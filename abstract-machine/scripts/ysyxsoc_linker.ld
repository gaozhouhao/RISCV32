ENTRY(_start)
/*PHDRS { text PT_LOAD; data PT_LOAD; }*/

MEMORY {
  psram : ORIGIN = 0x80000000, LENGTH = 4M
  flash : ORIGIN = 0x30000000, LENGTH = 16M
  mrom : ORIGIN = 0x20000000, LENGTH = 4K
  sram : ORIGIN = 0x0f000000, LENGTH = 8K
}

SECTIONS {
    . = ORIGIN(flash);
    
    .text : {
        *(entry)
        *(.text*)
    } > flash AT> flash

    etext = .;
    _etext = .;

    .rodata : {
        *(.rodata*)
    } > flash AT> flash

    .data : {
        _data_start = .;
        *(.data*)
        *(.sdata*)
        _data_end = .;
    } > psram AT> flash
    _data_lma = LOADADDR(.data);

    .bss : {
        _bss_start = .;
        *(.bss*)
        *(.sbss*)
        *(.scommon)
        _bss_end = .;
    } > psram

    _stack_top = 0x0f001000;
    _stack_pointer = _stack_top;
    end = _bss_end;
    _end = _bss_end;
    _heap_start = 0x0f001000;
/*ASSERT(_bss_end <= _stack_top, "data/bss overlaps stack")*/
}
