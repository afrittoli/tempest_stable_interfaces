#!/bin/bash

# Get the list of projects
# ssh -p 29418 andrea-frittoli@review.openstack.org gerrit ls-projects > projects

# Clone them
# for ss in $(cat projects | grep openstack); do if [ ! -d $ss ]; then mkdir -p $ss; git clone https://git.openstack.org/$ss $ss; fi; done

script_folder=$(cd $(dirname $0); pwd)
git_folder=${GIT_FOLDER:-${script_folder}/../git}

# Find the date on which tempest plugin entry point was added
find ${git_folder} -name 'setup.cfg' -exec egrep -l '^tempest' '{}' \; | while read aa; do
    cd $(dirname $aa);
    echo "$(git blame -L '/^tempest/,+1' $(basename $aa) | awk '{print $1}' |xargs git log -1 --format=%cd --date=short) $(basename $(dirname $aa))";
    cd - &> /dev/null;
done | sort | awk '{ print $1" "NR" "$2 }' > ${script_folder}/tempest_plugins.dat

jj=1
for client_repo in $(ls ${git_folder} | grep python-); do
    egrep '^(import|from) tempest[_\.]+lib\.cli(\.| import )base' -l -r ${git_folder}/${client_repo} | while read aa; do
        pushd $(dirname $aa) &> /dev/null;
        echo "$(git blame -L '/^\(from\|import\) tempest[_\.]\+lib\.cli\(\.\| import \)/,+1' $(basename $aa) | awk '{print $1}' |xargs git log -1 --format=%cd --date=short) ${client_repo}";
        popd &> /dev/null;
    done | sort | awk '{ print $1" "'${jj}'" "$2 }' | head -1
    jj=$(( jj + 1 ))
done > ${script_folder}/cli_tests.dat

awk '{ print $3 }' ${scipt_folder}/tempest_plugins.dat ${script_folder}/cli_tests.dat | sort | comm -23 ${script_folder}/../repos - > ${script_folder}/other.datr