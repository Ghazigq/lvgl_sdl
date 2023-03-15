#!/bin/bash
#----------------------------------------------------------------------------------------------------------
# @file    gen_version.sh
# @brief
# @ note :
# @param	--file= gen_version.h
#
#----------------------------------------------------------------------------------------------------------

# version_file=`echo $0 | sed 's/\(.*\)gen_version.sh/\1version/'`
# source $version_file

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

	export VERSION_MAJOR=$(($(git log --oneline | wc -l) / 65535 + 1))
	export VERSION_MINOR=$(($(git log  --oneline | wc -l) / 255))
	export VERSION_REVISION=$(($(git log --oneline | wc -l) % 255))
	export VERSION_EXTRA=0

	mkdir -p ${ARG_FILE%/*}
	echo "#ifndef _PPS_VERSION_H" >  ${ARG_FILE}
	echo "#define _PPS_VERSION_H" >> ${ARG_FILE}

	echo "#define VERSION_MAJOR \"$VERSION_MAJOR\"" >> ${ARG_FILE}
	echo "#define VERSION_MINOR \"$VERSION_MINOR\"" >> ${ARG_FILE}
	echo "#define VERSION_REVISION \"$VERSION_REVISION\"" >> ${ARG_FILE}
	echo "#define VERSION_EXTRA \"$VERSION_EXTRA\"" >> ${ARG_FILE}

	echo "#endif /* _PPS_VERSION_H */" >> ${ARG_FILE}

	echo Version:${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_REVISION}.${VERSION_EXTRA}
}

main $@

