#include <am.h>
#include <riscv/riscv.h>

#define systemFrequency 5
#define RxB (uint8_t *)0x10000000
#define LSR (uint8_t *)0x10000005

void __am_uart_init() {
    uint8_t tmp = inb(0x10000003); //Control connections
    tmp |= 0x80;
    outb(0x10000003, tmp); //Divisor Latch Access bit.
    outb(0x10000000, 0x01); //(system clock speed) / (16 x desired baud rate)
    outb(0x10000001, 0x00);
    tmp = inb(0x10000003);
    tmp &= ~0x80;
    outb(0x10000003, tmp);
}


void __am_uart_rx(AM_UART_RX_T *rx) {
    if ((*LSR & 0x1) == 0x1) {
      rx->data = (char)*RxB;
    }
    else {
      rx->data = (char)0xff;
    }
  // uptime->us = (((uint64_t)high1 << 32) | low) * systemFrequency;
}

// void __am_timer_rtc(AM_TIMER_RTC_T *rtc) {
//   rtc->second = 0;
//   rtc->minute = 0;
//   rtc->hour   = 0;
//   rtc->day    = 0;
//   rtc->month  = 0;
//   rtc->year   = 1900;
// }
