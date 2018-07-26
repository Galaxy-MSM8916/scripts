#!/bin/bash

tags_file="tags.txt"
remotes_file="remotes.txt"
out_file="report.txt"

echo "Merge report" >> ${out_file}
echo -e "============\n" >> ${out_file}


for tag in `cat ${tags_file}`; do
	git fetch caf ${tag}
	git pull --no-commit caf ${tag}
	conflict_count=`git status | grep 'both modified' | wc -l`
	git merge --abort
	echo -e "\tTag ${tag} has ${conflict_count} conflicts." >> ${out_file}
done

echo -e "\n==================\n" >> ${out_file}

for remote in `cat ${remotes_file}`; do
	git fetch caf ${remote}
	git pull --no-commit caf ${remote}
	conflict_count=`git status | grep 'both modified' | wc -l`
	git merge --abort
	echo -e "\tBranch ${remote} has ${conflict_count} conflicts." >> ${out_file}
done
