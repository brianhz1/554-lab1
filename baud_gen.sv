module baud_gen
#(  
    parameter clk_rate = 50000000,    // 50 Mhz
    parameter baud_rate = 19200; // bit per second
)
(
    input clk,
    input init,
    output baud_clk
);

    logic [$clog2(clk_rate/baud_rate)-1:0] counter;

    always_ff @(posedge clk) begin
        if (init)
            counter <= 0;
        else
            counter <= counter + 1;
    end

    assign baud_clk = &counter;

endmodule
