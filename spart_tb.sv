module spart_tb ();

    logic clk;
    logic rst_n;

    logic [3:0] key; // key[0] is rst_n
    logic [9:0] sw; // sw[9:8] select baud rate
    wire [35:0] gpio; // GPIO[3] as TX output, GPIO[5] as RX input
    logic [1:0] br_cfg;
    logic [7:0] bus_wdata;

    // testbench spart controls
    wire [7:0] databus;
    logic [1:0] ioaddr;
    logic iorw, iocs;

    logic db_w; // drive databus when high
    logic [7:0] db_data; // databus to drive databus

    lab1_spart iDUT(.CLOCK_50(clk), .KEY(key), .GPIO(gpio), .SW(sw));
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

        repeat(5) transaction();
        set_baud(2'b00);
        repeat(5) transaction();
        set_baud(2'b01);
        repeat(5) transaction();
        set_baud(2'b11);
        repeat(5) transaction();
        #100;
        $stop();
    end

    always
        #20 clk = ~clk;

    // sends a byte of data and reads the received data
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
        @(posedge clk);
        #1;
        ioaddr = 2'b01;
        iorw = 1;
        db_w = 0;

        fork
            // wait for response
            begin
                @(posedge rda);
                disable timeout;
                @(posedge clk);
                #1;

                // rx buffer read
                if (!rda)
                    $display("ERROR: RDA unset before read");
                ioaddr = 2'b00;
                iorw = 1;
                #1;
                $display("BR: %h, Data sent: %h, Data received: %h", br_cfg, data, databus);

                @(posedge clk);
                #1;
                ioaddr = 2'b01;
            end 
            // timeout
            begin : timeout
                #40000000;
                $display("ERROR: No signal received");
                $stop();
            end : timeout
        join

        @(posedge clk);
        #1;
    endtask

    // sets baud rate on DUT and spart_tb
    task automatic set_baud (bit [1:0] br_new);
        @(posedge clk)
        #1;
        br_cfg = br_new;
        #1;
        rst_n = 1'b0;
        #1;
        rst_n = 1'b1;
        @(posedge clk)
        #1;

        case (br_cfg)  // old: br_cfg_curr
            2'b00: bus_wdata = 8'h8A;  // 4800 baud * 16
            2'b01: bus_wdata = 8'h45;  // 9600 baud * 16
            2'b10: bus_wdata = 8'hA2;  // 19200 baud * 16
            2'b11: bus_wdata = 8'h50; // 38400 baud * 16
        endcase
        ioaddr = 2'b10;
        iorw = 0;
        db_data = bus_wdata;
        db_w = 1;
            
        @(posedge clk)
        #1;
        case (br_cfg)  // old: br_cfg_curr
            2'b00: bus_wdata = 8'h02;  // 4800 baud * 16
            2'b01: bus_wdata = 8'h01;  // 9600 baud * 16
            2'b10: bus_wdata = 8'h00;  // 19200 baud * 16
            2'b11: bus_wdata = 8'h00; // 38400 baud * 16
        endcase
        ioaddr = 2'b11;
        iorw = 0;
        db_data = bus_wdata;
        db_w = 1;
            
        @(posedge clk)
        #1;
        ioaddr = 2'b01;
        iorw = 1;
        db_w = 0;

        @(posedge clk)
        #1;
    endtask
endmodule