#include "lv_ui.h"
#include "lv_ffmpeg2.h"
#include "lvgl.h"

// demo/examples
#include "lvgl/demos/lv_demos.h"
#include "lvgl/examples/lv_examples.h"

#include "opencv2/imgproc/types_c.h"
#include "opencv2/opencv.hpp"

typedef struct {
  cv::VideoCapture* cap;
  uint8_t* img;
  lv_obj_t* obj;
  lv_timer_t* timer;
  lv_img_dsc_t imgdsc;
} lv_camera_t;

static int lv_camera_frame_update(lv_camera_t* lv_camera) {
  cv::Mat frame;
  if (!lv_camera->cap) return -1;

  *lv_camera->cap >> frame;  // 获取摄像头图像
  if (!frame.empty()) {
    cv::Mat lvgl_img;
    cv::cvtColor(frame, lvgl_img, CV_BGR2BGRA);
    // printf("frame width:%d height:%d channels:%d\n", lvgl_img.size().width,
    // lvgl_img.size().height, lvgl_img.channels());

    memcpy(lv_camera->img, lvgl_img.data,
           lvgl_img.size().width * lvgl_img.size().height * lvgl_img.channels());

    lv_img_cache_invalidate_src(lv_img_get_src(lv_camera->obj));
    lv_obj_invalidate(lv_camera->obj);
  }
  return 0;
}

static void lv_camera_cb(lv_timer_t* timer) {
  lv_camera_frame_update((lv_camera_t*)timer->user_data);
}

lv_camera_t* lv_camera_ui(void) {
  lv_camera_t* lv_camera = (lv_camera_t*)malloc(sizeof(lv_camera_t));
  if (NULL == lv_camera) return NULL;

  lv_camera->cap = new cv::VideoCapture(-1);
  // lv_camera->cap = new cv::VideoCapture("resource/test.mp4");
  if (!lv_camera->cap->isOpened()) {
    delete[] lv_camera->cap;
    free(lv_camera);
    return NULL;
  }

  int width = lv_camera->cap->get(cv::CAP_PROP_FRAME_WIDTH);
  int height = lv_camera->cap->get(cv::CAP_PROP_FRAME_HEIGHT);
  printf("width:%d height:%d\n", width, height);

  lv_camera->img = (uint8_t*)malloc(width * height * 4);
  if (NULL == lv_camera->img) {
    delete[] lv_camera->cap;
    free(lv_camera);
    return NULL;
  }

  lv_camera->obj = lv_img_create(lv_scr_act());
  if (NULL == lv_camera->obj) {
    delete[] lv_camera->cap;
    free(lv_camera->img);
    free(lv_camera);
    return NULL;
  }

  lv_camera->imgdsc.header.always_zero = 0;
  lv_camera->imgdsc.header.w           = width;
  lv_camera->imgdsc.header.h           = height;
  lv_camera->imgdsc.data_size          = lv_camera->imgdsc.header.w * lv_camera->imgdsc.header.h;
  lv_camera->imgdsc.data_size =
      (false) ? lv_camera->imgdsc.data_size * LV_IMG_PX_SIZE_ALPHA_BYTE : lv_camera->imgdsc.data_size * LV_COLOR_SIZE / 8;
  lv_camera->imgdsc.data      = (const uint8_t*)lv_camera->img;
  lv_camera->imgdsc.header.cf = LV_IMG_CF_TRUE_COLOR;
  lv_obj_set_width(lv_camera->obj, lv_camera->imgdsc.header.w);
  lv_obj_set_height(lv_camera->obj, lv_camera->imgdsc.header.h);
  lv_img_set_src(lv_camera->obj, &lv_camera->imgdsc);

  lv_camera->timer = lv_timer_create(lv_camera_cb, 100, lv_camera);
  return lv_camera;
}

void player_event_handler(lv_event_t* e) {
  lv_event_code_t code = lv_event_get_code(e);

  if (code == LV_EVENT_SIZE_CHANGED) {
    if (!(intptr_t)(e->user_data)) {
      e->user_data = (void*)1;
      lv_ffmpeg2_player_set_cmd(e->current_target, LV_FFMPEG_PLAYER_CMD_STOP);
      lv_ffmpeg2_player_set_src(e->current_target, "resource/test.mp4");
      lv_ffmpeg2_player_set_auto_restart(e->current_target, true);
      lv_ffmpeg2_player_set_cmd(e->current_target, LV_FFMPEG_PLAYER_CMD_START);
    }
  }
}

void lv_player(void) {
  lv_obj_t* player = NULL;
  for (int i = 0; i < 9; i++) {
    player = lv_ffmpeg2_player_create(lv_scr_act());
    lv_obj_set_content_width(player, lv_obj_get_width(lv_scr_act()) / 3);
    lv_obj_set_content_height(player, lv_obj_get_height(lv_scr_act()) / 3);
    lv_obj_align(player, LV_ALIGN_TOP_LEFT + i, 0, 0);
    lv_obj_add_event_cb(player, player_event_handler, LV_EVENT_ALL, NULL);
  }
}

void lv_ui(void) {
  // lv_demo_widgets();
  // lv_demo_keypad_encoder();
  // lv_demo_benchmark();
  // lv_demo_stress();
  // lv_demo_music();

  // lv_player();
  lv_camera_ui();
}