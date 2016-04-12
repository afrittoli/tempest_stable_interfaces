#!/bin/bash

code_search="http://codesearch.openstack.org/api/v1/search"
all_repos='repos=*'
not_ignore_case='i=Nope'
python_files='files=.*\.py$'
both_query="^(import|from) tempest"
lib_query="^(import|from) tempest[\._]+lib"
tempest_query="^(import|from) tempest[\. ]+[^l]"

# Build the list of repos
curl -s --get $code_search --data-urlencode $all_repos --data-urlencode $not_ignore_case --data-urlencode $python_files --data-urlencode "q=$both_query" | jq -r '.Results | del(.["tempest-lib"]) | del(.tempest) | keys | join("\n")' | \
  sort | uniq > tempest_or_lib_repos

# Build the list of imports
curl -s --get $code_search --data-urlencode $all_repos --data-urlencode $not_ignore_case --data-urlencode $python_files --data-urlencode "q=$both_query" | | jq -r '.Results | .[].Matches | .[].Matches | .[].Line' | \
  sed -e 's,[ ]*as .*,,' -e 's,[ ]*# .*,,' -e 's,from ,,g' -e 's, import ,.,g' -e 's,^import ,,g' -e 's,tempest.lib,tempest#lib,g'| cut -d'.' -f1,2 | sed -e 's,tempest#lib,tempest.lib,g' | sort | uniq > tempest_or_lib_imports

# Build the list of occurrences of imports per repo
echo "repo;lib;tempest"
for repo in $(cat tempest_or_lib_repos); do
  printf "$repo"
  for query in "$lib_query" "$tempest_query"; do
    printf ";"
    printf "$(curl -s --get $code_search --data-urlencode repos=$repo --data-urlencode $not_ignore_case --data-urlencode $python_files --data-urlencode "q=$query" | jq -r '.Results | .[].Matches | .[].Matches | .[].Line' | \
	sed -e 's,[ ]*as .*,,' -e 's,[ ]*# .*,,' -e 's,from ,,g' -e 's, import ,.,g' -e 's,^import ,,g' -e 's,tempest.lib,tempest#lib,g'| cut -d'.' -f1,2 | sed -e 's,tempest#lib,tempest.lib,g' | sort | uniq | tr '\n' ',' | sed -e 's/,$//')"
  done
  printf "\n"
done > imports_per_repo

# Build the occurrency graph
