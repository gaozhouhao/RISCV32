#include <am.h>
#include <riscv/riscv.h>

#define systemFrequency 5

void __am_timer_init() {
}

void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime) {
    uint32_t high1, low, high2;
    do{
        high1 = inl(0xa0000048 + 4);
        low = inl(0xa0000048 + 0);
        high2 = inl(0xa0000048 + 4);
    }while(high1 != high2);
  uptime->us = (((uint64_t)high1 << 32) | low) * systemFrequency;
}

void __am_timer_rtc(AM_TIMER_RTC_T *rtc) {
  rtc->second = 0;
  rtc->minute = 0;
  rtc->hour   = 0;
  rtc->day    = 0;
  rtc->month  = 0;
  rtc->year   = 1900;
}
