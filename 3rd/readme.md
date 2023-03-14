## SDL2
依赖：libiconv

## zlib
https://github.com/madler/zlib.git
./configure --prefix=/home/ghazi/personal/lvgl_sdl/3rd/zlib-1.2.13/release
make
make install

## jpeg
http://www.ijg.org/
./configure --enable-shared --enable-static --prefix=/home/ghazi/personal/lvgl_sdl/3rd/jpeg-9e/release
make
make install

## png
http://www.libpng.org/pub/png/libpng.html
./configure --enable-shared --enable-static --prefix=/home/ghazi/personal/lvgl_sdl/3rd/libpng-1.6.39/release
make
make install

## opencv
依赖：ffmpeg libpng
mkdir build
cd build

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/ghazi/personal/lvgl_sdl/3rd/ffmpeg/x86_64:/home/ghazi/personal/lvgl_sdl/3rd/libpng/x86_64
export PKG_CONFIG_PATH=/home/ghazi/personal/lvgl_sdl/3rd/ffmpeg/x86_64/pkgconfig:/home/ghazi/personal/lvgl_sdl/3rd/libpng/x86_64/pkgconfig
export PKG_CONFIG_LIBDIR=/home/ghazi/personal/lvgl_sdl/3rd/ffmpeg/x86_64:/home/ghazi/personal/lvgl_sdl/3rd/libpng/x86_64

<!-- export FFMPEG_INCLUDE_DIRS=/home/ghazi/personal/lvgl_sdl/3rd/ffmpeg/include
export FFMPEG_LIBRARIES=/home/ghazi/personal/lvgl_sdl/3rd/ffmpeg/x86_64 -->

<!-- cmake -DBUILD_SHARED_LIBS=OFF -DWITH_FFMPEG=ON -DOPENCV_FFMPEG_ENABLE_LIBAVDEVICE=ON .. -->

cmake -DBUILD_SHARED_LIBS=OFF -DWITH_FFMPEG=ON -DOPENCV_FFMPEG_ENABLE_LIBAVDEVICE=ON -DFFMPEG_INCLUDE_DIRS=/home/ghazi/personal/lvgl_sdl/3rd/ffmpeg/include ..
<!-- cmake -BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/homel \
-DOPENCV_EXTRA_MODULES_PATH=/home/wanggao/software/opencv/opencv-4.2.0/opencv_contrib-4.2.0/modules \
-DOPENCV_DNN_CUDA=True -DWITH_CUDA=True -DCUDA_ARCH_BIN="6.1 7.0 7.5" \
-DBUILD_EXAMPLES=OFF -DWITH_GSTREAMER=OFF -DBUILD_TESTS=OFF -DBUILD_PERF_TESTS=OFF \
../sources -->
make
make install DESTDIR=/home/ghazi/personal/lvgl_sdl/3rd/opencv-4.7.0/build/release

## ffmpeg
依赖：x264 x265 fdk-aac
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
