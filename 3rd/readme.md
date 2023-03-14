## SDL2
依赖：libiconv

## zlib
https://github.com/madler/zlib.git
./configure --prefix=/home/ghazi/personal/lvgl_sdl/3rd/zlib-1.2.13/release
make
make install

## jpeg
http://www.ijg.org

## png
http://www.libpng.org/pub/png/libpng.html

## opencv
依赖：ffmpeg libpng

<!-- cmake -BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/homel \
-DOPENCV_EXTRA_MODULES_PATH=/home/wanggao/software/opencv/opencv-4.2.0/opencv_contrib-4.2.0/modules \
-DOPENCV_DNN_CUDA=True -DWITH_CUDA=True -DCUDA_ARCH_BIN="6.1 7.0 7.5" \
-DBUILD_EXAMPLES=OFF -DWITH_GSTREAMER=OFF -DBUILD_TESTS=OFF -DBUILD_PERF_TESTS=OFF \
../sources -->

## ffmpeg
依赖：x264 x265 fdk-aac
