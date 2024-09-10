module baud_gen
#(  
    parameter clk = 50000000,    // 50 Mhz
    parameter baud_rate = 19200; // bit per second
)
(
    input i_clk,
    input i_init,
    output o_baud_clk
);

    logic [$clog2(clk/baud_rate)-1:0] counter;

    always_ff @(posedge i_clk) begin
        if (i_init)
            counter <= 0;
        else
            counter <= counter + 1;
    end

    assign o_baud_clk = &counter;

endmodule
