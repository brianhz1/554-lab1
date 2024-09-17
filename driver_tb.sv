module driver_tb ();
    logic clk;
    logic rst;
    logic [1:0] br_cfg;
    logic rda;
    logic tbr;
    logic [1:0] ioaddr;
    logic db_w; // drives databus when high
    logic [7:0] db_data;
    wire [7:0] databus;

    assign databus = db_w ? db_data : 8'hzz;

    driver driver0( .clk(clk),
                .rst(rst),
                .br_cfg(br_cfg),
                .iocs(iocs),
                .iorw(iorw),
                .rda(rda),
                .tbr(tbr),
                .ioaddr(ioaddr),
                .databus(databus)
            );


    initial begin
        clk = 0;
        rst = 0;
        br_cfg = 2'b10;
        rda = 0;
        tbr = 0;
        db_w = 0;
        db_data = 8'h00;
        #5;
        rst = 1;
        
        repeat (5) @(posedge clk);
        // checks initialization
        #1;
        if (!(driver0.br_cfg_curr === 2'b10))
            $display("ERROR: br_cfg changed with no stimulus");

        test_br_cfg(2'b00);
        test_br_cfg(2'b01);
        test_br_cfg(2'b10);
        test_br_cfg(2'b11);
        
        repeat(5) test_rx_tx();

        #100;
        $stop();
    end

    // tests changing br_cfg
    task automatic test_br_cfg (logic [1:0] br_new);
        @(posedge clk)
        #1;
        br_cfg = br_new;

        @(posedge clk)
        #1;
        if (!(ioaddr === 2'b10 && iocs === 1'b1 && iorw === 1'b0))
            case (br_new)
                2'b00: 
                    if (!(databus === 8'h8A))
                        $display("ERROR writing to DB low, br_cfg = %b", br_new);
                2'b01:
                    if (!(databus === 8'h45))
                        $display("ERROR writing to DB low, br_cfg = %b", br_new);
                2'b10: 
                    if (!(databus === 8'hA2))
                        $display("ERROR writing to DB low, br_cfg = %b", br_new);
                2'b11: 
                    if (!(databus === 8'h50))
                        $display("ERROR writing to DB low, br_cfg = %b", br_new);
            endcase
            
        @(posedge clk)
        #1;
        if (!(ioaddr === 2'b10 && iocs === 1'b1 && iorw === 1'b0))
        case (br_new)
            2'b00: 
                if (!(databus === 8'h02))
                    $display("ERROR writing to DB low, br_cfg = %b", br_new);
            2'b01:
                if (!(databus === 8'h01))
                    $display("ERROR writing to DB low, br_cfg = %b", br_new);
            2'b10: 
                if (!(databus === 8'h00))
                    $display("ERROR writing to DB low, br_cfg = %b", br_new);
            2'b11: 
                if (!(databus === 8'h00))
                    $display("ERROR writing to DB low, br_cfg = %b", br_new);
        endcase
            
        @(posedge clk)
        #1;
    endtask

    // test a rx -> tx transaction
    task automatic test_rx_tx ();
        bit [7:0] data;

        data = $random();
        @(posedge clk);
        #1;
        rda = 1'b1;
        @(posedge clk);
        #1;
        if (!(ioaddr === 2'b00 && iorw === 1'b1))
            $display("ERROR: incorrect read from rx buffer, ioaddr = %h, iorw = %h", ioaddr, iorw);
        db_data = data;
        db_w = 1'b1;
        @(posedge clk);
        #1;
        db_w = 1'b0;
        repeat(100) @(posedge clk);
        #1;
        tbr = 1'b1;
        @(posedge clk);
        #1;
        if (!(ioaddr === 2'b00 && iorw === 1'b0 && databus === data))
            $display("ERROR: incorrect write to tx buffer, ioaddr = %h, iorw = %h, data = %h", ioaddr, iorw, databus);
        @(posedge clk);
        #1;
        tbr = 1'b0;
        rda = 1'b0;
    endtask

    // clk generator
    always 
        #20 clk = ~clk;

endmodule