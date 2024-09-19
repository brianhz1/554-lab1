//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    
// Design Name: 
// Module Name:    driver 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module driver(
    input clk,
    input rst,
    input [1:0] br_cfg,
    input rda,
    input tbr,
    output logic [1:0] ioaddr,
    output iocs,
    output logic iorw,
    inout [7:0] databus
);

    typedef enum logic [3:0] {IDLE, DB_LOW, DB_HIGH, RECEIVE, TRANSMIT, TBR_WAIT} state_t;
    state_t state, next_state;

    logic [1:0] br_cfg_curr; // compare with br_cfg to notice change
    logic [7:0] data_buffer; // buffers data received
    logic [7:0] bus_wdata;
    logic w_db, bus_write, new_br_cfg;

    // state ff
    always_ff @(posedge clk, negedge rst) begin
        if (!rst)
            state <= DB_LOW; // old: IDLE
        else
            state <= next_state;
    end

    // data buffer ff
    always_ff @(posedge clk, negedge rst) begin
        if (!rst)
            data_buffer <= 0;
        else if (w_db)
            data_buffer <= databus;
    end

    // current br_cfg ff
    always_ff @(posedge clk, negedge rst) begin
        if (!rst)
            br_cfg_curr <= 2'b10;
        else if (new_br_cfg)
            br_cfg_curr <= br_cfg;
    end

    assign databus = bus_write ? bus_wdata : 8'hzz;

    always_comb begin
        // defaults
        next_state = state;
        iorw = 1'b1;
        ioaddr = 2'b01;
        new_br_cfg = 1'b0; // update br_cfg_curr
        w_db = 1'b0; // update data buffer
        bus_write = 1'b0; // drives databus when high
        bus_wdata = 8'h00; // data to write onto bus

        case (state)
            DB_LOW: begin
                case (br_cfg)  // old: br_cfg_curr
                    2'b00: bus_wdata = 8'h8A;  // 4800 baud * 16
                    2'b01: bus_wdata = 8'h45;  // 9600 baud * 16
                    2'b10: bus_wdata = 8'hA2;  // 19200 baud * 16
                    // 2'b11
                    default: bus_wdata = 8'h50; // 38400 baud * 16
                endcase

                iorw = 1'b0;
                ioaddr = 2'b10;
                bus_write = 1'b1;
                next_state = DB_HIGH;
            end

            DB_HIGH: begin
                case (br_cfg)  // old: br_cfg_curr
                    2'b00: bus_wdata = 8'h02;  // 4800 baud * 16
                    2'b01: bus_wdata = 8'h01;  // 9600 baud * 16
                    2'b10: bus_wdata = 8'h00;  // 19200 baud * 16
                    // 2'b11
                    default: bus_wdata = 8'h00; // 38400 baud * 16
                endcase

                iorw = 1'b0;
                ioaddr = 2'b11;
                bus_write = 1'b1;
                next_state = IDLE;
            end

            RECEIVE: begin
                ioaddr = 2'b00;
                w_db = 1'b1;
                next_state = TBR_WAIT;
            end

            TBR_WAIT:
                if (tbr)
                    next_state = TRANSMIT;

            TRANSMIT: begin
                iorw = 1'b0;
                ioaddr = 2'b00;
                bus_write = 1'b1;
                bus_wdata = data_buffer;
                next_state = IDLE;
            end

            default: begin // IDLE
                // if (br_cfg != br_cfg_curr) begin
                //     next_state = DB_LOW;
                //     new_br_cfg = 1;
                // end
                // else 
                if (rda)
                    next_state = RECEIVE;
            end
        endcase
    end

    assign iocs = 1'b1;
endmodule
