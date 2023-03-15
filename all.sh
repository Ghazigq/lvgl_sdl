#!/bin/bash

clean_common()
{
    echo "clean all"
    make distclean
}

build_common()
{
if ! [ -x "$(command -v bear)" ]; then
    make
else
    bear make
fi
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
    echo "" >> .config
}

case $1 in
    c)      make clean; rm -rf .config;;
    *)      if [ ! -e ".config" ]; then choose; fi; build_common;;
esac
