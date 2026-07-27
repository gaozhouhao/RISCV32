
.section .fsbl_entry, "ax"
.globl _fsbl_start
.type _fsbl_start, @function

_fsbl_start:
    mv s0, zero
    la sp, _boot_stack_pointer
    call fs_bootloader


.section .ssbl_entry, "ax"
.globl _ssbl_start
.type _ssbl_start, @function

_ssbl_start:
    mv s0, zero
    la sp, _boot_stack_pointer
    call ss_bootloader




.section entry, "ax"
.globl _start
.type _start, @function

_start:
    mv s0, zero
    la sp, _stack_pointer
    call _trm_init

.size _start, . - _start

