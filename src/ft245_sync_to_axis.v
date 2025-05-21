//******************************************************************************
// file:    ft245_sync_to_axis.v
//
// author:  JAY CONVERTINO
//
// date:    2022/08/09
//
// about:   Brief
// Converter FT245 sync FIFO interface to AXIS. Work in progress.
//
// license: License MIT
// Copyright 2022 Jay Convertino
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.
//
//******************************************************************************

`timescale 1ns/100ps

/*
 * Module: ft245_sync_to_axis
 *
 * Converter FT245 sync FIFO interface to AXIS.
 *
 * Parameters:
 *
 *   BUS_WIDTH     - Width of the FT245 and AXIS bus.
 *
 * Ports:
 *
 *   rstn           - Negative reset
 *   ft245_dclk     - Input clock from FIFO.
 *   ft245_ben      - Byte enable used in FT60x, similar to AXIS tkeep in 1 is a valid byte for each bit.
 *   ft245_data     - FIFO data bus
 *   ft245_rdn      - Enable read on active low
 *   ft245_wrn      - Enable write on active low
 *   ft245_siwun    - Send Immediate / Wakeup for USB suspend. Active low.
 *   ft245_txen     - When low, write data to the fifo.
 *   ft245_rxfn     - When low, read data from the fifo.
 *   ft245_oen      - Output enable active low
 *   ft245_rstn     - Negative Reset
 *   ft245_wakeupn  - Sleep ft245 active low
 *   s_axis_tdata   - Input axis data
 *   s_axis_tkeep   - Input axis data bytes that are valid. Each bit equals one byte.
 *   s_axis_tvalid  - Input axis data is valid when active high.
 *   s_axis_tready  - Input data bus is ready when signal is active high.
 *   m_axis_tdata   - Output axis data
 *   m_axis_tkeep   - Output what axis data bytes are valid. Each bit equals one byte.
 *   m_axis_tvalid  - Output is active high when axis data is valid.
 *   m_axis_tready  - Output data bus is told that the receive device is ready. The device is ready if it asserts this signal active high.
 */
module ft245_sync_to_axis #(
    parameter BUS_WIDTH = 1
  ) 
  (
    input                       rstn,
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
    input   [(BUS_WIDTH*8)-1:0] s_axis_tdata,
    input   [BUS_WIDTH-1:0]     s_axis_tkeep,
    input                       s_axis_tvalid,
    output                      s_axis_tready,
    output  [(BUS_WIDTH*8)-1:0] m_axis_tdata,
    output  [BUS_WIDTH-1:0]     m_axis_tkeep,
    output                      m_axis_tvalid,
    input                       m_axis_tready
  );
  
  // Group: Data Store Registers
  // Register data based upon ft245 clocks.

  // var: r_oen
  // output enable registers
  reg r_oen;
  // var: rr_oen
  // output enable registers registers
  reg rr_oen;
  // var: rrr_oen
  // output enable registers registers registers
  reg rrr_oen;
  
  // var: r_m_axis_tdata
  // master axis register to hold tdata for tready not ready at end condition
  reg  [(BUS_WIDTH*8)-1:0] r_m_axis_tdata;
  // var: r_m_axis_tkeep
  // master axis register to hold tkeep for tready not ready at end condition
  reg  [BUS_WIDTH-1:0]     r_m_axis_tkeep;
  // var: r_m_axis_tvalid
  // master axis register to hold tvalid for tready not ready at end condition
  reg                      r_m_axis_tvalid;
  
  // Group: Assignments
  // How various comibinations of logic are created and data dealt with.

  // procedure: ft245_data
  // combinartoral signals to convert registers and axis to and from ft245.
  // tristate ft245 based on output enable state
  assign ft245_data = (rr_oen & r_oen ? s_axis_tdata : 'bz);
  // procedure: ft245_ben
  // tristate ft245 based on output enable state
  assign ft245_ben  = (rr_oen & r_oen ? s_axis_tkeep : 'bz);
  // procedure: ft245_wrn
  // only allow write if there is space, nothing availbe to read, valid data
  // available, and output enable is timed correctly.
  assign ft245_wrn  = ft245_txen | ~ft245_rxfn | ~s_axis_tvalid | ~rr_oen;
  // procedure: ft245_oen
  // output enable
  assign ft245_oen  = rr_oen;
  // procedure: ft245_rdn
  // only ready when output enable is correctly timed and we are ready for data
  // ft245 will output data as soon as oen is applied (FWFT).
  assign ft245_rdn  = ~m_axis_tready | rrr_oen | rr_oen & r_oen;
  // procedure: ft245_wakeupn
  // always keep it awake
  assign ft245_wakeupn = 1'b0;
  // procedure: ft245_siwun
  // always keep it awake
  assign ft245_siwun   = 1'b0;
  // procedure: ft245_rstn
  // apply system reset to ft245
  assign ft245_rstn = rstn;
  
  // procedure: s_axis_tready
  // convert ft245 to ready. only ready when write buffer is available, nothing
  // is incoming, and output enable is set correctly.
  assign s_axis_tready = (~ft245_txen & ft245_rxfn) & rr_oen;
  
  // procedure: m_axis_tdata
  // output ft245 to master axis. at end, output registers incase next core
  // was not ready.
  assign m_axis_tdata  = (rr_oen | r_oen ? r_m_axis_tdata  : ft245_data);
  // procedure: m_axis_tkeep
  // output ft245 to master axis. at end, output registers incase next core
  // was not ready.
  assign m_axis_tkeep  = (rr_oen | r_oen ? r_m_axis_tkeep  : ft245_ben);
  // procedure: m_axis_tvalid
  // data is only valid in the correct output enable register state and is no longer
  // valid if rxfn indicates the receive exhausted.
  assign m_axis_tvalid = (rr_oen | r_oen ? r_m_axis_tvalid : ~(rrr_oen | ft245_rxfn));
  
  //register signals
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
