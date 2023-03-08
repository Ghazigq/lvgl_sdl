## SDL2
./configure --prefix=/home/ghazi/personal/lvgl_sdl/3rd/SDL-release-2.26.4/release
make
make install

## libiconv
./configure --prefix=/home/ghazi/personal/lvgl_sdl/3rd/libiconv-1.17/release --enable-static --disable-shared
make
make install

## x265
cd ./source
mkdir build
cd build
cmake ..
make
make install DESTDIR=/home/ghazi/personal/lvgl_sdl/3rd/x265_3.5/source/build/release

## x264
./configure --enable-shared --enable-static --disable-asm --prefix=/home/ghazi/personal/lvgl_sdl/3rd/x264-master/release
make
make install

## fdk-aac
./configure --enable-shared --enable-static --prefix=/home/ghazi/personal/lvgl_sdl/3rd/fdk-aac-2.0.2/release
make
make install

## ffmpeg
<!-- 无作用
x264_pkg_path=/home/ghazi/personal/lvgl_sdl/3rd/x264/x86_64/pkgconfig
x265_pkg_path=/home/ghazi/personal/lvgl_sdl/3rd/x265/x86_64/pkgconfig
export PKG_CONFIG_PATH=$x264_pkg_path:$x265_pkg_path -->

./configure --enable-static --enable-libx264 --enable-gpl --enable-libx265 --extra-cflags=-I../x264/include --extra-ldflags=-L../x264/x86_64 --extra-cflags=-I../x265/include --extra-ldflags=-L../x265/x86_64 --prefix=/home/ghazi/personal/lvgl_sdl/3rd/FFmpeg-n5.0.2/release

make
make install
