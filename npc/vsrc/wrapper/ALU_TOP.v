module mydesign (
    input         clk,

    input  [31:0] in_alu_src1,
    input  [31:0] in_alu_src2,
    input  [1:0]  in_alu_src1_sel,
    input  [1:0]  in_alu_src2_sel,
    input  [3:0]  in_ALUop,
    input  [31:0] in_src1_data,
    input  [31:0] in_src2_data,

    output [31:0] out_alu_result,
    output [3:0]  out_alu_flags
);

    reg [31:0] alu_src1;
    reg [31:0] alu_src2;
    reg [1:0]  alu_src1_sel;
    reg [1:0]  alu_src2_sel;
    reg [3:0]  ALUop;
    reg [31:0] src1_data;
    reg [31:0] src2_data;

    wire [31:0] alu_result;
    wire [3:0]  alu_flags;

    reg [31:0] alu_result_reg;
    reg [3:0]  alu_flags_reg;

    always @(posedge clk) begin
        alu_src1     <= in_alu_src1;
        alu_src2     <= in_alu_src2;
        alu_src1_sel <= in_alu_src1_sel;
        alu_src2_sel <= in_alu_src2_sel;
        ALUop        <= in_ALUop;
        src1_data    <= in_src1_data;
        src2_data    <= in_src2_data;

        alu_result_reg <= alu_result;
        alu_flags_reg  <= alu_flags;
    end

    ALU alu (
        .alu_src1     (alu_src1),
        .alu_src2     (alu_src2),
        .alu_src1_sel (alu_src1_sel),
        .alu_src2_sel (alu_src2_sel),
        .ALUop        (ALUop),
        .src1_data    (src1_data),
        .src2_data    (src2_data),
        .alu_result   (alu_result),
        .alu_flags    (alu_flags)
    );

    assign out_alu_result = alu_result_reg;
    assign out_alu_flags  = alu_flags_reg;

endmodule