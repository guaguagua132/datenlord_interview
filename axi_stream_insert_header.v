`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/04/26 17:06:37
// Design Name: 
// Module Name: axi_stream_insert_header
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


module axi_stream_insert_header #(
    parameter DATA_WD       = 32                    ,
    parameter DATA_BYTE_WD  = DATA_WD / 8           ,
    parameter BYTE_CNT_WD   = 2
) (
    input                       clk             ,
    input                       rst_n           ,
    // AXI Stream input original data
    input                       valid_in        ,
    input [DATA_WD-1 : 0]       data_in         ,
    input [DATA_BYTE_WD-1 : 0]  keep_in         ,
    input                       last_in         ,
    output                      ready_in        ,
    // AXI Stream output with header inserted
    output reg                       valid_out       ,
    output reg  [DATA_WD-1 : 0]      data_out        ,
    output reg  [DATA_BYTE_WD-1 : 0] keep_out        ,
    output                           last_out        ,
    input                            ready_out       ,
    // The header to be inserted to AXI Stream input
    input                         valid_insert    ,
    input   [DATA_WD-1 : 0]       data_insert     ,
    input   [DATA_BYTE_WD-1 : 0]  keep_insert     ,
    input   [BYTE_CNT_WD : 0]     byte_insert_cnt ,
    output                        ready_insert      
);

wire                        handshake           ;
wire                        handshake_in        ;
wire                        handshake_insert    ;

reg [DATA_WD-1 : 0]         shift_data          ;
reg [DATA_BYTE_WD-1 : 0]    shift_keep          ;
reg [DATA_BYTE_WD-1 : 0]    header_width        ;
reg                         header_insert_flag  ;
reg [DATA_BYTE_WD : 0]      keep_out_ext        ;
reg                         check_last          ;                      

assign ready_in = ready_out;
assign ready_insert = ready_out;
assign handshake_in = ready_out & valid_in;
assign handshake_insert = ready_out & valid_insert;
assign handshake = handshake_in & handshake_insert;

assign last_out = ~keep_out_ext[0];

always @(posedge clk)  begin
    if(~rst_n)  begin
        valid_out <= 0;
        data_out <= 0;
        keep_out <= 0;
//        last_out <= 0;
        header_insert_flag <= 0;
        keep_out_ext <= 1;
        check_last <= 0;
    end
    else    begin
        if(handshake)   begin
            valid_out <= 1;
            if(~header_insert_flag) begin
                header_insert_flag <= header_insert_flag + 1;
                data_out <= (data_insert << (DATA_BYTE_WD - byte_insert_cnt)*8) + 
                    (data_in >> byte_insert_cnt*8);
                shift_data <= data_in;
                keep_out <= (keep_insert << (DATA_BYTE_WD - byte_insert_cnt)) + 
                    (keep_in >> byte_insert_cnt);
                shift_keep <= keep_in;
            end
            else    begin
                if(~last_in)    begin
                    header_insert_flag <= header_insert_flag;
                    data_out <= (shift_data << (DATA_BYTE_WD - byte_insert_cnt)*8) + 
                        (data_in >> byte_insert_cnt*8);
                    shift_data <= data_in;
                    keep_out <= (shift_keep << (DATA_BYTE_WD - byte_insert_cnt)) + 
                        (keep_in >> byte_insert_cnt);
                    shift_keep <= keep_in;
                    keep_out_ext <= keep_out_ext;
                end
                else    begin
                    header_insert_flag <= header_insert_flag;
                    keep_out_ext <= keep_in >> (byte_insert_cnt-1);
                    check_last <= 1;
                    data_out <= (shift_data << (DATA_BYTE_WD - byte_insert_cnt)*8) + 
                        (data_in >> byte_insert_cnt*8);
                    shift_data <= data_in;
                    keep_out <= (shift_keep << (DATA_BYTE_WD - byte_insert_cnt)) + 
                        (keep_in >> byte_insert_cnt);
                    shift_keep <= keep_in;
                end
            end
        end
        else    begin
            if(check_last)  begin
                if(keep_out_ext[0]) begin
                    valid_out <= 1;
                    check_last <= 0;
                    data_out <= shift_data << (DATA_BYTE_WD - byte_insert_cnt)*8;
                    keep_out <= shift_keep << (DATA_BYTE_WD - byte_insert_cnt);
                    keep_out_ext <= 0;
                end
                else    begin
                    check_last <= 0;
                    valid_out <= 0;
                    keep_out_ext <= 1;
                end
            end
            else    begin
                valid_out <= 0;
                keep_out_ext <= 1;
            end
        end
    end
end

endmodule
