static const char norm_fg[] = "#c6c8d0";
static const char norm_bg[] = "#1d2543";
static const char norm_border[] = "#6b7084";

static const char sel_fg[] = "#c6c8d0";
static const char sel_bg[] = "#39A7FA";
static const char sel_border[] = "#c6c8d0";

static const char urg_fg[] = "#c6c8d0";
static const char urg_bg[] = "#2D9BFA";
static const char urg_border[] = "#2D9BFA";

static const char *colors[][3]      = {
    /*               fg           bg         border                         */
    [SchemeNorm] = { norm_fg,     norm_bg,   norm_border }, // unfocused wins
    [SchemeSel]  = { sel_fg,      sel_bg,    sel_border },  // the focused win
    [SchemeUrg] =  { urg_fg,      urg_bg,    urg_border },
};
