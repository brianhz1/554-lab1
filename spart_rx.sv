module spart_rx
(
    input clk,
    input rst_n,
    input enable,   // 16x baud freq
    input [1:0] addr,
    input iorw,
    input IOCS,
    input RX,
    output logic RDA, // receive data available
    inout [7:0] rx_data
);

    typedef enum logic [1:0] {IDLE, START, RECEIVE, STOP} state_t;
    state_t state, next_state;
    logic [7:0] rx_shift_reg;
    logic [3:0] baud_counter; // counts enable to generate baud clk
    logic [3:0] bit_counter; // counts number of bits received
    logic init, shift, inc; // signals to initialize, shift and increment counters

    // state ff
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // state datapath
    always_comb begin
        next_state = state;
        init = 1'b0;
        shift = 1'b0;
        RDA = 1'b0;
        inc = 1'b0;
        rx_data_valid = 1'b0;

        case (state)
            START: begin
                if (enable & !RX) // start bit detected
                    next_state = RECEIVE;
            end

            RECEIVE: begin
                if (&baud_counter & enable) begin
                    if (bit_counter == 4'd8)
                        next_state = STOP;
                    else
                        shift = 1'b1;
                end
                if (enable)
                    inc = 1'b1;
            end

            STOP: begin
                if (&baud_counter & enable) begin
                    if (RX) begin // stop bit detected
                        next_state = IDLE;
                        rx_data_valid = 1'b1;  // mark data as valid
                    end
                end
            end

            default: begin // IDLE state
                if (!RX) begin // detect start bit
                    init = 1'b1;
                    next_state = START;
                end
            end
        endcase
    end

    // rx_shift_reg ff
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            rx_shift_reg <= '0;
        else if (shift)
            rx_shift_reg <= {RX, rx_shift_reg[7:1]};
    end

    // baud_counter ff
    always_ff @(posedge clk) begin
        if (init)
            baud_counter <= 0;
        else if (inc)
            baud_counter <= baud_counter + 1;
    end

    // bit_counter ff
    always_ff @(posedge clk) begin
        if (init)
            bit_counter <= 0;
        else if (shift)
            bit_counter <= bit_counter + 1;
    end

    // Data availability logic (RDA)
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            RDA <= 1'b0;
        else if (rx_data_valid)
            RDA <= 1'b1;  // data is ready after STOP state
        else if ((iorw == 1'b0) & IOCS & (addr == 2'b00))  // clear RDA when read occurs
            RDA <= 1'b0;
    end

    // Assigning received data to rx_data when read
    assign rx_data = (IOCS && (iorw == 1'b0) && (addr == 2'b00)) ? rx_shift_reg : 8'hzz;

endmodule
