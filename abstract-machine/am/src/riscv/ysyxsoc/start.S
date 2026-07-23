
.section .boot.entry, "ax"
.globl _boot_start
.type _boot_start, @function

_boot_start:
    mv s0, zero
    la sp, _boot_stack_pointer
    call bootloader


.section entry, "ax"
.globl _start
.type _start, @function

_start:
    mv s0, zero
    la sp, _stack_pointer
    call _trm_init

.size _start, . - _start

