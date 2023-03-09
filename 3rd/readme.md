# 注意事项
x264 x265 fdk-aac生成的pkgconfig下文件必须手动更改路径，否则ffmpeg编译时找不到库

## SDL2
./configure --enable-shared --enable-static --prefix=/home/ghazi/personal/lvgl_sdl/3rd/SDL-release-2.26.4/release
make
make install

## libiconv
./configure --enable-shared --enable-static --prefix=/home/ghazi/personal/lvgl_sdl/3rd/libiconv-1.17/release
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
x264_pkg_path=/home/ghazi/personal/lvgl_sdl/3rd/x264/x86_64/pkgconfig
x265_pkg_path=/home/ghazi/personal/lvgl_sdl/3rd/x265/x86_64/pkgconfig
fdk_aac_pkg_path=/home/ghazi/personal/lvgl_sdl/3rd/fdk-aac/x86_64/pkgconfig
export PKG_CONFIG_PATH=$x264_pkg_path:$x265_pkg_path:$fdk_aac_pkg_path

./configure --enable-static --enable-libx264 --enable-gpl --enable-libx265 --extra-cflags="-I../x264/include -I../x265/include -I../fdk-aac/include" --extra-ldflags="-L../x264/x86_64 -L../x265/x86_64" --prefix=/home/ghazi/personal/lvgl_sdl/3rd/FFmpeg-n5.0.2/release

<!-- ./configure --enable-static --enable-libx264 --enable-gpl --enable-libx265 --enable-libfdk-aac --enable-nonfree --extra-cflags="-I../x264/include -I../x265/include -I../fdk-aac/include" --extra-ldflags="-L../x264/x86_64 -L../x265/x86_64 -L../fdk-aac/x86_64" --prefix=/home/ghazi/personal/lvgl_sdl/3rd/FFmpeg-n5.0.2/release -->

<!-- export PKG_CONFIG_PATH=/home/ghazi/personal/lvgl_sdl/3rd/fdk_aac/x86_64/pkgconfig
./configure --enable-static --enable-gpl --enable-libfdk-aac --enable-nonfree --extra-cflags=-I../fdk_aac/include --extra-ldflags=-L../fdk_aac/x86_64 --prefix=/home/ghazi/personal/lvgl_sdl/3rd/FFmpeg-n5.0.2/release -->

make
make install
