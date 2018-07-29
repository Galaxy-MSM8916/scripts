#!/bin/bash

script_dir=`realpath $(dirname $0)`

function update_repo() {
    echo "Finding git repo..."
    local git_dir=`find $script_dir -type d -name '.git'`
    [ -z $git_dir ] && local git_dir=".git"

    if [ -d "$git_dir" ]; then
        echo "Found git repo at $git_dir"
        local repo=`dirname $git_dir`
        echo "Updating ${git_dir}..."
        git -C $repo fetch && git -C $repo rebase -s "recursive" -X "theirs" FETCH_HEAD
        [ "$?" -eq 0 ] && echo -e "Scripts succesfully updated\n" || echo -e "Failed to update scripts repo\n"
    else
        echo -e "Failed to update scripts. No git repository found.\n"
    fi
}
