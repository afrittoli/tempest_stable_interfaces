#!/bin/bash

script_folder=$(cd $(dirname $0); pwd)
code_search="http://codesearch.openstack.org/api/v1/search"
all_repos='repos=*'
not_ignore_case='i=Nope'
python_files='files=.*\.py$'
query="^(import|from) tempest"

# Get the ~raw data
curl -s --get ${code_search} \
        --data-urlencode ${all_repos} \
        --data-urlencode ${not_ignore_case} \
        --data-urlencode ${python_files} \
        --data-urlencode "q=$query" |
    jq '.Results | del(.["tempest-lib"]) | del(.tempest) ' > ${script_folder}/raw/data.json

# Build the list of repos
echo "Building the list of repos in ${script_folder}/repos"
cat ${script_folder}/raw/data.json | \
    jq -r 'keys | join("\n")' | \
    sort | uniq > ${script_folder}/repos

# Build the list of imports
echo "Building the list of imports in ${script_folder}/imports"
cat ${script_folder}/raw/data.json | \
    jq -r '.[].Matches | .[].Matches | .[].Line' | \
    sed -e 's,[ ]*as .*,,' -e 's,[ ]*# .*,,' -e 's,from ,,g' -e 's, import ,.,g' -e 's,^import ,,g' -e 's,tempest.lib,tempest#lib,g'| \
    cut -d'.' -f1,2 | sed -e 's,tempest#lib,tempest.lib,g' | sort | uniq > ${script_folder}/imports

# Build the list of occurrences of imports per repo
echo "Building the table of imports per repo in ${script_folder}/imports_per_repo"
echo "repo;imports" > ${script_folder}/imports_per_repo
for repo in $(cat ${script_folder}/repos); do
    printf "$repo;"
    printf "$(cat ${script_folder}/raw/data.json | \
                jq -r '.["'${repo}'"].Matches | .[].Matches | .[].Line' | \
                sed -e 's,[ ]*as .*,,' -e 's,[ ]*# .*,,' -e 's,from ,,g' -e 's, import ,.,g' -e 's,^import ,,g' -e 's,tempest.lib,tempest#lib,g'| \
                cut -d'.' -f1,2 | sed -e 's,tempest#lib,tempest.lib,g' | sort | uniq | tr '\n' ',' | sed -e 's/,$//')"
    printf "\n"
done >> ${script_folder}/imports_per_repo

# Build the repo per imports tables
# Tempest first and tempest.lib then
for filter in 'tempest' 'lib'; do
    [[ "${filter}" == "tempest" ]] && grep_opt='-v' || grep_opt=' '
    echo "Building the table of repos per import in ${script_folder}/repo_per_${filter}_imports"
    echo "import;namespace;count;repos" > ${script_folder}/repo_per_${filter}_imports
    for import in $(cat ${script_folder}/imports | egrep ${grep_opt} '^tempest.lib'); do
        printf "${import};${import#tempest.*};"
        printf "$(grep -c ${import} ${script_folder}/imports_per_repo);"
        printf "$(grep ${import} ${script_folder}/imports_per_repo | cut -d';' -f1 | tr '\n' ',' | sed -e 's/,$//')"
        printf "\n"
    done >> ${script_folder}/repo_per_${filter}_imports
done