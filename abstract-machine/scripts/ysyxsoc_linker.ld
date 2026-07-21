ENTRY(_boot_start)
/*PHDRS { text PT_LOAD; data PT_LOAD; }*/

MEMORY {
  psram : ORIGIN = 0x80000000, LENGTH = 4M
  flash : ORIGIN = 0x30000000, LENGTH = 16M
  mrom : ORIGIN = 0x20000000, LENGTH = 4K
  sram : ORIGIN = 0x0f000000, LENGTH = 8K
}

SECTIONS {
    .boot.text : {
        KEEP(*(.boot.entry))
        KEEP(*(.boot.text))
        KEEP(*(.boot.text.*))
        _boot_text_end = .;
    } > flash
    _boot_text_lma = LOADADDR(.boot.text);

    .text : {
        _text_start = .;
        KEEP(*(entry))
        *(.text*)
        _text_end = .;
    } > sram AT> flash
    _text_lma = LOADADDR(.text);

    .rodata : {
        _rodata_start = .;
        *(.rodata*)
        _rodata_end = .;
    } > sram AT> flash
    _rodata_lma = LOADADDR(.rodata);

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

    _psram_start = ORIGIN(psram);
    _psram_end = ORIGIN(psram) + LENGTH(psram);
    
    _stack_top = 0x0f002000;
    _boot_stack_pointer = _stack_top;
    _stack_pointer = _stack_top;
    end = _bss_end;
    _end = _bss_end;
    _heap_start = _end;
/*ASSERT(_bss_end <= _stack_top, "data/bss overlaps stack")*/
}
