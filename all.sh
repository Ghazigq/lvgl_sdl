#!/bin/bash

clean_common()
{
    echo "clean all"
    make distclean
}

build_common()
{
    make test
    make install
}

choose()
{
    select app_type in `ls configs/*_config`;
    do
        break
    done

    cp $app_type .config
    arch_path=`echo $app_type | cut -d "/" -f 2 | cut -d "_" -f 1`
    echo -e "\nCONFIG_ARCH_PATH=$arch_path" >> .config
}

case $1 in
    c)      make clean; rm -rf .config;;
    *)      if [ ! -e ".config" ]; then choose; fi; build_common;;
esac
