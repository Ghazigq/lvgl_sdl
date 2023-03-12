#include <stdio.h>
#include <unistd.h>
extern "C" {
  #include "lv_drivers.h"
};
#include "opencv2/opencv.hpp"


using namespace cv;

int main(int argc, char *args[])
{
  lv_main(argc, args);

  VideoCapture capture("C:/Users/Y/Desktop/picture/1.mp4");

  while (1)
  {
    sleep(100000);
  }

  return 0;
}