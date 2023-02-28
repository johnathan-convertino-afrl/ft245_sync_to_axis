//******************************************************************************
/// @file    tb_axis.v
/// @author  JAY CONVERTINO
/// @date    2022.09.12
/// @brief   Test ft245 core
///
/// @LICENSE MIT
///  Copyright 2022 Jay Convertino
///
///  Permission is hereby granted, free of charge, to any person obtaining a copy
///  of this software and associated documentation files (the "Software"), to 
///  deal in the Software without restriction, including without limitation the
///  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or 
///  sell copies of the Software, and to permit persons to whom the Software is 
///  furnished to do so, subject to the following conditions:
///
///  The above copyright notice and this permission notice shall be included in 
///  all copies or substantial portions of the Software.
///
///  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
///  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
///  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
///  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
///  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
///  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
///  IN THE SOFTWARE.
//******************************************************************************

`timescale 1 ns/10 ps

module tb_axis;
  
  reg         tb_data_clk = 0;
  reg         tb_rst = 0;
  //   wire        tb_rx;
  wire [7:0]  tb_m_tdata;
  wire [0:0]  tb_m_tkeep;
  wire        tb_m_tvalid;
  wire        tb_m_tready;
  //   wire        tb_tx;
  wire [7:0]  tb_s_tdata;
  wire [0:0]  tb_s_tkeep;
  wire        tb_s_tvalid;
  wire        tb_s_tready;
  
  reg tb_txen = 0;
  reg tb_rxfn = 0;
  
  reg [0:0] tb_r_ben = 1;
  reg [7:0] tb_r_data = 'h55;
  
  wire [0:0] tb_ben;
  wire [7:0] tb_data;
  
  wire [0:0] ben;
  wire [7:0] data;
  
  wire tb_rdn;
  wire tb_wrn;
  wire tb_siwun;
  wire tb_oen;
  wire tb_rstn;
  wire tb_wakeupn;
  
  assign tb_ben     = (tb_oen == 1 ? ben  : 'bz);
  assign tb_data    = (tb_oen == 1 ? data : 'bz);
  
  assign ben    = (tb_oen == 0 ? tb_r_ben : 'bz);
  assign data   = (tb_oen == 0 ? tb_r_data : 'bz);
  
  //1ns
  localparam CLK_PERIOD = 20;
  localparam RST_PERIOD = 500;
  
  //device under test
  ft245_sync_to_axis #(
    .BUS_WIDTH(1)
  ) dut (
    //reset
    .rstn(~tb_rst),
    .ft245_dclk(tb_data_clk),
    .ft245_ben(ben),
    .ft245_data(data),
    .ft245_rdn(tb_rdn),
    .ft245_wrn(tb_wrn),
    .ft245_siwun(tb_siwun),
    .ft245_txen(tb_txen),
    .ft245_rxfn(tb_rxfn),
    .ft245_oen(tb_oen),
    .ft245_rstn(tb_rstn),
    .ft245_wakeupn(tb_wakeupn),
    //master output
    .m_axis_tdata(tb_m_tdata),
    .m_axis_tkeep(tb_m_tkeep),
    .m_axis_tvalid(tb_m_tvalid),
    .m_axis_tready(tb_m_tready),
    //slave input
    .s_axis_tdata(tb_s_tdata),
    .s_axis_tkeep(tb_s_tkeep),
    .s_axis_tvalid(tb_s_tvalid),
    .s_axis_tready(tb_s_tready)
  );
  
  //reset
  initial
  begin
    tb_rst <= 1'b1;
    
    #RST_PERIOD;
    
    tb_rst <= 1'b0;
  end
  
  //transmit data
  initial
  begin
    tb_txen <= 1'b1;
    
    #560
    
    tb_txen <= 1'b0;
    
    #5000
  
    tb_txen <= 1'b1;
  end
  
   //recv data
  initial
  begin
    tb_rxfn <= 1'b1;
    
    #2500
    
    tb_rxfn <= 1'b0;
    
    #500
  
    tb_rxfn <= 1'b1;
    
    #600
    
    tb_rxfn <= 1'b0;
    
    #1960
    
    tb_rxfn <= 1'b1;
    
    #40
    
    tb_rxfn <= 1'b0;
    
    #820
    
    tb_rxfn <= 1'b1;
  end
  
  //copy pasta, fst generation
  initial
  begin
    $dumpfile("tb_axis.fst");
    $dumpvars(0,tb_axis);
  end
  
  //axis clock
  always
  begin
    tb_data_clk <= ~tb_data_clk;
    
    #(CLK_PERIOD/2);
  end
  
  //produce data for ft245 recv
  always @(posedge tb_data_clk)
  begin
    if (tb_rst == 1'b1) begin
      tb_r_ben   <= 1'b0;
      tb_r_data  <= 8'd65;
    end else begin
      tb_r_ben <= 1'b1;
      
      tb_r_data <= tb_r_data;
      
      if(~tb_rxfn && ~tb_oen && ~tb_rdn)
        tb_r_data <= tb_r_data + 1;
    end
  end
  
  master_axis_stimulus #(
    .BUS_WIDTH(1),
    .USER_WIDTH(1),
    .DEST_WIDTH(1),
    .FILE("out.bin")
  ) master_axis_stim (
    // write
    .s_axis_aclk(tb_data_clk),
    .s_axis_arstn(~tb_rst),
    .s_axis_tvalid(tb_m_tvalid),
    .s_axis_tready(tb_m_tready),
    .s_axis_tdata(tb_m_tdata),
    .s_axis_tkeep(tb_m_tkeep),
    .s_axis_tlast(1'b0),
    .s_axis_tuser(1'b0),
    .s_axis_tdest(1'b0)
  );
  
  slave_axis_stimulus #(
    .BUS_WIDTH(1),
    .USER_WIDTH(1),
    .DEST_WIDTH(1),
    .FILE("const.bin")
  ) slave_axis_stim (
    // output to slave
    .m_axis_aclk(tb_data_clk),
    .m_axis_arstn(~tb_rst),
    .m_axis_tvalid(tb_s_tvalid),
    .m_axis_tready(tb_s_tready),
    .m_axis_tdata(tb_s_tdata),
    .m_axis_tkeep(tb_s_tkeep),
    .m_axis_tlast(),
    .m_axis_tuser(),
    .m_axis_tdest()
  );
  
  //copy pasta, no way to set runtime... this works in vivado as well.
  initial begin
    #1_000_000; // Wait a long time in simulation units (adjust as needed).
    $display("END SIMULATION");
    $finish;
  end
endmodule
