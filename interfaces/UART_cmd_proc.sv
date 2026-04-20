interface UART_cmd_proc_if;
    modport master(
        output logic clr_cmd_rdy,
        output logic send_resp,
        input logic cmd,
        input logic cmd_rdy
    );
    modport slave(
        input logic clr_cmd_rdy,
        input logic send_resp,
        output logic cmd,
        output logic cmd_rdy
    );
endinterface