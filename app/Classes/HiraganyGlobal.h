#ifndef __HIRAGANY_GLOBAL_H__
#define __HIRAGANY_GLOBAL_H__

#ifdef DEBUG
# define DebugLog(...) NSLog(__VA_ARGS__)
#else
# define DebugLog(...) ;
#endif

#endif
