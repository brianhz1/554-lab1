module spart_tb ();

    logic clk;
    logic rst_n;

    logic [3:0] key; // key[0] is rst_n
    logic [9:0] sw; // sw[9:8] select baud rate
    wire [35:0] gpio; // GPIO[3] as TX output, GPIO[5] as RX input
    logic [1:0] br_cfg;

    // testbench spart controls
    wire [7:0] databus;
    logic [1:0] ioaddr;
    logic iorw, iocs;

    logic db_w; // drive databus when high
    logic [7:0] db_data; // databus to drive databus

    lab1_spart iDUT(.CLOCK_50(clk), .KEY(key), .GPIO(gpio));
    spart spart_tb(.clk(clk),
                .rst(rst_n),
                .iocs(iocs),
                .iorw(iorw),
                .rda(rda),
                .tbr(tbr),
                .ioaddr(ioaddr),
                .databus(databus),
                .txd(txd),
                .rxd(rxd)
            );

    assign key[0] = ~rst_n;
    assign sw[9:8] = br_cfg;
    assign iocs = 1'b1;
    assign rxd = gpio[3];
    assign gpio[5] = txd;
    assign databus = db_w  ? db_data : 8'hzz;

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        br_cfg = 2'b10;
        iorw = 1;
        ioaddr = 2'b01;
        db_data = 8'h00;
        db_w = 1'b0;

        repeat(2) @(posedge clk);
        #1;
        rst_n = 1'b1;

        repeat(10) transaction();

        #100;
        $stop();
    end

    always
        #20 clk = ~clk;

    task automatic transaction();
        bit [7:0] data;
        data = $random();

        // write to tx buffer
        @(posedge clk);
        #1;
        if (!tbr)
            $display("ERROR: TBR not ready");
        ioaddr = 2'b00;
        iorw = 0;
        db_data = data;
        db_w = 1;

        // wait for response
        @(posedge clk);
        #1;
        ioaddr = 2'b01;
        iorw = 1;
        db_w = 0;
        @(posedge rda)
        @(posedge clk);
        #1;

        // rx buffer read
        if (!rda)
            $display("ERROR: RDA unset without read");
        ioaddr = 2'b00;
        iorw = 1;
        #1;
        $display("Data sent: %h, Data received: %h", data, databus);

        @(posedge clk);
        #1;
    endtask
endmodule