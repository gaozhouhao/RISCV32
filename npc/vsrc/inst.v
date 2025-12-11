
module inst(
    input       [7:0]   q,
    input       [7:0]   rdata1,
    input       [7:0]   rdata2,
    output  reg         wen,
    output  reg [1:0]   raddr1,
    output  reg [1:0]   raddr2,
    output  reg [1:0]   waddr,
    output  reg [7:0]   wdata,
    output  reg         jump_flag,
    output  reg [3:0]   next_pc,
    output  reg [7:0]   seg0,
    output  reg [7:0]   seg1
);

parameter add = 2'b00;
parameter li = 2'b10;
parameter bner0 = 2'b11;
parameter out = 2'b01;

wire    [1:0]   opcode;
wire    [1:0]   rd;
wire    [1:0]   rs1;
wire    [1:0]   rs2;
wire    [3:0]   addr;
wire    [3:0]   imm;

assign opcode = q[7:6];
assign rd = q[5:4];
assign rs1 = q[3:2];
assign rs2 = q[1:0];
assign addr = q[5:2];
assign imm = q[3:0];
wire [7:0] segs [7:0];


assign segs[0] = 8'b11111101;
assign segs[1] = 8'b01100000;
assign segs[2] = 8'b11011010;
assign segs[3] = 8'b11110010;
assign segs[4] = 8'b01100110;
assign segs[5] = 8'b10110110;
assign segs[6] = 8'b10111110;
assign segs[7] = 8'b11100000;

always @(*) begin
    wdata = 8'b0;
    waddr = 2'b0;
    raddr1 = 2'b0;
    raddr2 = 2'b0;
    wen = 0;
    next_pc = 0;
    seg0 = ~segs[0];
    seg1 = ~segs[0];
    case(opcode)
        add:begin
            wen = 1;
            jump_flag = 0;
            raddr1 = rs1;
            raddr2 = rs2;
            waddr = rd;
            wdata = rdata1 + rdata2;
            //$display("rs1:%d,rs2:%d, rd:%d,rdata1:%d, rdata2:%d, wdata:%d", rs1, rs2, rd, rdata1, rdata2, wdata);
        end
        li:begin
            jump_flag = 0;
            wen = 1;
            waddr = rd;
            wdata = {4'b0,imm};
        end
        bner0:begin
            wen = 0;
            raddr1 = 2'b0;
            raddr2 = rs2;
            if(rdata1 != rdata2) begin
                jump_flag = 1;    
                next_pc = addr;
            end         
            else
               jump_flag = 0;
        end
        out:begin
            wen = 0;
            jump_flag = 1;
            raddr2 = rs2;
            next_pc = addr;
            seg0 = ~segs[rdata2%10];
            seg1 = ~segs[rdata2/10];
            $display("rdata:%d,seg0:%d,seg1:%d", rdata2, seg0, seg1);
        end
        default:
            jump_flag = 0;
    endcase
end
endmodule











