module baud_gen_tb ();
    logic clk;
    logic rst_n;
    logic iorw;
    logic [7:0] bus_data;
    logic [1:0] addr;
    logic enable;
    // logic [9:0] br_cfg;

    integer count;

    baud_gen iBAUD_GEN(.*);


    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        count = 0;
        iorw = 1;  // 1 is read
        bus_data = 8'h00;
        addr = 2'b01;
        #5;
        rst_n = 1'b1;

        @(posedge clk);
        #1;
        repeat (8) begin
            @(posedge enable);
            count++;
        end 

        @(posedge clk);
        #1;
        iorw = 0;
        addr = 2'b10;
        bus_data = 8'h50;

        @(posedge clk);
        #1;
        iorw = 0;
        addr = 2'b11;
        bus_data = 8'h00;

        @(posedge clk);
        #1;
        iorw = 1;
        addr = 2'b01;
        
        repeat (8) begin
            @(posedge enable);
            count++;
        end 

        #100;
        $display(count);
        $stop();
    end

    always 
        #20 clk = ~clk;

endmodule