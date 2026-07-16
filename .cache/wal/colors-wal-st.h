const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#1d2543", /* black   */
  [1] = "#2D9BFA", /* red     */
  [2] = "#39A7FA", /* green   */
  [3] = "#48B5F9", /* yellow  */
  [4] = "#5DB9F5", /* blue    */
  [5] = "#57C5F8", /* magenta */
  [6] = "#6ACFF9", /* cyan    */
  [7] = "#c6c8d0", /* white   */

  /* 8 bright colors */
  [8]  = "#6b7084",  /* black   */
  [9]  = "#2D9BFA",  /* red     */
  [10] = "#39A7FA", /* green   */
  [11] = "#48B5F9", /* yellow  */
  [12] = "#5DB9F5", /* blue    */
  [13] = "#57C5F8", /* magenta */
  [14] = "#6ACFF9", /* cyan    */
  [15] = "#c6c8d0", /* white   */

  /* special colors */
  [256] = "#1d2543", /* background */
  [257] = "#c6c8d0", /* foreground */
  [258] = "#c6c8d0",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
