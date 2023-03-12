#include <stdio.h>
#include <unistd.h>
#include "lv_drivers.h"

int main(int argc, char *args[])
{
  lv_main(argc, args);

  while (1)
  {
    sleep(100000);
  }

  return 0;
}