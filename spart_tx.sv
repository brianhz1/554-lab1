module spart_tx 
(
    input clk,
    input rst_n,
    input enable,   // 16x baud freq
    input [1:0] addr,
    input [7:0] tx_data, // internal databus
    input iorw,    // write when low
    input iocs,
    output logic TBR, // transmit buffer ready
    output TX
);

    typedef enum logic [1:0] {IDLE, WAIT, TRANSMIT} state_t;
    state_t state, next_state; 
    logic [8:0] tx_shift_reg; 
    logic [3:0] baud_counter; // counts enable to generate baud clk
    logic [3:0] shift_counter; // counts number of bits shifted
    logic init; // initializes counters, sets shift register
    logic shift; // shifts out next bit
    logic inc; // increments baud counter

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
        TBR = 1'b0;
        inc = 1'b0;

        case (state)
            WAIT: begin // waits for next enable signal
                if (enable)
                    next_state = TRANSMIT;
            end

            TRANSMIT: begin
                if (&baud_counter & enable) begin
                    if (shift_counter == 4'd9)
                        next_state = IDLE;
                    else
                        shift = 1'b1;
                end

                if (enable)
                    inc = 1'b1;
            end

            default: begin // IDLE state
                TBR = 1'b1;
                if (!iorw & (addr == 2'b00) && iocs) begin
                    init = 1'b1;
                    next_state = WAIT;
                end
            end
        endcase
    end

    // tx_shift_reg ff
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            tx_shift_reg <= '1;
        else if (init)
            tx_shift_reg <= {tx_data, 1'b0};
        else if (shift)
            tx_shift_reg <= {1'b1, tx_shift_reg[8:1]};
    end

    // baud_counter ff
    always_ff @(posedge clk) begin
        if (init)
            baud_counter <= 0;
        else if (inc)
            baud_counter <= baud_counter + 1;

    end

    // shift_counter ff
    always_ff @(posedge clk) begin
        if (init)
            shift_counter <= 0;
        else if (shift)
            shift_counter <= shift_counter + 1;
    end

    assign TX = tx_shift_reg[0];

endmodule