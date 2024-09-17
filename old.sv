   // baud_gen
   // input [1:0] br_cfg,   
   
   // always_comb begin
    //     case (br_cfg)
    //         2'b00: load = 16'd650;  // 4800 baud * 16
    //         2'b01: load = 16'd325;  // 9600 baud * 16
    //         2'b10: load = 16'd162;  // 19200 baud * 16
    //         // 2'b11
    //         default: load = 16'd80; // 38400 baud * 16
    //     endcase
    // end