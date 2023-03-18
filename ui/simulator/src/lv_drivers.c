#include "lvgl/lvgl.h"

// SDL
// #include "lv_drivers/sdl/sdl_gpu.h"
#include "SDL2/SDL.h"
#include "lv_drivers/indev/keyboard.h"
#include "lv_drivers/indev/mouse.h"
#include "lv_drivers/indev/mousewheel.h"
#include "lv_drivers/sdl/sdl.h"

// demo/examples
#include "lvgl/demos/lv_demos.h"
#include "lvgl/examples/libs/ffmpeg/lv_example_ffmpeg.h"
#include "lvgl/examples/lv_examples.h"

// user
#include "lv_btn.h"

static int tick_thread(void* data) {
  while (1) {
    lv_tick_inc(5);
    SDL_Delay(5);
  }
  return 0;
}

/**
 * Initialize the Hardware Abstraction Layer (HAL) for the LVGL graphics
 * library
 */
static void hal_init(void) {
  /* SDL Driver*/
  sdl_init();

  /*Create a display buffer*/
  static lv_disp_draw_buf_t disp_buf1;
  static lv_color_t buf1_1[LV_HOR_RES_MAX * 100];
  static lv_color_t buf1_2[LV_HOR_RES_MAX * 100];
  lv_disp_draw_buf_init(&disp_buf1, buf1_1, buf1_2, LV_HOR_RES_MAX * 100);
  // sdl_gpu_disp_draw_buf_init(&disp_buf1);

  /*Create a display*/
  static lv_disp_drv_t disp_drv;
  lv_disp_drv_init(&disp_drv); /*Basic initialization*/
  // sdl_gpu_disp_drv_init(&disp_drv);
  disp_drv.draw_buf     = &disp_buf1;
  disp_drv.flush_cb     = sdl_display_flush;
  disp_drv.hor_res      = LV_HOR_RES_MAX;
  disp_drv.ver_res      = LV_VER_RES_MAX;
  disp_drv.antialiasing = 1;

  lv_disp_t* disp = lv_disp_drv_register(&disp_drv);

  lv_theme_t* th =
      lv_theme_default_init(disp, lv_palette_main(LV_PALETTE_BLUE), lv_palette_main(LV_PALETTE_RED),
                            LV_THEME_DEFAULT_DARK, LV_FONT_DEFAULT);
  lv_disp_set_theme(disp, th);

  lv_group_t* g = lv_group_create();
  lv_group_set_default(g);

  static lv_indev_drv_t indev_drv_1;
  lv_indev_drv_init(&indev_drv_1); /*Basic initialization*/
  indev_drv_1.type = LV_INDEV_TYPE_POINTER;

  /*This function will be called periodically (by the library) to get the mouse position and state*/
  indev_drv_1.read_cb     = sdl_mouse_read;
  lv_indev_t* mouse_indev = lv_indev_drv_register(&indev_drv_1);

  static lv_indev_drv_t indev_drv_2;
  lv_indev_drv_init(&indev_drv_2); /*Basic initialization*/
  indev_drv_2.type     = LV_INDEV_TYPE_KEYPAD;
  indev_drv_2.read_cb  = sdl_keyboard_read;
  lv_indev_t* kb_indev = lv_indev_drv_register(&indev_drv_2);
  lv_indev_set_group(kb_indev, g);

  static lv_indev_drv_t indev_drv_3;
  lv_indev_drv_init(&indev_drv_3); /*Basic initialization*/
  indev_drv_3.type    = LV_INDEV_TYPE_ENCODER;
  indev_drv_3.read_cb = sdl_mousewheel_read;

  lv_indev_t* enc_indev = lv_indev_drv_register(&indev_drv_3);
  lv_indev_set_group(enc_indev, g);

  /*Set a cursor for the mouse*/
  LV_IMG_DECLARE(mouse_cursor_icon);                  /*Declare the image file.*/
  lv_obj_t* cursor_obj = lv_img_create(lv_scr_act()); /*Create an image object for the cursor */
  lv_img_set_src(cursor_obj, &mouse_cursor_icon);     /*Set the image source*/
  lv_indev_set_cursor(mouse_indev, cursor_obj);       /*Connect the image  object to the driver*/

  SDL_CreateThread(tick_thread, "tick", NULL);
}

static int lv_thread(void* data) {
  /*Initialize LVGL*/
  lv_init();

  /*Initialize the HAL (display, input devices, tick) for LVGL*/
  hal_init();

  // lv_example_switch_1();
  // lv_example_calendar_1();
  // lv_example_btnmatrix_2();
  // lv_example_checkbox_1();
  // lv_example_colorwheel_1();
  // lv_example_chart_7();
  // lv_example_canvas_1();
  // lv_example_table_2();
  // lv_example_scroll_2();
  // lv_example_textarea_1();
  // lv_example_menu_3();
  // lv_example_msgbox_1();
  // lv_example_dropdown_2();
  // lv_example_btn_1();
  // lv_example_scroll_1();
  // lv_example_tabview_1();
  // lv_example_switch_1();
  // lv_example_flex_3();
  // lv_example_label_1();
  // lv_example_anim_1();
  // lv_example_anim_2();
  // lv_example_anim_3();
  // lv_example_anim_timeline_1();
  // lv_example_win_1();
  lv_demo_widgets();
  // lv_demo_keypad_encoder();
  // lv_demo_benchmark();
  // lv_demo_stress();
  // lv_demo_music();
  // lv_example_ffmpeg_1();
  // lv_example_ffmpeg_2();
  // lv_example_qrcode_1();
  // lv_example_gif_1();
  // lv_btn();

  while (1) {
    lv_timer_handler();
    SDL_Delay(5);
  }
  return 0;
}

int lv_main(int argc, char* args[]) {
  (void)argc; /*Unused*/
  (void)args; /*Unused*/

  SDL_CreateThread(lv_thread, "lvgl", NULL);
  return 0;
}
