#!/bin/bash
root_path=$PWD

build()
{
    # [ -e build ] && rm -rf build
    mkdir -p build
    tar -zxvf tar/$src_tar -C build
    cd build/${src_tar:0:4}* #jpeg只能4位
    if [[ "$src_tar" =~ "x264" ]]; then
        ./configure --enable-shared --enable-static --disable-asm --includedir=$root_path/include --prefix=$root_path/x86_64
    elif [[ "$src_tar" =~ "x265" ]]; then
        cd ./source
        mkdir build
        cd build
        cmake -DCMAKE_INSTALL_PREFIX=$root_path/x86_64 ..
    elif [[ "$src_tar" =~ "FFmpeg" ]]; then
        ./configure --enable-static --enable-libx264 --enable-gpl --enable-libx265 \
        --extra-cflags="-I../../include" --extra-ldflags="-L../../x86_64" \
        --includedir=$root_path/include --prefix=$root_path/x86_64
    else
        ./configure --enable-shared --enable-static --includedir=$root_path/include --prefix=$root_path/x86_64
    fi
    make
    make install
    if [[ "$src_tar" =~ "x265" ]]; then
        sed -i 's/includedir=${prefix}\/include/includedir=${prefix}\/..\/include/' $root_path/x86_64/lib/pkgconfig/x265.pc
        cd -
        cp -d -r $root_path/x86_64/include/* $root_path/include/
        rm -rf $root_path/x86_64/include
    fi
    cd $root_path
}

choose()
{
    select src_tar in `ls tar`;
    do
        break
    done
}

choose
build