module bus_intf(
    input iocs,           // I/O Chip Select
    input iorw,           // I/O Read/Write control
    input [1:0] ioaddr,   // I/O Address (used to select status or buffer)
    inout [7:0] databus,  // 8-bit bidirectional data bus
    input [7:0] receive_buffer,   // Data from receive buffer
    output reg [7:0] transmit_buffer,  // Data to transmit buffer
    output reg transmit_control,   // Control signal for transmission
    output reg rda,       // Receive Data Available
    output reg tbr,       // Transmit Buffer Ready
    input receive_control  // Control signal indicating new data received
);

    reg [7:0] db_low;   // Divisor Buffer Low Byte
    reg [7:0] db_high;  // Divisor Buffer High Byte

    wire [7:0] status_reg;
    assign status_reg = {6'b000000, tbr, rda};

    // Control the bidirectional databus
    assign databus = (iocs && iorw) ? (
                        (ioaddr == 2'b00) ? receive_buffer :
                        (ioaddr == 2'b01) ? status_reg :
                        (ioaddr == 2'b10) ? db_low :
                        (ioaddr == 2'b11) ? db_high :
                        8'b0
                     ) : 8'bz;

    // Write operations
    always @(*) begin
        // Default values to prevent latches
        transmit_control = 0;
        // Keep previous values if not writing
        transmit_buffer = transmit_buffer;
        db_low = db_low;
        db_high = db_high;

        if (iocs && !iorw) begin
            case (ioaddr)
                2'b00: begin
                    transmit_buffer = databus; // Write to transmit buffer
                    tbr = 0;                   // Transmit buffer not ready
                    transmit_control = 1;      // Start transmission
                end
                2'b10: db_low = databus;       // Write to divisor buffer low
                2'b11: db_high = databus;      // Write to divisor buffer high
                default: ;
            endcase
        end
    end

    // Update rda flag
    always @(*) begin
        // Default to retain previous value
        rda = rda;

        if (receive_control) begin
            rda = 1;  // Data is available to read
        end else if (iocs && iorw && (ioaddr == 2'b00)) begin
            rda = 0;  // Data has been read from receive buffer
        end
    end

    // Update tbr flag
    always @(*) begin
        // Default to retain previous value
        tbr = tbr;

        if (transmit_control == 0 && tbr == 0) begin
            tbr = 1; // Transmit buffer is ready to accept new data
        end
    end

endmodule

