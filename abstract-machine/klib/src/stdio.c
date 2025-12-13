#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>
#include <limits.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

int printf(const char *fmt, ...) {
  panic("Not implemented");
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  panic("Not implemented");
}

int sprintf(char *out, const char *fmt, ...) {
    va_list ap;
    int d;
    char *s;
    char *start = out;
    va_start(ap, fmt);
    while(*fmt){
        if(*fmt != '%') *out++ = *fmt++;
        else{
            fmt ++;
            switch(*fmt++){
                case 's':
                    s =va_arg(ap, char *);
                    while(*s != '\0'){
                        *out++ = *s++;
                    }
                    break;
                case 'd':
                    unsigned int ud = 0;
                    d = va_arg(ap, int);
                    if(d == INT_MIN){
                        *out++ = '-';
                        ud = (unsigned int)INT_MAX + 1u;
                    }
                    else if(d < 0){
                        *out++ = '-';
                        ud = (unsigned int)(-d);
                    }
                    else if(d == 0){
                        *out ++ = '0';
                    }
                    else{
                        ud = (unsigned int)d;
                    }
                    char tmp[32];
                    int n = 0;
                    while(ud != 0){
                        tmp[n] = ud % 10 + '0';
                        ud /= 10;
                        n ++;
                    }
                    for(int i = n-1; i >= 0; i --){
                        *out = tmp[i];
                        out ++;
                    }
                    break;
            }
        }
    }
    va_end(ap);
    *out = '\0';
    return out - start;
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  panic("Not implemented");
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  panic("Not implemented");
}

#endif
