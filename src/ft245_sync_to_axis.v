//******************************************************************************
/// @FILE    ft245_sync_to_axis.v
/// @AUTHOR  JAY CONVERTINO
/// @DATE    2022.08.09
/// @BRIEF   FT245 to AXIS
/// @DETAILS Converter FT245 sync FIFO interface to AXIS.
///
/// @LICENSE MIT
/// Copyright 2022 Jay Convertino
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to 
/// deal in the Software without restriction, including without limitation the
/// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or 
/// sell copies of the Software, and to permit persons to whom the Software is 
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in 
/// all copies or substantial portions of the Software.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
/// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
/// IN THE SOFTWARE.
//******************************************************************************

`timescale 1ns/100ps

// ft245 to axis
module ft245_sync_to_axis #(
    parameter BUS_WIDTH = 1
  ) 
  (
    // system
    input                       rstn,
    // ft245 interface
    input                       ft245_dclk,
    inout   [BUS_WIDTH-1:0]     ft245_ben,
    inout   [(BUS_WIDTH*8)-1:0] ft245_data,
    output                      ft245_rdn,
    output                      ft245_wrn,
    output                      ft245_siwun,
    input                       ft245_txen,
    input                       ft245_rxfn,
    output                      ft245_oen,
    output                      ft245_rstn,
    output                      ft245_wakeupn,
    // slave
    input   [(BUS_WIDTH*8)-1:0] s_axis_tdata,
    input   [BUS_WIDTH-1:0]     s_axis_tkeep,
    input                       s_axis_tvalid,
    output                      s_axis_tready,
    // master
    output  [(BUS_WIDTH*8)-1:0] m_axis_tdata,
    output  [BUS_WIDTH-1:0]     m_axis_tkeep,
    output                      m_axis_tvalid,
    input                       m_axis_tready
  );
  
  // output enable registers
  reg r_oen;
  reg rr_oen;
  reg rrr_oen;
  
  // master axis register to hold data for tready not ready at end condition
  reg  [(BUS_WIDTH*8)-1:0] r_m_axis_tdata;
  reg  [BUS_WIDTH-1:0]     r_m_axis_tkeep;
  reg                      r_m_axis_tvalid;
  
  // combinartoral signals to convert registers and axis to and from ft245.
  // tristate ft245 based on output enable state
  assign ft245_data = (rr_oen & r_oen ? s_axis_tdata : 'bz);
  // tristate ft245 based on output enable state
  assign ft245_ben  = (rr_oen & r_oen ? s_axis_tkeep : 'bz);
  // only allow write if there is space, nothing availbe to read, valid data
  // available, and output enable is timed correctly.
  assign ft245_wrn  = ft245_txen | ~ft245_rxfn | ~s_axis_tvalid | ~rr_oen;
  // output enable
  assign ft245_oen  = rr_oen;
  // only ready when output enable is correctly timed and we are ready for data
  // ft245 will output data as soon as oen is applied (FWFT).
  assign ft245_rdn  = ~m_axis_tready | rrr_oen | rr_oen & r_oen;
  // always keep it awake
  assign ft245_wakeupn = 1'b0;
  assign ft245_siwun   = 1'b0;
  // apply system reset to ft245
  assign ft245_rstn = rstn;
  
  // convert ft245 to ready. only ready when write buffer is available, nothing
  // is incoming, and output enable is set correctly.
  assign s_axis_tready = (~ft245_txen & ft245_rxfn) & rr_oen;
  
  // output ft245 to master axis. at end, output registers incase next core
  // was not ready.
  assign m_axis_tdata  = (rr_oen | r_oen ? r_m_axis_tdata  : ft245_data);
  assign m_axis_tkeep  = (rr_oen | r_oen ? r_m_axis_tkeep  : ft245_ben);
  // data is only valid in the correct output enable register state and is no longer
  // valid if rxfn indicates the receive exhausted.
  assign m_axis_tvalid = (rr_oen | r_oen ? r_m_axis_tvalid : ~(rrr_oen | ft245_rxfn));
  
  always @(posedge ft245_dclk) begin
    if(rstn == 1'b0) begin
      // regs
      r_oen   <= 1;
      rr_oen  <= 1;
      rrr_oen <= 1;
      // m axis
      r_m_axis_tdata  <= 0;
      r_m_axis_tkeep  <= 0;
      r_m_axis_tvalid <= 0;
    end else begin
      // register output enable negative to create combinatorial signals needed.
      r_oen   <= ft245_rxfn;
      rr_oen  <= r_oen;
      rrr_oen <= rr_oen;
      
      // only update when reading data, only remove read data if m_axis_tready
      // goes high.
      if((~rr_oen & ~r_oen) | m_axis_tready) begin
        r_m_axis_tdata  <= (m_axis_tready ? 'b0 : ft245_data);
        r_m_axis_tkeep  <= (m_axis_tready ? 'b0 : ft245_ben);
        r_m_axis_tvalid <= (m_axis_tready ? 'b0 : ~rrr_oen);
      end
    end
  end
endmodule
