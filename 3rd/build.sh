#!/bin/bash
root_path=$PWD
install_path=$root_path/$1
lib_path=$install_path/lib
include_path=$install_path/include
pkg_path=$lib_path/pkgconfig

build()
{
    # [ -e build ] && rm -rf build
    mkdir -p build
    mkdir -p $install_path
    tar -zxvf tar/$src_tar -C build
    cd build/${src_tar:0:4}* #jpeg只能4位
    if [[ "$src_tar" =~ "x264" ]]; then
        ./configure --enable-shared --enable-static --disable-asm --prefix=$install_path
        make
        make install
    elif [[ "$src_tar" =~ "x265" ]]; then
        cd ./source
        mkdir -p build
        cd build
        cmake -DCMAKE_INSTALL_PREFIX=$install_path ..
        make
        make install
        cd -
    elif [[ "$src_tar" =~ "FFmpeg" ]]; then
        ./configure --enable-static --enable-libx264 --enable-gpl --enable-libx265 --enable-libfdk-aac --enable-nonfree \
        --extra-cflags="-I$include_path" --extra-ldflags="-L$install_path" --prefix=$install_path
        make
        make install
    elif [[ "$src_tar" =~ "opencv" ]]; then
        export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$lib_path
        mkdir -p build
        cd build
        cmake -DBUILD_SHARED_LIBS=OFF -DWITH_FFMPEG=ON -DOPENCV_FFMPEG_ENABLE_LIBAVDEVICE=ON -DFFMPEG_INCLUDE_DIRS=$include_path -DCMAKE_INSTALL_PREFIX=$install_path ..
        make
        make install
        cd -
    else
        ./configure --enable-shared --enable-static --prefix=$install_path
        make
        make install
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

100M_tar()
{
    for tar_file in `find . -type f -size +100000k`;
    do
        tar -zcvf ${tar_file}_100M.tar.gz $tar_file
    done
}

100M_untar()
{
    for untar_file in `find . -name "*_100M.tar.gz"`;
    do
        tar -zxvf ${untar_file}
    done
}

export PKG_CONFIG_PATH=$pkg_path
export PKG_CONFIG_LIBDIR=$lib_path
echo "PKG_CONFIG_PATH: ${PKG_CONFIG_PATH}"
echo "PKG_CONFIG_LIBDIR: ${PKG_CONFIG_LIBDIR}"

case $1 in
    untar)  100M_untar;;
    *)      choose && build && 100M_tar;;
esac