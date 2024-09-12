module baud_gen
(
    input clk,
    input rst_n,
    input init,
    input [1:0] br_cfg,
    output enable // 16x selected baud rate
);

    logic [9:0] counter;   // down counter
    logic [9:0] load;  // value to load into divisor buffer
    logic [9:0] divisor_buffer; // value to load into down counter

    always_comb begin
        case (br_cfg)
            2'b00: load = 10'd651;  // 4800 baud * 16
            2'b01: load = 10'd326;  // 9600 baud * 16
            2'b10: load = 10'd163;  // 19200 baud * 16
            // 2'b11
            default: load = 10'd81; // 38400 baud * 16
        endcase
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            divisor_buffer <= load;
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) 
            counter <= 0;
        else if (counter == 0)
            counter <= divisor_buffer;
        else
            counter <= counter - 1;
    end

    assign enable = counter == 0;

endmodule