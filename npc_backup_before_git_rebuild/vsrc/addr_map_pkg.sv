/* verilator lint_off UNUSED */
package addr_map_pkg;

    localparam  logic   [31:0]  UART_BASE   = 32'ha000_0300;
    localparam  logic   [31:0]  UART_END    = 32'ha000_0FFF;

    localparam  logic   [31:0]  SRAM_BASE   = 32'h8000_0000;
    localparam  logic   [31:0]  SRAM_END    = 32'h80ff_ffff;
    
    localparam  logic   [31:0]  CLINT_BASE  = 32'ha000_0000;
    localparam  logic   [31:0]  CLINT_END   = 32'ha000_02ff;

endpackage
/* verilator lint_on UNUSED */
