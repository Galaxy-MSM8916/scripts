#!/bin/bash

function update_repo() {
    echo "Finding git repo..."
    local git_dir=`find -type d -name '.git'`
    [ -z $git_dir ] && local git_dir=".git"

    if [ -d "$git_dir" ]; then
        echo "Found git repo at $git_dir"
        local repo=`dirname $git_dir`
        echo "Updating ${git_dir}..."
        git -C $repo fetch && git -C $repo rebase FETCH_HEAD
        [ "$?" -eq 0 ] && echo "Scripts succesfully updated" || echo "Failed to update scripts repo"
    fi
}
