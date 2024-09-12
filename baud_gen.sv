module baud_gen
(
    input clk,
    input init,
    input [1:0] br_cfg,
    output enable // 16x selected baud rate
);

    logic [11:0] counter;   // down counter
    logic [11:0] load;  // value to load into down counter

    always_comb begin
        case (br_cfg)
            2'b00: load = 11'd651;  // 4800 baud * 16
            2'b01: load = 11'd326;  // 9600 baud * 16
            2'b10: load = 11'd163;  // 19200 baud * 16
            // 2'b11
            default: load = 11'd81; // 38400 baud * 16
        endcase
    end

    always_ff @(posedge clk) begin
        if (init)
            counter <= load;
        else
            counter <= counter - 1;
    end

    assign enable = counter == 0;

endmodule
