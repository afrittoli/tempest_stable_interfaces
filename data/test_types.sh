#!/usr/bin/env bash
#
# Discovers type of tests for a list of repositories
# Only plugin and CLI can be discovered auto-magically

script_folder=$(cd $(dirname $0); pwd)

REPOS=${REPOS:-${script_folder}/repos}
IMPORTS=${IMPORTS:-${script_folder}/imports_per_repo_detailed}

TEMPEST_NAMESPACE="(test_discover.plugins|scenario.manager)"
CLI_NAMESPACE="(lib.cli|tempest.cli)(,|\.|$)"
UTILS_NAMESPACE="(lib.common.utils)"

echo "repo;tempest;cli;utils" > ${script_folder}/test_types_per_repo
for repo in $(cat ${REPOS}); do
    printf "${repo};"
    printf "$(egrep ^${repo} ${IMPORTS} | egrep ${TEMPEST_NAMESPACE} &> /dev/null && echo 1 || echo 0);"
    printf "$(egrep ^${repo} ${IMPORTS} | egrep ${CLI_NAMESPACE} &> /dev/null && echo 1 || echo 0);"
    printf "$(egrep ^${repo} ${IMPORTS} | egrep ${UTILS_NAMESPACE} &> /dev/null && echo 1 || echo 0)\n"
done >> ${script_folder}/test_types_per_repo