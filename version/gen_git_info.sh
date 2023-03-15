#!/bin/bash
#----------------------------------------------------------------------------------------------------------
# @file    gen_git_info.sh
# @brief
# @ note :
# @param	--file= git_info.h
#
#----------------------------------------------------------------------------------------------------------

usage()
{
	echo "Usage: $@ fail to exit"
	exit 1
}

main()
{
    # strip info
	for i in $*
	do
		case $i in
		--file=*)
			if [ -z "$ARG_FILE" ]
			then
				ARG_FILE=${i##*--file=}
			else
				usage $@
			fi
			;;
		*)
			;;
		esac
	done

	if [ -z "$ARG_FILE" ]
	then
		usage $@
	fi

	# write to file
	GIT_BUILD_BRANCH=$(git rev-parse --abbrev-ref HEAD)
	GIT_BUILD_COMMIT=$(git rev-parse --short HEAD)
	GIT_BUILD_AUTHOR=$(git config user.name)
	GIT_COMMIT_TIME=$(git log -1 --format="%ad" --date=short)
	GIT_CLEAN=$(git status | grep "无文件要提交，干净的工作区" | xargs)

	if [ "$GIT_CLEAN" == "无文件要提交，干净的工作区" ];	then
	  GIT_COMMIT_DIRTY=;
	else
	  GIT_COMMIT_DIRTY=P;
	fi

	mkdir -p ${ARG_FILE%/*}
	echo "#ifndef _PPS_GIT_INFO_H" >  ${ARG_FILE}
	echo "#define _PPS_GIT_INFO_H" >> ${ARG_FILE}
	echo "#define GIT_BUILD_BRANCH \"$GIT_BUILD_BRANCH\"" >> ${ARG_FILE}
	echo "#define GIT_BUILD_COMMIT \"$GIT_BUILD_COMMIT\"" >> ${ARG_FILE}
	echo "#define GIT_BUILD_AUTHOR \"$GIT_BUILD_AUTHOR\"" >> ${ARG_FILE}
	echo "#define GIT_COMMIT_TIME \"$GIT_COMMIT_TIME\"" >> ${ARG_FILE}
	echo "#define GIT_COMMIT_DIRTY \"$GIT_COMMIT_DIRTY\"" >> ${ARG_FILE}

    echo "#endif /* _PPS_GIT_INFO_H */" >> ${ARG_FILE}

	echo Build:${GIT_COMMIT_TIME}_${GIT_BUILD_BRANCH}_${GIT_BUILD_COMMIT} $GIT_COMMIT_DIRTY by $GIT_BUILD_AUTHOR
}

main $@
