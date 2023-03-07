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

