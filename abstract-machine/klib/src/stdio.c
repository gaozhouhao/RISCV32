#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>
#include <limits.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

int printf(const char *fmt, ...) {
    char out[65536];
    va_list ap;
    va_start(ap, fmt);
    int num = vsprintf(out, fmt, ap);
    int i = 0;
    while(*(out+i) != '\0'){
        putch(*(out+i));
        i ++;
    }
    va_end(ap);
    return num;
}

inline int u32_dev_len(unsigned int num){
    int cnt = 0;
    while(num != 0){
        num /= 10;
        cnt ++;
    }
    return cnt;
}

inline int u32_hex_len(unsigned int num){
    int cnt = 0;
    while(num != 0){
        num /= 16;
        cnt ++;
    }
    return cnt;
}


int vsprintf(char *out, const char *fmt, va_list ap) {
    int d;
    int format_flag = 0;
    char *s;
    char *start = out;
    while(*fmt){
        if(*fmt != '%' && format_flag == 0) { *out++ = *fmt++; continue;}

        fmt ++;

        int width = 0;
        char padding = ' ';
        if(*fmt == '0') {padding = '0'; fmt ++;}
        while(*fmt >= '0' && *fmt <= '9'){
            width = width * 10 + *fmt -'0';
            fmt ++;
        }
        switch(*fmt++){
            case 's':
                s = va_arg(ap, char *);
                while(*s != '\0') { *out++ = *s++; }
                break;
            case 'c':
                int c = va_arg(ap, int);
                *out++ = (char)c;
                break;
            case 'd':
                unsigned int ud = 0;
                d = va_arg(ap, int);
                if(d == INT_MIN){
                    *out++ = '-';
                    ud = (unsigned int)INT_MAX + 1u;
                }
                else if(d == 0) {ud = 0; *out ++ = '0';}
                else if(d < 0){
                    ud = (unsigned int)(-d);
                    if (padding == ' '){
                        for(int i = 0; i < width - u32_dev_len(ud) - 1; i ++)
                            *out ++ = ' ';
                        *out ++ = '-';
                    }
                    if (padding == '0'){
                        *out ++ = '-';
                        for (int i = 0; i < width - u32_dev_len(ud); i ++)
                            *out ++ = '0';
                    }
                }
                else{ 
                    ud = (unsigned int)d;
                    for (int i = 0; i < width - u32_dev_len(ud); i ++)
                        *out ++ = padding;
                }
                for (int i = u32_dev_len(ud); i > 0; i --){
                    unsigned int temp = ud;
                    for (int j = 0; j < i-1; j ++) { temp /= 10; }
                    *out ++ = temp%10 + '0';
                }
                break;
            case 'x':
                unsigned int x = va_arg(ap, unsigned int);
                for (int i = 0; i < width - u32_hex_len(x); i ++)
                    *out ++ = padding;
                for (int i = u32_hex_len(x); i > 0; i --){
                    unsigned int temp = x;
                    for (int j = 0; j < i-1; j ++) { temp /= 16; }
                    if(temp%16 < 10) *out ++ = temp%16 + '0';
                    else             *out ++ = temp%16 - 10 + 'a';
                }
                break;
        }
    }
    *out = '\0';
    return out - start;
}

int sprintf(char *out, const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    int n = vsprintf(out, fmt, ap);
    va_end(ap);
    return n;
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  panic("Not implemented");
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  panic("Not implemented");
}

#endif
