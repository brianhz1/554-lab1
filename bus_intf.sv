module bus_intf(
    input iocs,           // I/O Chip Select
    input iorw,           // I/O Read/Write control
    input [1:0] ioaddr,   // I/O Address (used to select status or buffer)
    input tbr,
    input rda,
    inout [7:0] databus,  // 8-bit bidirectional data bus
    inout [7:0] databus_in // internal data bus
);

    wire [7:0] status_reg;
    assign status_reg = {6'b000000, tbr, rda};

    // Control the bidirectional databus
    assign databus = (iocs && iorw) ? ((ioaddr == 2'b01) ? status_reg : databus_in) : 8'hzz;

    assign databus_in = (iocs && !iorw) ? databus : 8'hzz;

endmodule

