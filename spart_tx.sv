module spart_tx 
(
    input clk,
    input rst_n,
    input enable,   // 16x baud freq
    input [7:0] tx_data,
    input write,
    output logic TBR, // transmit buffer ready
    output TX
);

    typedef enum logic {IDLE, TRANSMIT} state_t;
    state_t state, next_state; 
    logic [8:0] tx_shift_reg; 
    logic [3:0] baud_counter; // counts enable to generate baud clk
    logic [3:0] shift_counter; // counts number of bits shifted
    logic init; // initializes counters, sets shift register
    logic shift; // shifts out next bit

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

        case (state)
            TRANSMIT: begin
                if (&baud_counter)
                    shift = 1'b1;
                if (shift_counter == 4'd10) begin
                    next_state = IDLE;
                end
            end

            default: begin // IDLE state
                TBR = 1'b1;
                if (write) begin
                    init = 1'b1;
                    next_state = TRANSMIT;
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
        else if (enable)
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