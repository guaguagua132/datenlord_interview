`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/04/26 21:36:37
// Design Name: 
// Module Name: tb_axi_stream_insert_header
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_axi_stream_insert_header(
    );
parameter DATA_WD       = 32                    ;
parameter DATA_BYTE_WD  = DATA_WD / 8           ;
parameter BYTE_CNT_WD   = $clog2(DATA_BYTE_WD)  ;
parameter BIT_CNT_WD    = $clog2(DATA_WD)       ;
parameter TOTAL_NUM     = 512                   ;
parameter TOTAL_NUM_WD  = $clog2(TOTAL_NUM)     ;

reg                 clk         ;
reg                 rst_n       ;
// AXI Stream input original data
reg                             valid_in        ;
reg [DATA_WD-1 : 0]             data_in         ;
reg [DATA_BYTE_WD-1 : 0]        keep_in         ;
reg                             last_in         ;
wire                            ready_in        ;
// AXI Stream output with header inserted
wire                            valid_out       ;   
wire [DATA_WD-1 : 0]            data_out        ; 
wire [DATA_BYTE_WD-1 : 0]       keep_out        ; 
wire                            last_out        ; 
reg                             ready_out       ;       // from next module
// The header to be inserted to AXI Stream input
reg                             valid_insert    ;
reg     [DATA_WD-1 : 0]         data_insert     ;
reg     [DATA_BYTE_WD-1 : 0]    keep_insert     ;
reg     [BYTE_CNT_WD : 0]       byte_insert_cnt ;
wire                            ready_insert    ;
// for simulation
wire                            handshake       ;
reg     [TOTAL_NUM_WD : 0]      data_in_cnt     ;


function integer clog2;
    input integer n; 
    begin
    n = n - 1;
    for (clog2 = 0; n > 0; clog2 = clog2 + 1)
        n = n >> 1;
    end
endfunction    

function [DATA_BYTE_WD-1 : 0] generate_keep_insert;
    input   [BIT_CNT_WD-1 : 0]  num;
    integer i;
    begin
    generate_keep_insert = 0;
        for (i = 0; i < num; i = i + 1)  begin
            generate_keep_insert = generate_keep_insert << 1;
            generate_keep_insert[0] = 1;
        end
    end
endfunction

function [DATA_BYTE_WD-1 : 0] generate_keep_last_in;
    input   [BIT_CNT_WD-1 : 0]  num;
    integer i;
    begin
    generate_keep_last_in = 0;
        for (i = 0; i < num; i = i + 1)  begin
            generate_keep_last_in = generate_keep_last_in >> 1;
            generate_keep_last_in[DATA_BYTE_WD-1] = 1;
        end
    end
endfunction

   
initial begin
    clk = 0;
    rst_n = 0;
    data_in_cnt = 0;
    valid_in = 0;
    data_in  = $random % 2147483647;
    keep_in  = 4'b1111;
    last_in  = 0;
    
    ready_out = 0;
    
    valid_insert    = 0;
    data_insert     = 0;
    keep_insert     = 0;
    byte_insert_cnt = 0;
    
    #100
    rst_n = 1;
    
    #25
    ready_out = 1;
    valid_in  = 1;
    
    #20
    valid_insert    = 1;
    data_insert     = 32'hffffffff;
    byte_insert_cnt = {$random}%(DATA_BYTE_WD) + 1;
    keep_insert     = generate_keep_insert(byte_insert_cnt);
    
//    #300
//    ready_out = 0;
//    #100
//    ready_out = 1;
end

always #10 clk = ~clk;

assign handshake = valid_insert & valid_in & ready_in & ready_insert;

always @(posedge clk)  begin
    if(handshake)    begin
        if(data_in_cnt < TOTAL_NUM-1)  begin  
            data_in <= $random % 2147483647;
            keep_in <= 4'b1111;
            last_in <= 0;
            data_in_cnt <= data_in_cnt + 1;
        end
        else if(data_in_cnt == TOTAL_NUM-1) begin
            data_in <= $random % 2147483647;
            keep_in <= generate_keep_last_in({$random}%(DATA_BYTE_WD) + 1);
            keep_in <= generate_keep_last_in({$random}%(DATA_BYTE_WD) + 1);
            last_in <= 1;
            data_in_cnt <= data_in_cnt + 1;
        end
        else    begin
            data_in <= $random % 2147483647;
            keep_in <= 4'b1111;
            byte_insert_cnt = {$random}%(DATA_BYTE_WD) + 1;
            keep_insert <= generate_keep_insert(byte_insert_cnt);
            last_in <= 0;
            data_in_cnt <= 0;
        end
    end
    else    begin
        data_in <= data_in;
        keep_in <= keep_in;
        data_in_cnt <= data_in_cnt;
        byte_insert_cnt <= byte_insert_cnt ;
        keep_insert     <= keep_insert     ;
    end
end

always @(posedge clk)  begin
    if(last_in)
        last_in <= 0;
    else
        last_in <= last_in;
end


axi_stream_insert_header #(
    .DATA_WD        (DATA_WD     )    ,
    .DATA_BYTE_WD   (DATA_BYTE_WD)    ,
    .BYTE_CNT_WD    (BYTE_CNT_WD )    ,
    .BIT_CNT_WD     (BIT_CNT_WD  )
) axi_stream_insert_header_u (
    .clk  (clk  )    ,
    .rst_n(rst_n)    ,
    
    .valid_in(valid_in) ,
    .data_in (data_in ) ,
    .keep_in (keep_in ) ,
    .last_in (last_in ) ,
    .ready_in(ready_in) ,
    
    .valid_out(valid_out)   ,
    .data_out (data_out )   ,
    .keep_out (keep_out )   ,
    .last_out (last_out )   ,
    .ready_out(ready_out)   ,
    
    .valid_insert   (valid_insert   )   ,
    .data_insert    (data_insert    )   ,
    .keep_insert    (keep_insert    )   ,
    .byte_insert_cnt(byte_insert_cnt)   ,
    .ready_insert   (ready_insert   )   
);


  
endmodule
