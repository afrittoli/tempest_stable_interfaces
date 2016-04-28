#!/bin/bash
#
# Uses codesearch to get tempest imports across openstack
# Post-processes the result into a few data files
#
# Setting IMPORT_LEVELS=3 increases the results granularity
# If ./raw/data.json is found search is not done. Delete it to force a fresh
# search on codesearch.

script_folder=$(cd $(dirname $0); pwd)
code_search="http://codesearch.openstack.org/api/v1/search"
all_repos='repos=*'
not_ignore_case='i=Nope'
python_files='files=.*\.py$'
query="^(import|from) tempest"
levels=${IMPORT_LEVELS:-2}

if [[ $levels -eq 2 ]]; then
    cut_levels="1,2"
    filename_postfix=""
elif [[ $levels -eq 3 ]]; then
    cut_levels="1,2,3"
    filename_postifx="_detailed"
else
    echo "IMPORT_LEVELS must be 2 or 3" >2
    exit 1
fi

# Get the ~raw data. Delete the cache to fetch a new version
if [ ! -f ${script_folder}/raw/data.json ]; then
    curl -s --get ${code_search} \
            --data-urlencode ${all_repos} \
            --data-urlencode ${not_ignore_case} \
            --data-urlencode ${python_files} \
            --data-urlencode "q=$query" |
        jq '.Results | del(.["tempest-lib"]) | del(.tempest) ' > ${script_folder}/raw/data.json
fi

# Build the list of repos
echo "Building the list of repos in ${script_folder}/repos"
cat ${script_folder}/raw/data.json | \
    jq -r 'keys | join("\n")' | \
    sort | uniq > ${script_folder}/repos

# Build the list of imports
echo "Building the list of imports in ${script_folder}/imports${filename_postifx}"
cat ${script_folder}/raw/data.json | \
    jq -r '.[].Matches | .[].Matches | .[].Line' | \
    sed -e 's,[ ]*as .*,,' -e 's,[ ]*# .*,,' -e 's,from ,,g' -e 's, import ,.,g' -e 's,^import ,,g' -e 's,tempest.lib,tempest#lib,g'| \
    cut -d'.' -f${cut_levels} | sed -e 's,tempest#lib,tempest.lib,g' | sort | uniq > ${script_folder}/imports${filename_postifx}

# Build the list of occurrences of imports per repo
echo "Building the table of imports per repo in ${script_folder}/imports_per_repo${filename_postifx}"
echo "repo;imports" > ${script_folder}/imports_per_repo${filename_postifx}
for repo in $(cat ${script_folder}/repos); do
    printf "$repo;"
    printf "$(cat ${script_folder}/raw/data.json | \
                jq -r '.["'${repo}'"].Matches | .[].Matches | .[].Line' | \
                sed -e 's,[ ]*as .*,,' -e 's,[ ]*# .*,,' -e 's,from ,,g' -e 's, import ,.,g' -e 's,^import ,,g' -e 's,tempest.lib,tempest#lib,g'| \
                cut -d'.' -f"${cut_levels}" | sed -e 's,tempest#lib,tempest.lib,g' | sort | uniq | tr '\n' ',' | sed -e 's/,$//')"
    printf "\n"
done >> ${script_folder}/imports_per_repo${filename_postifx}

# Build list of all lines for full count
cat ${script_folder}/raw/data.json | \
    jq -r '.[].Matches | .[].Matches | .[].Line' | \
    sed -e 's,[ ]*as .*,,' -e 's,[ ]*# .*,,' -e 's,from ,,g' -e 's, import ,.,g' -e 's,^import ,,g' -e 's,tempest.lib,tempest#lib,g'| \
    cut -d'.' -f${cut_levels} | sed -e 's,tempest#lib,tempest.lib,g' > ${script_folder}/raw/all_lines${filename_postifx}

# Build the repo per imports tables for tempest and tempest.lib
for filter in 'tempest' 'lib'; do
    [[ "${filter}" == "tempest" ]] && grep_opt='-v' || grep_opt=' '
    echo "Building the table of repos per import in ${script_folder}/repo_per_${filter}_imports${filename_postifx}"
    echo "import;namespace;count;total_count;repos" > ${script_folder}/repo_per_${filter}_imports${filename_postifx}
    for import in $(cat ${script_folder}/imports${filename_postifx} | egrep ${grep_opt} '^(tempest.lib|tempest.config$|tempest.test_discover.plugins)'); do
        printf "${import};${import#tempest.*};"
        printf "$(egrep -c ${import}'(,|$)' ${script_folder}/imports_per_repo${filename_postifx});"
        printf "$(egrep -c ${import} ${script_folder}/raw/all_lines${filename_postifx});"
        printf "$(egrep ${import}'(,|$)' ${script_folder}/imports_per_repo${filename_postifx} | cut -d';' -f1 | tr '\n' ',' | sed -e 's/,$//')"
        printf "\n"
    done >> ${script_folder}/repo_per_${filter}_imports${filename_postifx}
done