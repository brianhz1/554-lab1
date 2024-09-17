module baud_gen
(
    input clk,
    input rst_n,
    input iorw, // write when low
    input iocs,
    input [1:0] addr, //  0: DB low, 1: DB high
    output enable, // 16x selected baud rate
    inout [7:0] bus_data // data bus
);

    logic [15:0] counter;   // down counter
    logic [15:0] load;  // value to load into divisor buffer
    logic [15:0] divisor_buffer; // value to load into down counter 

    assign bus_data = (addr[1] && iorw && iocs) ? (addr[0] ? divisor_buffer[15:8] : divisor_buffer[7:0]) : 8'hzz;

    // division buffer
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            divisor_buffer <= 16'd162;
        else if (!iorw && iocs)
            if (addr == 2'b11)
                divisor_buffer[15:8] <= bus_data;
            else if (addr == 2'b10)
                divisor_buffer[7:0] <= bus_data;
    end

    // down counter
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