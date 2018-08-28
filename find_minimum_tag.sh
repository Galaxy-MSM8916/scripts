#!/bin/bash

function print_help() {
    echo "Usage: `basename $0` [OPTIONS] "
    echo "  -b | --branches   Path to file with list of branches"
    echo "  -d | --path       Path to git repo directory"
    echo "  -o | --out        Path to output file (for report)"
    echo "                    if none is specified, print to stdout"
    echo "  -r | --remote     Remote to use for fetching tags/branches"
    echo "  -t | --tags       Path to file with list of tags"
    echo "  -h | --help       Print this message"
    exit 0
}

if [ "x$1" == "x" ]; then
    print_help
fi

while [ "$1" != "" ]; do
    case $1 in
        -b | --branches)        shift
                                BRANCH_FILE=$1
                                ;;
        -d | --path )           shift
                                REPO_DIR=$1
                                ;;
        -o | --out)             shift
                                REPORT_OUT_FILE=$1
                                ;;
        -r | --remote)          shift
                                REMOTE=$1
                                ;;
        -t | --tags)            shift
                                TAGS_FILE=$1
                                ;;
        *)                      print_help
                                ;;
    esac
    shift
done

if [ "x${BRANCH_FILE}" == "x" ] && [ "x${TAGS_FILE}" == "x" ]; then
    echo "Error: No branch or tag file specified!" >> /dev/stderr
fi

if [ "x${REPO_DIR}" == "x" ]; then
    REPO_DIR=$PWD
fi

if [ "x${REPORT_OUT_FILE}" == "x" ]; then
    REPORT_OUT_FILE=/dev/stdout
fi

echo "Merge report" >> ${REPORT_OUT_FILE}
echo -e "============\n" >> ${REPORT_OUT_FILE}

for tag in `cat ${TAGS_FILE}`; do
	git -C ${REPO_DIR} fetch ${REMOTE} ${tag}
	git -C ${REPO_DIR} clean -df
	git -C ${REPO_DIR} pull  --no-commit ${REMOTE} ${tag} --allow-unrelated-histories
	conflict_count=`git -C ${REPO_DIR} status | grep 'both modified' | wc -l`
	git -C ${REPO_DIR} merge --abort
	echo -e "\tTag ${tag} has ${conflict_count} conflicts." >> ${REPORT_OUT_FILE}
done

echo -e "\n==================\n" >> ${REPORT_OUT_FILE}

for branch in `cat ${BRANCH_FILE}`; do
	git -C ${REPO_DIR} fetch ${REMOTE} ${branch}
	git -C ${REPO_DIR} clean -df
	git -C ${REPO_DIR} pull  --no-commit ${REMOTE} ${tag} --allow-unrelated-histories
	conflict_count=`git -C ${REPO_DIR} status | grep 'both modified' | wc -l`
	git -C ${REPO_DIR} merge --abort
	echo -e "\tBranch ${branch} has ${conflict_count} conflicts." >> ${REPORT_OUT_FILE}
done
