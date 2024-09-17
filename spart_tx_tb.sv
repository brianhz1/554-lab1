module spart_tx_tb ();
    logic clk;
    logic rst_n;
    logic write;
    logic [7:0] tx_data;
    logic [1:0] addr;
    logic [9:0] counter;

    spart_tx iSPART_TX(.clk(clk), .rst_n(rst_n), .enable(enable), .addr(addr), .tx_data(tx_data), .iorw(write), .TBR(TBR), .TX(TX));

    initial begin
        clk = 1'b0;
        addr = 2'b01;
        rst_n = 1'b0;
        write = 1'b1;
        #5;
        rst_n = 1'b1;

        @(posedge clk);
        #1;
        if (!TBR)
            $display("ERROR: TBR is low");

        tx_data = 8'b01111111;
        write = 1'b0;
        addr = 2'b00;
        @(posedge clk);
        #1;
        write = 1'b1;
        addr = 2'b01;

        @(posedge TBR);
        #100;
        $stop();
    end

    always 
        #20 clk = ~clk;

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            counter <= 9'd163; // 19200 bps * 16
        else
            counter <= counter - 1;
    end

    assign enable = counter == 0;

endmodule

// program test 
// (
//     input clk,
//     input TBR,
//     input TX,
//     output logic rst_n,
//     output logic [7:0] tx_data,
//     output logic write
// );
//     initial begin
//         rst_n = 1'b0;
//         #5;
//         rst_n = 1'b1;

//         @(posedge clk);
//         if (!TBR)
//             $display("ERROR: TBR is low");

//         tx_data = 8'b01111111;
//         write = 1'b1;

//         @(posedge TBR);
//         #100;
//         $stop();
//     end
// endprogram