#!/usr/bin/env bash
pip install zenroom
zenroom_pip_version=`pip show zenroom | grep "Version:" | cut -d " " -f 2`
repo_version=`cat VERSION`
latest_version=`echo "${latest_version}\n${repo_version}" | sort -V | tail -1 | cut -c3-`
echo $latest_version
echo $repo_version
if [[ ${repo_version} == ${latest_version} ]]; then
    next_version=${repo_version}
else
    next_version=`echo ${zenroom_pip_version} | awk -F. -v OFS=. '{$NF=$NF+1; print}'`
fi
echo $next_version
#sed -ie 's/version=get_python_version()/version=${ next_version }/' bindings/python3/setup.py
