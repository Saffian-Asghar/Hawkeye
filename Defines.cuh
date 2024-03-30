#pragma once
#include <math.h>
#define pixelI(x,y,width,channel) ((x * width + y ) * channel)

#define redI(x,y,width,channel)  (pixelI(x,y,width,channel)+0)
#define greenI(x,y,width,channel) (pixelI(x,y,width,channel)+1)
#define blueI(x,y,width,channel) (pixelI(x,y,width,channel)+2)

#define get_grey(r,g,b) ((0.2989 * (int)r) + (0.5870 * (int)g) + (0.1140 * (int)b))

#define getIndex(bid,bdim,tid)(bid*bdim+tid)

#define withIn(a,b,err) (abs((int)a-(int)b)>= (int)err)
#define withInRange(a,b,err) (abs((int)a-(int)b)<= (int)err)


#define FRAME_THRESH_COUNT 50
#define FRAME_THRESH_REFRESH (FRAME_THRESH_COUNT*10)
#define FRAME_COMPARE_ERROR 16