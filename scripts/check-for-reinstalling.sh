#!/usr/bin/env bash

files=("yarn.lock")

for file in "${files[@]}"; do
  # The HEAD@{1} is a special notation for the commit that HEAD used to be
  # at prior to the original reset commit (1 change ago)
  # See more: https://git-scm.com/docs/git-reflog
  if [[ $(git diff HEAD@{1}..HEAD@{0} -- "${file}" | wc -l) -gt 0 ]]; then
    echo
    echo -e "======> \e[33;1m»${file}« has changed!\e[0m"
    echo -e "======> \e[33;1mreinstalling (dev-)dependencies by running »yarn install« might be a good idea\e[0m"
    break
  fi
done
