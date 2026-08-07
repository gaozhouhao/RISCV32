ENTRY(_fsbl_start)
/*PHDRS { text PT_LOAD; data PT_LOAD; }*/

MEMORY {
  psram : ORIGIN = 0x80000000, LENGTH = 4M
  flash : ORIGIN = 0x30000000, LENGTH = 16M
  mrom : ORIGIN = 0x20000000, LENGTH = 4K
  sram : ORIGIN = 0x0f000000, LENGTH = 8K
  sdram : ORIGIN = 0xa0000000, LENGTH = 128M
  run_addr : ORIGIN = 0xa0000000, LENGTH = 128M
}


SECTIONS {
    .fsbl_text : {
        *(.fsbl_entry)
        *(.fsbl_text)
        *(.fsbl_text.*)
        _fsbl_text_end = .;
    } > flash
    _fsbl_text_lma = LOADADDR(.fsbl_text);

    .ssbl_text : {
        _ssbl_text_start = .;
        *(.ssbl_entry)
        *(.ssbl_text)
        *(.ssbl_text.*)
        _ssbl_text_end = .;
    } > sram AT > flash
    _ssbl_text_lma = LOADADDR(.ssbl_text);

    .text : {
        _text_start = .;
        *(entry)
        *(.text*)
        _text_end = .;
    } > run_addr AT> flash
    _text_lma = LOADADDR(.text);

    .rodata : {
        _rodata_start = .;
        *(.rodata*)
        _rodata_end = .;
    } > run_addr AT> flash
    _rodata_lma = LOADADDR(.rodata);

    .data : {
        _data_start = .;
        *(.data*)
        *(.sdata*)
        _data_end = .;
    } > run_addr AT> flash
    _data_lma = LOADADDR(.data);


    .data.extra : {
        _data_extra_start = .;
        /* section information for finsh shell */
        __fsymtab_start = .;
        KEEP(*(FSymTab))
        __fsymtab_end = .;
        . = ALIGN(8);
        __vsymtab_start = .;
        KEEP(*(VSymTab))
        __vsymtab_end = .;
        . = ALIGN(8);

        /* section information for initial. */
        . = ALIGN(8);
        __rt_init_start = .;
        KEEP(*(SORT(.rti_fn*)))
        __rt_init_end = .;
        . = ALIGN(8);

        __rt_utest_tc_tab_start = .;
        KEEP(*(UtestTcTab))
        __rt_utest_tc_tab_end = .;

        . = ALIGN(8);
        __am_apps_data_start = .;
        *(__am_apps.data*)
        *(__am_apps.sdata*)
        __am_apps_data_end = .;
        . = ALIGN(8);
        _data_extra_end = .;
    } > run_addr AT > flash
    _data_extra_lma = LOADADDR(.data.extra);


    .bss : {
        _bss_start = .;
        *(.bss*)
        *(.sbss*)
        *(.scommon)
        _bss_end = .;
    } > run_addr

    .bss.extra : {
        _bss_extra_start = .;
        . = ALIGN(8);
        __am_apps_bss_start = .;
        *(__am_apps.bss*)
        *(__am_apps.sbss*)
        *(__am_apps.scommon*)
        __am_apps_bss_end = .;
        . = ALIGN(8);
        _bss_extra_end = .;
    } > run_addr


    _run_start = ORIGIN(run_addr);
    _run_end = ORIGIN(run_addr) + LENGTH(run_addr);
    
    _stack_top = 0x0f002000;
    _boot_stack_pointer = _stack_top;
    _stack_pointer = _stack_top;
    end = _bss_end;
    _end = _bss_end;
    _heap_start = _end;
}


