/**
 * @file lv_ffmpeg2.c
 *
 */

/*********************
 *      INCLUDES
 *********************/
#include "lv_ffmpeg2.h"
#if LV_USE_FFMPEG != 0

#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavutil/imgutils.h>
#include <libavutil/samplefmt.h>
#include <libavutil/timestamp.h>
#include <libswscale/swscale.h>

/*********************
 *      DEFINES
 *********************/
#if LV_COLOR_DEPTH == 1 || LV_COLOR_DEPTH == 8
    #define AV_PIX_FMT_TRUE_COLOR AV_PIX_FMT_RGB8
#elif LV_COLOR_DEPTH == 16
    #define AV_PIX_FMT_TRUE_COLOR AV_PIX_FMT_RGB565LE
#elif LV_COLOR_DEPTH == 32
    #define AV_PIX_FMT_TRUE_COLOR AV_PIX_FMT_BGR0
#else
    #error Unsupported  LV_COLOR_DEPTH
#endif

#define MY_CLASS &lv_ffmpeg2_player_class

#define FRAME_DEF_REFR_PERIOD   33  /*[ms]*/

/**********************
 *      TYPEDEFS
 **********************/
struct ffmpeg2_context_s {
    AVFormatContext * fmt_ctx;
    AVCodecContext * video_dec_ctx;
    AVStream * video_stream;
    uint8_t * video_src_data[4];
    uint8_t * video_dst_data[4];
    struct SwsContext * sws_ctx;
    AVFrame * frame;
    AVPacket pkt;
    int video_stream_idx;
    int video_src_linesize[4];
    int video_dst_linesize[4];
    enum AVPixelFormat video_dst_pix_fmt;
    bool has_alpha;
    int dst_width;
    int dst_height;
};

#pragma pack(1)

struct lv_img_pixel_color_s {
    lv_color_t c;
    uint8_t alpha;
};

#pragma pack()

/**********************
 *  STATIC PROTOTYPES
 **********************/

static struct ffmpeg2_context_s * ffmpeg2_open_file(const char * path);
static void ffmpeg2_close(struct ffmpeg2_context_s * ffmpeg2_ctx);
static void ffmpeg2_close_src_ctx(struct ffmpeg2_context_s * ffmpeg2_ctx);
static void ffmpeg2_close_dst_ctx(struct ffmpeg2_context_s * ffmpeg2_ctx);
static int ffmpeg2_image_allocate(struct ffmpeg2_context_s * ffmpeg2_ctx);
static int ffmpeg2_get_frame_refr_period(struct ffmpeg2_context_s * ffmpeg2_ctx);
static uint8_t * ffmpeg2_get_img_data(struct ffmpeg2_context_s * ffmpeg2_ctx);
static int ffmpeg2_update_next_frame(struct ffmpeg2_context_s * ffmpeg2_ctx);
static int ffmpeg2_output_video_frame(struct ffmpeg2_context_s * ffmpeg2_ctx);
static bool ffmpeg2_pix_fmt_has_alpha(enum AVPixelFormat pix_fmt);
static bool ffmpeg2_pix_fmt_is_yuv(enum AVPixelFormat pix_fmt);

static void lv_ffmpeg2_player_constructor(const lv_obj_class_t * class_p, lv_obj_t * obj);
static void lv_ffmpeg2_player_destructor(const lv_obj_class_t * class_p, lv_obj_t * obj);

#if LV_COLOR_DEPTH != 32
    static void convert_color_depth(uint8_t * img, uint32_t px_cnt);
#endif

/**********************
 *  STATIC VARIABLES
 **********************/
const lv_obj_class_t lv_ffmpeg2_player_class = {
    .constructor_cb = lv_ffmpeg2_player_constructor,
    .destructor_cb = lv_ffmpeg2_player_destructor,
    .instance_size = sizeof(lv_ffmpeg2_player_t),
    .base_class = &lv_img_class
};

/**********************
 *      MACROS
 **********************/

/**********************
 *   GLOBAL FUNCTIONS
 **********************/

int lv_ffmpeg2_get_frame_num(const char * path)
{
    int ret = -1;
    struct ffmpeg2_context_s * ffmpeg2_ctx = ffmpeg2_open_file(path);

    if(ffmpeg2_ctx) {
        ret = ffmpeg2_ctx->video_stream->nb_frames;
        ffmpeg2_close(ffmpeg2_ctx);
    }

    return ret;
}

lv_obj_t * lv_ffmpeg2_player_create(lv_obj_t * parent)
{
    lv_obj_t * obj = lv_obj_class_create_obj(MY_CLASS, parent);
    lv_obj_class_init_obj(obj);
    return obj;
}

lv_res_t lv_ffmpeg2_player_set_src(lv_obj_t * obj, const char * path)
{
    LV_ASSERT_OBJ(obj, MY_CLASS);
    lv_res_t res = LV_RES_INV;

    lv_ffmpeg2_player_t * player = (lv_ffmpeg2_player_t *)obj;

    if(player->ffmpeg2_ctx) {
        ffmpeg2_close(player->ffmpeg2_ctx);
        player->ffmpeg2_ctx = NULL;
    }

    lv_timer_pause(player->timer);

    player->ffmpeg2_ctx = ffmpeg2_open_file(path);
    player->ffmpeg2_ctx->dst_width  = lv_obj_get_width(obj) ? lv_obj_get_width(obj)
                                     : lv_obj_get_content_width(obj)
                                         ? lv_obj_get_content_width(obj)
                                         : player->ffmpeg2_ctx->video_dec_ctx->width;
    player->ffmpeg2_ctx->dst_height = lv_obj_get_height(obj) ? lv_obj_get_height(obj)
                                     : lv_obj_get_content_height(obj)
                                         ? lv_obj_get_content_height(obj)
                                         : player->ffmpeg2_ctx->video_dec_ctx->height;

    if(!player->ffmpeg2_ctx) {
        LV_LOG_ERROR("ffmpeg2 file open failed: %s", path);
        goto failed;
    }

    if(ffmpeg2_image_allocate(player->ffmpeg2_ctx) < 0) {
        LV_LOG_ERROR("ffmpeg2 image allocate failed");
        ffmpeg2_close(player->ffmpeg2_ctx);
        goto failed;
    }

    bool has_alpha = player->ffmpeg2_ctx->has_alpha;
    int width = player->ffmpeg2_ctx->dst_width;
    int height = player->ffmpeg2_ctx->dst_height;
    uint32_t data_size = 0;

    if(has_alpha) {
        data_size = width * height * LV_IMG_PX_SIZE_ALPHA_BYTE;
    }
    else {
        data_size = width * height * LV_COLOR_SIZE / 8;
    }

    player->imgdsc.header.always_zero = 0;
    player->imgdsc.header.w = width;
    player->imgdsc.header.h = height;
    player->imgdsc.data_size = data_size;
    player->imgdsc.header.cf = has_alpha ? LV_IMG_CF_TRUE_COLOR_ALPHA : LV_IMG_CF_TRUE_COLOR;
    player->imgdsc.data = ffmpeg2_get_img_data(player->ffmpeg2_ctx);

    lv_img_set_src(&player->img.obj, &(player->imgdsc));

    int period = ffmpeg2_get_frame_refr_period(player->ffmpeg2_ctx);

    if(period > 0) {
        LV_LOG_INFO("frame refresh period = %d ms, rate = %d fps",
                    period, 1000 / period);
        lv_timer_set_period(player->timer, period);
    }
    else {
        LV_LOG_WARN("unable to get frame refresh period");
    }

    res = LV_RES_OK;

failed:
    return res;
}

void lv_ffmpeg2_player_set_cmd(lv_obj_t * obj, lv_ffmpeg_player_cmd_t cmd)
{
    LV_ASSERT_OBJ(obj, MY_CLASS);
    lv_ffmpeg2_player_t * player = (lv_ffmpeg2_player_t *)obj;

    if(!player->ffmpeg2_ctx) {
        LV_LOG_ERROR("ffmpeg2_ctx is NULL");
        return;
    }

    lv_timer_t * timer = player->timer;

    switch(cmd) {
        case LV_FFMPEG_PLAYER_CMD_START:
            av_seek_frame(player->ffmpeg2_ctx->fmt_ctx,
                          0, 0, AVSEEK_FLAG_BACKWARD);
            lv_timer_resume(timer);
            LV_LOG_INFO("ffmpeg2 player start");
            break;
        case LV_FFMPEG_PLAYER_CMD_STOP:
            av_seek_frame(player->ffmpeg2_ctx->fmt_ctx,
                          0, 0, AVSEEK_FLAG_BACKWARD);
            lv_timer_pause(timer);
            LV_LOG_INFO("ffmpeg2 player stop");
            break;
        case LV_FFMPEG_PLAYER_CMD_PAUSE:
            lv_timer_pause(timer);
            LV_LOG_INFO("ffmpeg2 player pause");
            break;
        case LV_FFMPEG_PLAYER_CMD_RESUME:
            lv_timer_resume(timer);
            LV_LOG_INFO("ffmpeg2 player resume");
            break;
        default:
            LV_LOG_ERROR("Error cmd: %d", cmd);
            break;
    }
}

void lv_ffmpeg2_player_set_auto_restart(lv_obj_t * obj, bool en)
{
    LV_ASSERT_OBJ(obj, MY_CLASS);
    lv_ffmpeg2_player_t * player = (lv_ffmpeg2_player_t *)obj;
    player->auto_restart = en;
}

/**********************
 *   STATIC FUNCTIONS
 **********************/

#if LV_COLOR_DEPTH != 32

static void convert_color_depth(uint8_t * img, uint32_t px_cnt)
{
    lv_color32_t * img_src_p = (lv_color32_t *)img;
    struct lv_img_pixel_color_s * img_dst_p = (struct lv_img_pixel_color_s *)img;

    for(uint32_t i = 0; i < px_cnt; i++) {
        lv_color32_t temp = *img_src_p;
        img_dst_p->c = lv_color_hex(temp.full);
        img_dst_p->alpha = temp.ch.alpha;

        img_src_p++;
        img_dst_p++;
    }
}

#endif

static uint8_t * ffmpeg2_get_img_data(struct ffmpeg2_context_s * ffmpeg2_ctx)
{
    uint8_t * img_data = ffmpeg2_ctx->video_dst_data[0];

    if(img_data == NULL) {
        LV_LOG_ERROR("ffmpeg2 video dst data is NULL");
    }

    return img_data;
}

static bool ffmpeg2_pix_fmt_has_alpha(enum AVPixelFormat pix_fmt)
{
    const AVPixFmtDescriptor * desc = av_pix_fmt_desc_get(pix_fmt);

    if(desc == NULL) {
        return false;
    }

    if(pix_fmt == AV_PIX_FMT_PAL8) {
        return true;
    }

    return (desc->flags & AV_PIX_FMT_FLAG_ALPHA) ? true : false;
}

static bool ffmpeg2_pix_fmt_is_yuv(enum AVPixelFormat pix_fmt)
{
    const AVPixFmtDescriptor * desc = av_pix_fmt_desc_get(pix_fmt);

    if(desc == NULL) {
        return false;
    }

    return !(desc->flags & AV_PIX_FMT_FLAG_RGB) && desc->nb_components >= 2;
}

static int ffmpeg2_output_video_frame(struct ffmpeg2_context_s * ffmpeg2_ctx)
{
    int ret = -1;

    int width = ffmpeg2_ctx->video_dec_ctx->width;
    int height = ffmpeg2_ctx->video_dec_ctx->height;
    AVFrame * frame = ffmpeg2_ctx->frame;

    if(frame->width != width
       || frame->height != height
       || frame->format != ffmpeg2_ctx->video_dec_ctx->pix_fmt) {

        /* To handle this change, one could call av_image_alloc again and
         * decode the following frames into another rawvideo file.
         */
        LV_LOG_ERROR("Width, height and pixel format have to be "
                     "constant in a rawvideo file, but the width, height or "
                     "pixel format of the input video changed:\n"
                     "old: width = %d, height = %d, format = %s\n"
                     "new: width = %d, height = %d, format = %s\n",
                     width,
                     height,
                     av_get_pix_fmt_name(ffmpeg2_ctx->video_dec_ctx->pix_fmt),
                     frame->width, frame->height,
                     av_get_pix_fmt_name(frame->format));
        goto failed;
    }

    LV_LOG_TRACE("video_frame coded_n:%d", frame->coded_picture_number);

    /* copy decoded frame to destination buffer:
     * this is required since rawvideo expects non aligned data
     */
    av_image_copy(ffmpeg2_ctx->video_src_data, ffmpeg2_ctx->video_src_linesize,
                  (const uint8_t **)(frame->data), frame->linesize,
                  ffmpeg2_ctx->video_dec_ctx->pix_fmt, width, height);

    if(ffmpeg2_ctx->sws_ctx == NULL) {
        int swsFlags = SWS_BILINEAR;

        if(ffmpeg2_pix_fmt_is_yuv(ffmpeg2_ctx->video_dec_ctx->pix_fmt)) {

            /* When the video width and height are not multiples of 8,
             * and there is no size change in the conversion,
             * a blurry screen will appear on the right side
             * This problem was discovered in 2012 and
             * continues to exist in version 4.1.3 in 2019
             * This problem can be avoided by increasing SWS_ACCURATE_RND
             */
            if((width & 0x7) || (height & 0x7)) {
                LV_LOG_WARN("The width(%d) and height(%d) the image "
                            "is not a multiple of 8, "
                            "the decoding speed may be reduced",
                            width, height);
                swsFlags |= SWS_ACCURATE_RND;
            }
        }

        ffmpeg2_ctx->sws_ctx = sws_getContext(
                                  width, height, ffmpeg2_ctx->video_dec_ctx->pix_fmt,
                                  ffmpeg2_ctx->dst_width, ffmpeg2_ctx->dst_height, ffmpeg2_ctx->video_dst_pix_fmt,
                                  swsFlags,
                                  NULL, NULL, NULL);
    }

    ret = sws_scale(
              ffmpeg2_ctx->sws_ctx,
              (const uint8_t * const *)(ffmpeg2_ctx->video_src_data),
              ffmpeg2_ctx->video_src_linesize,
              0,
              height,
              ffmpeg2_ctx->video_dst_data,
              ffmpeg2_ctx->video_dst_linesize);

failed:
    return ret;
}

static int ffmpeg2_decode_packet(AVCodecContext * dec, const AVPacket * pkt,
                                struct ffmpeg2_context_s * ffmpeg2_ctx)
{
    int ret = 0;

    /* submit the packet to the decoder */
    ret = avcodec_send_packet(dec, pkt);
    if(ret < 0) {
        LV_LOG_ERROR("Error submitting a packet for decoding (%s)",
                     av_err2str(ret));
        return ret;
    }

    /* get all the available frames from the decoder */
    while(ret >= 0) {
        ret = avcodec_receive_frame(dec, ffmpeg2_ctx->frame);
        if(ret < 0) {

            /* those two return values are special and mean there is
             * no output frame available,
             * but there were no errors during decoding
             */
            if(ret == AVERROR_EOF || ret == AVERROR(EAGAIN)) {
                return 0;
            }

            LV_LOG_ERROR("Error during decoding (%s)", av_err2str(ret));
            return ret;
        }

        /* write the frame data to output file */
        if(dec->codec->type == AVMEDIA_TYPE_VIDEO) {
            ret = ffmpeg2_output_video_frame(ffmpeg2_ctx);
        }

        av_frame_unref(ffmpeg2_ctx->frame);
        if(ret < 0) {
            LV_LOG_WARN("ffmpeg2_decode_packet ended %d", ret);
            return ret;
        }
    }

    return 0;
}

static int ffmpeg2_open_codec_context(int * stream_idx,
                                     AVCodecContext ** dec_ctx, AVFormatContext * fmt_ctx,
                                     enum AVMediaType type)
{
    int ret;
    int stream_index;
    AVStream * st;
    const AVCodec * dec = NULL;
    AVDictionary * opts = NULL;

    ret = av_find_best_stream(fmt_ctx, type, -1, -1, NULL, 0);
    if(ret < 0) {
        LV_LOG_ERROR("Could not find %s stream in input file",
                     av_get_media_type_string(type));
        return ret;
    }
    else {
        stream_index = ret;
        st = fmt_ctx->streams[stream_index];

        /* find decoder for the stream */
        dec = avcodec_find_decoder(st->codecpar->codec_id);
        if(dec == NULL) {
            LV_LOG_ERROR("Failed to find %s codec",
                         av_get_media_type_string(type));
            return AVERROR(EINVAL);
        }

        /* Allocate a codec context for the decoder */
        *dec_ctx = avcodec_alloc_context3(dec);
        if(*dec_ctx == NULL) {
            LV_LOG_ERROR("Failed to allocate the %s codec context",
                         av_get_media_type_string(type));
            return AVERROR(ENOMEM);
        }

        /* Copy codec parameters from input stream to output codec context */
        if((ret = avcodec_parameters_to_context(*dec_ctx, st->codecpar)) < 0) {
            LV_LOG_ERROR(
                "Failed to copy %s codec parameters to decoder context",
                av_get_media_type_string(type));
            return ret;
        }

        /* Init the decoders */
        if((ret = avcodec_open2(*dec_ctx, dec, &opts)) < 0) {
            LV_LOG_ERROR("Failed to open %s codec",
                         av_get_media_type_string(type));
            return ret;
        }

        *stream_idx = stream_index;
    }

    return 0;
}

static int ffmpeg2_get_frame_refr_period(struct ffmpeg2_context_s * ffmpeg2_ctx)
{
    int avg_frame_rate_num = ffmpeg2_ctx->video_stream->avg_frame_rate.num;
    if(avg_frame_rate_num > 0) {
        int period = 1000 * (int64_t)ffmpeg2_ctx->video_stream->avg_frame_rate.den
                     / avg_frame_rate_num;
        return period;
    }

    return -1;
}

static int ffmpeg2_update_next_frame(struct ffmpeg2_context_s * ffmpeg2_ctx)
{
    int ret = 0;

    while(1) {

        /* read frames from the file */
        if(av_read_frame(ffmpeg2_ctx->fmt_ctx, &(ffmpeg2_ctx->pkt)) >= 0) {
            bool is_image = false;

            /* check if the packet belongs to a stream we are interested in,
             * otherwise skip it
             */
            if(ffmpeg2_ctx->pkt.stream_index == ffmpeg2_ctx->video_stream_idx) {
                ret = ffmpeg2_decode_packet(ffmpeg2_ctx->video_dec_ctx,
                                           &(ffmpeg2_ctx->pkt), ffmpeg2_ctx);
                is_image = true;
            }

            av_packet_unref(&(ffmpeg2_ctx->pkt));

            if(ret < 0) {
                LV_LOG_WARN("video frame is empty %d", ret);
                break;
            }

            /* Used to filter data that is not an image */
            if(is_image) {
                break;
            }
        }
        else {
            ret = -1;
            break;
        }
    }

    return ret;
}

struct ffmpeg2_context_s * ffmpeg2_open_file(const char * path)
{
    if(path == NULL || strlen(path) == 0) {
        LV_LOG_ERROR("file path is empty");
        return NULL;
    }

    struct ffmpeg2_context_s * ffmpeg2_ctx = calloc(1, sizeof(struct ffmpeg2_context_s));

    if(ffmpeg2_ctx == NULL) {
        LV_LOG_ERROR("ffmpeg2_ctx malloc failed");
        goto failed;
    }

    /* open input file, and allocate format context */

    if(avformat_open_input(&(ffmpeg2_ctx->fmt_ctx), path, NULL, NULL) < 0) {
        LV_LOG_ERROR("Could not open source file %s", path);
        goto failed;
    }

    /* retrieve stream information */

    if(avformat_find_stream_info(ffmpeg2_ctx->fmt_ctx, NULL) < 0) {
        LV_LOG_ERROR("Could not find stream information");
        goto failed;
    }

    if(ffmpeg2_open_codec_context(
           &(ffmpeg2_ctx->video_stream_idx),
           &(ffmpeg2_ctx->video_dec_ctx),
           ffmpeg2_ctx->fmt_ctx, AVMEDIA_TYPE_VIDEO)
       >= 0) {
        ffmpeg2_ctx->video_stream = ffmpeg2_ctx->fmt_ctx->streams[ffmpeg2_ctx->video_stream_idx];

        ffmpeg2_ctx->has_alpha = ffmpeg2_pix_fmt_has_alpha(ffmpeg2_ctx->video_dec_ctx->pix_fmt);

        ffmpeg2_ctx->video_dst_pix_fmt = (ffmpeg2_ctx->has_alpha ? AV_PIX_FMT_BGRA : AV_PIX_FMT_TRUE_COLOR);
    }

#if LV_FFMPEG_AV_DUMP_FORMAT != 0
    /* dump input information to stderr */
    av_dump_format(ffmpeg2_ctx->fmt_ctx, 0, path, 0);
#endif

    if(ffmpeg2_ctx->video_stream == NULL) {
        LV_LOG_ERROR("Could not find video stream in the input, aborting");
        goto failed;
    }

    return ffmpeg2_ctx;

failed:
    ffmpeg2_close(ffmpeg2_ctx);
    return NULL;
}

static int ffmpeg2_image_allocate(struct ffmpeg2_context_s * ffmpeg2_ctx)
{
    int ret;

    /* allocate image where the decoded image will be put */
    ret = av_image_alloc(
              ffmpeg2_ctx->video_src_data,
              ffmpeg2_ctx->video_src_linesize,
              ffmpeg2_ctx->video_dec_ctx->width,
              ffmpeg2_ctx->video_dec_ctx->height,
              ffmpeg2_ctx->video_dec_ctx->pix_fmt,
              4);

    if(ret < 0) {
        LV_LOG_ERROR("Could not allocate src raw video buffer");
        return ret;
    }

    LV_LOG_INFO("alloc video_src_bufsize = %d", ret);

    ret = av_image_alloc(
              ffmpeg2_ctx->video_dst_data,
              ffmpeg2_ctx->video_dst_linesize,
              ffmpeg2_ctx->dst_width,
              ffmpeg2_ctx->dst_height,
              ffmpeg2_ctx->video_dst_pix_fmt,
              4);

    if(ret < 0) {
        LV_LOG_ERROR("Could not allocate dst raw video buffer");
        return ret;
    }

    LV_LOG_INFO("allocate video_dst_bufsize = %d", ret);

    ffmpeg2_ctx->frame = av_frame_alloc();

    if(ffmpeg2_ctx->frame == NULL) {
        LV_LOG_ERROR("Could not allocate frame");
        return -1;
    }

    /* initialize packet, set data to NULL, let the demuxer fill it */
    av_init_packet(&ffmpeg2_ctx->pkt);
    ffmpeg2_ctx->pkt.data = NULL;
    ffmpeg2_ctx->pkt.size = 0;

    return 0;
}

static void ffmpeg2_close_src_ctx(struct ffmpeg2_context_s * ffmpeg2_ctx)
{
    avcodec_free_context(&(ffmpeg2_ctx->video_dec_ctx));
    avformat_close_input(&(ffmpeg2_ctx->fmt_ctx));
    av_frame_free(&(ffmpeg2_ctx->frame));
    if(ffmpeg2_ctx->video_src_data[0] != NULL) {
        av_free(ffmpeg2_ctx->video_src_data[0]);
        ffmpeg2_ctx->video_src_data[0] = NULL;
    }
}

static void ffmpeg2_close_dst_ctx(struct ffmpeg2_context_s * ffmpeg2_ctx)
{
    if(ffmpeg2_ctx->video_dst_data[0] != NULL) {
        av_free(ffmpeg2_ctx->video_dst_data[0]);
        ffmpeg2_ctx->video_dst_data[0] = NULL;
    }
}

static void ffmpeg2_close(struct ffmpeg2_context_s * ffmpeg2_ctx)
{
    if(ffmpeg2_ctx == NULL) {
        LV_LOG_WARN("ffmpeg2_ctx is NULL");
        return;
    }

    sws_freeContext(ffmpeg2_ctx->sws_ctx);
    ffmpeg2_close_src_ctx(ffmpeg2_ctx);
    ffmpeg2_close_dst_ctx(ffmpeg2_ctx);
    free(ffmpeg2_ctx);

    LV_LOG_INFO("ffmpeg2_ctx closed");
}

static void lv_ffmpeg2_player_frame_update_cb(lv_timer_t * timer)
{
    lv_obj_t * obj = (lv_obj_t *)timer->user_data;
    lv_ffmpeg2_player_t * player = (lv_ffmpeg2_player_t *)obj;

    if(!player->ffmpeg2_ctx) {
        return;
    }

    int has_next = ffmpeg2_update_next_frame(player->ffmpeg2_ctx);

    if(has_next < 0) {
        lv_ffmpeg2_player_set_cmd(obj, player->auto_restart ? LV_FFMPEG_PLAYER_CMD_START : LV_FFMPEG_PLAYER_CMD_STOP);
        return;
    }

#if LV_COLOR_DEPTH != 32
    if(player->ffmpeg2_ctx->has_alpha) {
        convert_color_depth((uint8_t *)(player->imgdsc.data),
                            player->imgdsc.header.w * player->imgdsc.header.h);
    }
#endif

    lv_img_cache_invalidate_src(lv_img_get_src(obj));
    lv_obj_invalidate(obj);
}

static void lv_ffmpeg2_player_constructor(const lv_obj_class_t * class_p,
                                         lv_obj_t * obj)
{
    LV_TRACE_OBJ_CREATE("begin");

    lv_ffmpeg2_player_t * player = (lv_ffmpeg2_player_t *)obj;

    player->auto_restart = false;
    player->ffmpeg2_ctx = NULL;
    player->timer = lv_timer_create(lv_ffmpeg2_player_frame_update_cb,
                                    FRAME_DEF_REFR_PERIOD, obj);
    lv_timer_pause(player->timer);

    LV_TRACE_OBJ_CREATE("finished");
}

static void lv_ffmpeg2_player_destructor(const lv_obj_class_t * class_p,
                                        lv_obj_t * obj)
{
    LV_TRACE_OBJ_CREATE("begin");

    lv_ffmpeg2_player_t * player = (lv_ffmpeg2_player_t *)obj;

    if(player->timer) {
        lv_timer_del(player->timer);
        player->timer = NULL;
    }

    lv_img_cache_invalidate_src(lv_img_get_src(obj));

    ffmpeg2_close(player->ffmpeg2_ctx);
    player->ffmpeg2_ctx = NULL;

    LV_TRACE_OBJ_CREATE("finished");
}

#endif /*LV_USE_FFMPEG*/
