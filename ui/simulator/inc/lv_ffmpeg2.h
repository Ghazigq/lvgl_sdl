/**
 * @file lv_ffmpeg2.h
 *
 */
#ifndef LV_FFMPEG2_H
#define LV_FFMPEG2_H

#ifdef __cplusplus
extern "C" {
#endif

/*********************
 *      INCLUDES
 *********************/
#include "lvgl.h"
#if LV_USE_FFMPEG != 0

/*********************
 *      DEFINES
 *********************/

/**********************
 *      TYPEDEFS
 **********************/
struct ffmpeg2_context_s;

extern const lv_obj_class_t lv_ffmpeg2_player_class;

typedef struct {
    lv_img_t img;
    lv_timer_t * timer;
    lv_img_dsc_t imgdsc;
    bool auto_restart;
    struct ffmpeg2_context_s * ffmpeg2_ctx;
} lv_ffmpeg2_player_t;

/**********************
 * GLOBAL PROTOTYPES
 **********************/

/**
 * Get the number of frames contained in the file
 * @param path image or video file name
 * @return Number of frames, less than 0 means failed
 */
int lv_ffmpeg2_get_frame_num(const char * path);

/**
 * Create ffmpeg2_player object
 * @param parent pointer to an object, it will be the parent of the new player
 * @return pointer to the created ffmpeg2_player
 */
lv_obj_t * lv_ffmpeg2_player_create(lv_obj_t * parent);

/**
 * Set the path of the file to be played
 * @param obj pointer to a ffmpeg2_player object
 * @param path video file path
 * @return LV_RES_OK: no error; LV_RES_INV: can't get the info.
 */
lv_res_t lv_ffmpeg2_player_set_src(lv_obj_t * obj, const char * path);

/**
 * Set command control video player
 * @param obj pointer to a ffmpeg2_player object
 * @param cmd control commands
 */
void lv_ffmpeg2_player_set_cmd(lv_obj_t * obj, lv_ffmpeg_player_cmd_t cmd);

/**
 * Set the video to automatically replay
 * @param obj pointer to a ffmpeg2_player object
 * @param en true: enable the auto restart
 */
void lv_ffmpeg2_player_set_auto_restart(lv_obj_t * obj, bool en);

/*=====================
 * Other functions
 *====================*/

/**********************
 *      MACROS
 **********************/

#endif /*LV_USE_FFMPEG*/

#ifdef __cplusplus
} /*extern "C"*/
#endif

#endif /*LV_FFMPEG2_H*/
