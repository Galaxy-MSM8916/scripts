#!/bin/bash

VERBOSE=0

function print_help() {
    echo "Usage: `basename $0` [OPTIONS] "
    echo "  -d | --path       Path to git repo directory"
    echo "  -o | --out        Path to output file (for report)"
    echo "                    if none is specified, print to stdout"
    echo "  -r | --remote     Remote to use for fetching tags/branches"
    echo "  -t | --tag-regexp regexp to use for searching tags. Default is '*LA\.BR\.*8x16*[0-9]'"
    echo "  -h | --help       Print this message"
    echo "  -v | --verbose    Print git output as well"
    exit 0
}

if [ "x$1" == "x" ]; then
    print_help
fi

while [ "$1" != "" ]; do
    case $1 in
        -d | --path)            shift
                                REPO_DIR=$1
                                ;;
        -o | --out)             shift
                                REPORT_OUT_FILE=$1
                                ;;
        -r | --remote)          shift
                                REMOTE=$1
                                ;;
       -t | --tag-regexp)       shift
                                TAG_REGEXP=$1
                                ;;
        -v | --verbose)         shift
                                VERBOSE=1
                                ;;
        *)                      print_help
                                ;;
    esac
    shift
done

BEST_TAG=
BEST_COUNT=246913578246644640

if [ "x${REPO_DIR}" == "x" ]; then
    REPO_DIR=$PWD
fi

if [ "x${REPORT_OUT_FILE}" == "x" ]; then
    REPORT_OUT_FILE=/dev/stdout
fi

if [ "x${TAG_REGEXP}" == "x" ]; then
    TAG_REGEXP='*LA\.BR\.*8x16*[0-9]'
fi

echo "Merge report" >> ${REPORT_OUT_FILE}
echo -e "============\n" >> ${REPORT_OUT_FILE}

if [ "$VERBOSE" -ne 1 ]; then
    git -C ${REPO_DIR} fetch -t ${REMOTE} 2>/dev/null 1>&2
else
    git -C ${REPO_DIR} fetch -t ${REMOTE}
fi

TAGS=`git -C ${REPO_DIR} ls-remote --tags ${REMOTE} ${TAG_REGEXP} | sed s'/[ \t]\+/ /'g | cut -d' ' -f2`

for tag in ${TAGS}; do
	if [ "$VERBOSE" -ne 1 ]; then
		git -C ${REPO_DIR} fetch ${REMOTE} ${tag} 2>/dev/null 1>&2
		git -C ${REPO_DIR} clean -df 2>/dev/null 1>&2
		git -C ${REPO_DIR} pull  --no-commit ${REMOTE} ${tag} --allow-unrelated-histories 2>/dev/null 1>&2
		conflict_count=`git -C ${REPO_DIR} status | egrep "both modified|both added" | wc -l`
		git -C ${REPO_DIR} merge --abort 2>/dev/null 1>&2
	else
		git -C ${REPO_DIR} fetch ${REMOTE} ${tag}
		git -C ${REPO_DIR} clean -df
		git -C ${REPO_DIR} pull  --no-commit ${REMOTE} ${tag} --allow-unrelated-histories
		conflict_count=`git -C ${REPO_DIR} status | egrep "both modified|both added" | wc -l`
		git -C ${REPO_DIR} merge --abort
	fi

	echo -e "\tTag ${tag} has ${conflict_count} conflicts." >> ${REPORT_OUT_FILE}

	if [ ${conflict_count} -le ${BEST_COUNT} ]; then
		BEST_TAG=${tag}
		BEST_COUNT=${conflict_count}
	fi
done

echo -e "\n==================\n" >> ${REPORT_OUT_FILE}

echo -e "\nBest tag is ${BEST_TAG} with ${BEST_COUNT} merge conflicts\n" >> ${REPORT_OUT_FILE}

