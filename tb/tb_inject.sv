// Copyright 2024 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Description: Testbench for --force command in questa vsim

module tb_inject;

  localparam CyclTime = 10ns;
  localparam ApplTime = 2ns;
  localparam InjectTime = 10ns; // How many ns after START the fault injection should happen. 
  localparam TestTime = 8ns;

  localparam DutStates = 4;

  typedef logic [$clog2(DutStates)-1:0] test_t; 

  test_t signal_start, signal_inject, signal_intermediate, signal_final;

  enum logic [2:0] {IDLE, START, INJECT, INTERMEDIATE, UNINJECT, FINAL} position_d, position_q;

  logic clk, rst_n, done;


  always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
      position_q <= IDLE;
    end else begin
      position_q <= position_d;
    end
  end

  logic inject_clock;
  logic inject_d, inject_q; // Signal to trigger force command
  always_ff @(posedge inject_clock or negedge rst_n) begin
    if(~rst_n) begin
      inject_q <= 0;
    end else begin
      inject_q <= inject_d;
    end
  end

  // DUT Signal
  test_t signal_d, signal_q, signal_r; 

  // DUT FF
  always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
      signal_q <= '0;
      signal_r <= '0;
    end else begin
      signal_q <= signal_d;
      signal_r <= signal_q;
    end
  end

  initial begin : clk_gen
    done = 0;
    rst_n = 1'b1;
    while (!done) begin
      clk = 1'b1;
      #(CyclTime / 2);
      clk = 1'b0;
      #(CyclTime / 2);
    end
  end

  initial begin : inject_clk_gen
    # InjectTime;

    while (!done) begin
      inject_clock = 1'b1;
      #(CyclTime / 2);
      inject_clock = 1'b0;
      #(CyclTime / 2);
    end
  end

  initial begin : inject_toggle
    inject_d = 0;

    for (int i = 0; i < DutStates; i++) begin
      for (int j = 0; j < DutStates; j++) begin
        for (int k = 0; k < DutStates; k++) begin
          for (int l = 0; l < DutStates; l++) begin

            // Assign named signals so they can be seen in TB
            signal_inject = j;

            repeat (3) @(posedge inject_clock);
            #ApplTime;
            inject_d = 1;

            repeat (2) @(posedge inject_clock);
            #ApplTime;
            inject_d = 0;

            repeat (7) @(posedge inject_clock);

          end
        end
      end
    end
  end

  initial begin : main
    signal_d = 0;
    position_d = IDLE;

    for (int i = 0; i < DutStates; i++) begin
      for (int j = 0; j < DutStates; j++) begin
        for (int k = 0; k < DutStates; k++) begin
          for (int l = 0; l < DutStates; l++) begin

            // Assign named signals so they can be seen in TB
            signal_start = i;
            signal_intermediate = k;
            signal_final = l;

            repeat (3) @(posedge clk);
            #ApplTime;
            position_d = START;
            signal_d = signal_start;

            @(posedge clk);
            #ApplTime;
            position_d = INJECT;

            @(posedge clk);
            #ApplTime;
            position_d = INTERMEDIATE;
            signal_d = signal_intermediate;

            @(posedge clk);
            #ApplTime;
            position_d = UNINJECT;

            @(posedge clk);
            #ApplTime;
            position_d = FINAL;
            signal_d = signal_final;
            
            @(posedge clk);
            #ApplTime;
            signal_d = 0;
            position_d = IDLE;
            repeat (4) @(posedge clk);

          end
        end
      end
    end
    done = 1;
  end

endmodule

