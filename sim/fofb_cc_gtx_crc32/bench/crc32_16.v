//////////////////////////////////////////////////////////////////////////////
//
// crc calculation
// This VERILOG code was generated using CRCGEN.PL version 1.7
// Last Modified: 01/02/2002
// Options Used:
//    Module Name = crc32
//      CRC Width = 32
//     Data Width = 16
//     CRC Init   = F
//     Polynomial = [0 -> 32]
//        1 1 1 0 1 1 0 1 1 0 1 1 1 0 0 0 1 0 0 0 0 0 1 1 0 0 1 0 0 0 0 0 1
//
// Disclaimer: THESE DESIGNS ARE PROVIDED "AS IS" WITH NO WARRANTY 
//             WHATSOEVER AND XILINX SPECIFICALLY DISCLAIMS ANY 
//             IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR
//             A PARTICULAR PURPOSE, OR AGAINST INFRINGEMENT.
//
// Copyright (c) 2001,2002 Xilinx, Inc.  All rights reserved.
//
//
//////////////////////////////////////////////////////////////////////////////

module crc32 (
   crc_reg, 
   crc,
   d,
   calc,
   init,
   d_valid,
   clk,
   reset
   );

output [31:0] crc_reg;
output [15:0]  crc;

input  [15:0]  d;
input         calc;
input         init;
input         d_valid;
input         clk;
input         reset;

reg    [31:0] crc_reg;
reg    [15:0]  crc;

//////////////////////////////////////////////////////////////////////////////
// Internal Signals
//////////////////////////////////////////////////////////////////////////////
wire   [31:0] next_crc;

//////////////////////////////////////////////////////////////////////////////
// Infer CRC-32 registers
// 
// The crc_reg register stores the CRC-32 value.
// The crc register is the most significant 16 bits of the 
// CRC-32 value.
//
// Truth Table:
// -----+---------+----------+----------------------------------------------
// calc | d_valid | crc_reg  | crc 
// -----+---------+----------+----------------------------------------------
//  0   |     0   | crc_reg  | crc 
//  0   |     1   |  shift   | bit-swapped, complimented msbyte of crc_reg
//  1   |     0   | crc_reg  | crc 
//  1   |     1   | next_crc | bit-swapped, complimented msbyte of next_crc
// -----+---------+----------+----------------------------------------------
// 
//////////////////////////////////////////////////////////////////////////////
 
always @ (posedge clk or posedge reset)
begin
   if (reset) begin
      crc_reg <= 32'hFFFFFFFF;
      crc     <= 16'hFFFF;
   end
   
   else if (init) begin
      crc_reg <= 32'hFFFFFFFF;
      crc     <=  16'hFFFF;
   end

   else if (calc & d_valid) begin
      crc_reg <= next_crc;
      crc     <= ~{next_crc[16], next_crc[17], next_crc[18], next_crc[19],
                   next_crc[20], next_crc[21], next_crc[22], next_crc[23],
                   next_crc[24], next_crc[25], next_crc[26], next_crc[27],
                   next_crc[28], next_crc[29], next_crc[30], next_crc[31]};
   end
   
   else if (~calc & d_valid) begin
      crc_reg <=  {crc_reg[15:0], 16'hFFFF};
      crc     <= ~{crc_reg[0], crc_reg[1], crc_reg[2], crc_reg[3],
                   crc_reg[4], crc_reg[5], crc_reg[6], crc_reg[7],
                   crc_reg[8], crc_reg[9], crc_reg[10], crc_reg[11],
                   crc_reg[12], crc_reg[13], crc_reg[14], crc_reg[15]};
   end
end

//////////////////////////////////////////////////////////////////////////////
// CRC XOR equations
//////////////////////////////////////////////////////////////////////////////

assign next_crc[0] = crc_reg[22] ^ crc_reg[25] ^ d[5] ^ d[3] ^ d[6] ^ crc_reg[16] ^ crc_reg[28] ^ d[15] ^ d[9] ^ crc_reg[26];
assign next_crc[1] = crc_reg[22] ^ crc_reg[17] ^ d[3] ^ crc_reg[27] ^ d[15] ^ d[4] ^ crc_reg[25] ^ d[8] ^ crc_reg[23] ^ d[2] ^ crc_reg[29] ^ d[6] ^ crc_reg[16] ^ crc_reg[28] ^ d[14] ^ d[9];
assign next_crc[2] = crc_reg[22] ^ crc_reg[17] ^ d[1] ^ crc_reg[30] ^ d[15] ^ crc_reg[24] ^ d[13] ^ d[7] ^ crc_reg[18] ^ crc_reg[25] ^ d[8] ^ d[2] ^ crc_reg[23] ^ d[6] ^ crc_reg[29] ^ crc_reg[16] ^ d[14] ^ d[9];
assign next_crc[3] = crc_reg[17] ^ d[1] ^ crc_reg[31] ^ crc_reg[30] ^ crc_reg[24] ^ crc_reg[19] ^ d[13] ^ d[7] ^ crc_reg[18] ^ crc_reg[25] ^ d[5] ^ d[12] ^ d[8] ^ crc_reg[23] ^ d[6] ^ d[14] ^ crc_reg[26] ^ d[0];
assign next_crc[4] = crc_reg[22] ^ crc_reg[31] ^ d[3] ^ crc_reg[27] ^ d[15] ^ crc_reg[24] ^ d[4] ^ crc_reg[19] ^ d[13] ^ d[7] ^ crc_reg[20] ^ crc_reg[18] ^ d[12] ^ d[11] ^ crc_reg[16] ^ crc_reg[28] ^ d[9] ^ d[0];
assign next_crc[5] = crc_reg[22] ^ crc_reg[17] ^ d[15] ^ crc_reg[19] ^ crc_reg[20] ^ crc_reg[21] ^ d[12] ^ d[5] ^ d[8] ^ d[10] ^ d[11] ^ crc_reg[23] ^ d[2] ^ crc_reg[29] ^ crc_reg[16] ^ d[14] ^ d[9] ^ crc_reg[26];
assign next_crc[6] = crc_reg[22] ^ crc_reg[17] ^ d[1] ^ crc_reg[27] ^ crc_reg[30] ^ crc_reg[24] ^ d[4] ^ d[13] ^ d[7] ^ crc_reg[20] ^ crc_reg[21] ^ crc_reg[18] ^ d[8] ^ d[10] ^ d[11] ^ crc_reg[23] ^ d[14] ^ d[9];
assign next_crc[7] = crc_reg[31] ^ d[15] ^ crc_reg[24] ^ crc_reg[19] ^ d[13] ^ d[7] ^ crc_reg[21] ^ crc_reg[18] ^ d[5] ^ d[12] ^ d[8] ^ d[10] ^ crc_reg[23] ^ crc_reg[16] ^ crc_reg[26] ^ d[0];
assign next_crc[8] = crc_reg[17] ^ d[3] ^ crc_reg[27] ^ d[15] ^ d[4] ^ crc_reg[24] ^ crc_reg[19] ^ crc_reg[20] ^ d[7] ^ d[12] ^ d[5] ^ d[11] ^ crc_reg[16] ^ crc_reg[28] ^ d[14] ^ crc_reg[26];
assign next_crc[9] = crc_reg[17] ^ d[3] ^ crc_reg[27] ^ d[4] ^ d[13] ^ crc_reg[20] ^ crc_reg[21] ^ crc_reg[18] ^ crc_reg[25] ^ d[10] ^ d[11] ^ d[2] ^ crc_reg[29] ^ d[6] ^ crc_reg[28] ^ d[14];
assign next_crc[10] = d[1] ^ crc_reg[30] ^ d[15] ^ crc_reg[19] ^ d[13] ^ crc_reg[21] ^ crc_reg[18] ^ crc_reg[25] ^ d[12] ^ d[10] ^ d[2] ^ crc_reg[29] ^ d[6] ^ crc_reg[16];
assign next_crc[11] = crc_reg[17] ^ d[1] ^ d[3] ^ crc_reg[31] ^ crc_reg[30] ^ d[15] ^ crc_reg[19] ^ crc_reg[20] ^ crc_reg[25] ^ d[12] ^ d[11] ^ d[6] ^ crc_reg[16] ^ crc_reg[28] ^ d[14] ^ d[0];
assign next_crc[12] = crc_reg[22] ^ crc_reg[17] ^ crc_reg[31] ^ d[3] ^ d[15] ^ d[13] ^ crc_reg[20] ^ crc_reg[21] ^ crc_reg[18] ^ crc_reg[25] ^ d[10] ^ d[11] ^ d[2] ^ d[6] ^ crc_reg[29] ^ crc_reg[16] ^ crc_reg[28] ^ d[14] ^ d[9] ^ d[0];
assign next_crc[13] = crc_reg[22] ^ crc_reg[17] ^ d[1] ^ crc_reg[30] ^ crc_reg[19] ^ d[13] ^ crc_reg[21] ^ crc_reg[18] ^ d[5] ^ d[12] ^ d[8] ^ d[10] ^ crc_reg[23] ^ d[2] ^ crc_reg[29] ^ d[14] ^ crc_reg[26] ^ d[9];
assign next_crc[14] = crc_reg[22] ^ d[1] ^ crc_reg[31] ^ crc_reg[27] ^ crc_reg[30] ^ crc_reg[24] ^ d[4] ^ crc_reg[19] ^ d[13] ^ d[7] ^ crc_reg[20] ^ crc_reg[18] ^ d[12] ^ d[8] ^ d[11] ^ crc_reg[23] ^ d[9] ^ d[0];
assign next_crc[15] = d[3] ^ crc_reg[31] ^ crc_reg[24] ^ crc_reg[19] ^ crc_reg[20] ^ d[7] ^ crc_reg[21] ^ crc_reg[25] ^ d[12] ^ d[8] ^ d[10] ^ d[11] ^ crc_reg[23] ^ d[6] ^ crc_reg[28] ^ d[0];
assign next_crc[16] = crc_reg[0] ^ d[3] ^ d[15] ^ crc_reg[24] ^ crc_reg[20] ^ d[7] ^ crc_reg[21] ^ d[10] ^ d[11] ^ d[2] ^ crc_reg[29] ^ crc_reg[16] ^ crc_reg[28];
assign next_crc[17] = crc_reg[22] ^ crc_reg[17] ^ d[1] ^ crc_reg[30] ^ crc_reg[21] ^ crc_reg[25] ^ d[10] ^ d[2] ^ d[6] ^ crc_reg[29] ^ crc_reg[1] ^ d[14] ^ d[9];
assign next_crc[18] = crc_reg[22] ^ d[1] ^ crc_reg[31] ^ crc_reg[30] ^ d[13] ^ crc_reg[18] ^ d[5] ^ d[8] ^ crc_reg[23] ^ d[9] ^ d[0] ^ crc_reg[26] ^ crc_reg[2];
assign next_crc[19] = crc_reg[31] ^ crc_reg[27] ^ crc_reg[24] ^ d[4] ^ crc_reg[19] ^ d[7] ^ d[12] ^ d[8] ^ crc_reg[23] ^ d[0] ^ crc_reg[3];
assign next_crc[20] = crc_reg[4] ^ d[3] ^ crc_reg[24] ^ crc_reg[20] ^ d[7] ^ crc_reg[25] ^ d[11] ^ d[6] ^ crc_reg[28];
assign next_crc[21] = crc_reg[5] ^ crc_reg[21] ^ crc_reg[25] ^ d[5] ^ d[10] ^ d[2] ^ d[6] ^ crc_reg[29] ^ crc_reg[26];
assign next_crc[22] = d[1] ^ d[3] ^ crc_reg[27] ^ crc_reg[30] ^ d[15] ^ d[4] ^ crc_reg[25] ^ d[6] ^ crc_reg[16] ^ crc_reg[28] ^ crc_reg[6];
assign next_crc[23] = crc_reg[22] ^ crc_reg[17] ^ crc_reg[31] ^ d[15] ^ crc_reg[7] ^ crc_reg[25] ^ d[2] ^ d[6] ^ crc_reg[29] ^ crc_reg[16] ^ d[14] ^ d[9] ^ d[0];
assign next_crc[24] = crc_reg[17] ^ d[1] ^ crc_reg[8] ^ crc_reg[30] ^ d[13] ^ crc_reg[18] ^ d[5] ^ d[8] ^ crc_reg[23] ^ d[14] ^ crc_reg[26];
assign next_crc[25] = crc_reg[9] ^ crc_reg[31] ^ crc_reg[27] ^ crc_reg[24] ^ d[4] ^ crc_reg[19] ^ d[13] ^ d[7] ^ crc_reg[18] ^ d[12] ^ d[0];
assign next_crc[26] = crc_reg[22] ^ crc_reg[10] ^ d[15] ^ crc_reg[19] ^ crc_reg[20] ^ d[12] ^ d[5] ^ d[11] ^ crc_reg[16] ^ d[9] ^ crc_reg[26];
assign next_crc[27] = crc_reg[17] ^ crc_reg[27] ^ d[4] ^ crc_reg[20] ^ crc_reg[21] ^ d[8] ^ d[10] ^ d[11] ^ crc_reg[11] ^ crc_reg[23] ^ d[14];
assign next_crc[28] = crc_reg[22] ^ d[3] ^ crc_reg[24] ^ d[13] ^ d[7] ^ crc_reg[21] ^ crc_reg[18] ^ d[10] ^ crc_reg[12] ^ crc_reg[28] ^ d[9];
assign next_crc[29] = crc_reg[22] ^ crc_reg[19] ^ crc_reg[25] ^ d[12] ^ d[8] ^ crc_reg[13] ^ crc_reg[23] ^ d[2] ^ d[6] ^ crc_reg[29] ^ d[9];
assign next_crc[30] = d[1] ^ crc_reg[30] ^ crc_reg[24] ^ crc_reg[20] ^ d[7] ^ crc_reg[14] ^ d[5] ^ d[8] ^ d[11] ^ crc_reg[23] ^ crc_reg[26];
assign next_crc[31] = crc_reg[31] ^ crc_reg[27] ^ d[4] ^ crc_reg[24] ^ d[7] ^ crc_reg[21] ^ crc_reg[25] ^ crc_reg[15] ^ d[10] ^ d[6] ^ d[0];
endmodule
