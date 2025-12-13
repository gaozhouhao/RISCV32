#include <klib.h>
#include <klib-macros.h>
#include <stdint.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

size_t strlen(const char *s) {
    size_t num = 0;
    while(*s != '\0'){
        s ++;
        num ++;
    }
    return num;
}

char *strcpy(char *dst, const char *src) {
    memcpy(dst, src, strlen(src)+1);
    return dst;
}

char *strncpy(char *dst, const char *src, size_t n) {
  panic("Not implemented");
}

char *strcat(char *dst, const char *src) {
    strcpy(dst + strlen(dst), src);
    return dst;
}

int strcmp(const char *s1, const char *s2) {
    while(*s1 != '\0' && *s2 != '\0'){
        if(*s1 < *s2) return -1;
        if(*s1 > *s2) return 1;
        s1 ++;
        s2 ++;
    }
    return 0;
}

int strncmp(const char *s1, const char *s2, size_t n) {
  panic("Not implemented");
}

void *memset(void *s, int c, size_t n) {
    char *d = (char *)s;
    while(n --){
        *d = (char)c;
        d ++;
    }
    return s;
}

void *memmove(void *dst, const void *src, size_t n) {
  panic("Not implemented");
}

void *memcpy(void *out, const void *in, size_t n) {   
    char *d = (char *)out;
    const char *s = (const char *)in;
    for(int i = 0;  i < n; i ++){ 
       *d = *s;
        d ++;
        s ++;
    }
    return out;
}

int memcmp(const void *s1, const void *s2, size_t n) {
    const unsigned char *d = (const unsigned char *)s1;
    const unsigned char *s = (const unsigned char *)s2;
    while(n --){
        if(*d < *s) return -1;
        if(*d > *s) return 1;
        s ++;
        d ++;
    }
    return 0;
}

#endif
