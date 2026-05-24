ENTRY(_start)
/*PHDRS { text PT_LOAD; data PT_LOAD; }*/

MEMORY {
  mrom : ORIGIN = 0x20000000, LENGTH = 4K
  sram : ORIGIN = 0x0f000000, LENGTH = 8K
}

SECTIONS {
    . = ORIGIN(mrom);
    
    .text : {
        *(entry)
        *(.text*)
    } > mrom AT> mrom

    etext = .;
    _etext = .;

    .rodata : {
        *(.rodata*)
    } > mrom AT> mrom

    _data_lma = .;
    .data : {
        _data_start = .;
        *(.data*)
        *(.sdata*)
        _data_end = .;
    } > sram AT> mrom
    
    .bss : {
        _bss_start = .;
        *(.bss*)
        *(.sbss*)
        *(.scommon)
        _bss_end = .;
    } > sram

    _stack_top = 0x0f001000;
    . = _stack_top;
    _stack_pointer = .;
    end = .;
    _end = .;
    _heap_start = 0x0f001000;
}
