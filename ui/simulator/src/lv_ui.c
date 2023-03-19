#include "lv_ui.h"
#include "lv_ffmpeg2.h"
#include "lvgl.h"

// demo/examples
#include "lvgl/demos/lv_demos.h"
#include "lvgl/examples/lv_examples.h"

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

void lv_ui(void) {
  // lv_demo_widgets();
  // lv_demo_keypad_encoder();
  // lv_demo_benchmark();
  // lv_demo_stress();
  // lv_demo_music();

  lv_obj_t* player = NULL;
  for (int i = 0; i < 9; i++) {
    player = lv_ffmpeg2_player_create(lv_scr_act());
    lv_obj_set_content_width(player, lv_obj_get_width(lv_scr_act()) / 3);
    lv_obj_set_content_height(player, lv_obj_get_height(lv_scr_act()) / 3);
    lv_obj_align(player, LV_ALIGN_TOP_LEFT + i, 0, 0);
    lv_obj_add_event_cb(player, player_event_handler, LV_EVENT_ALL, NULL);
  }
}