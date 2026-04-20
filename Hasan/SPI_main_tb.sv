`timescale 1ns/1ps

module SPI_main_tb;

    logic clk;
    logic rst_n;
    logic SS_n;
    logic SCLK;
    logic MOSI;
    logic MISO;
    logic wrt;
    logic [15:0] wt_data;
    logic done;
    logic [15:0] rd_data;
    logic INT;
    logic [15:0] rsp;

    SPI_main dut (
        .clk(clk),
        .rst_n(rst_n),
        .SS_n(SS_n),
        .SCLK(SCLK),
        .MOSI(MOSI),
        .MISO(MISO),
        .wrt(wrt),
        .wt_data(wt_data),
        .done(done),
        .rd_data(rd_data)
    );

    SPI_iNEMO1 SPI_NEMO1 (
        .SS_n(SS_n),
        .SCLK(SCLK),
        .MISO(MISO),
        .MOSI(MOSI),
        .INT(INT)
    );

    always #10 clk = ~clk;   //50 MHz clock

    task automatic issue_cmd(input logic [15:0] cmd);
        begin
            @(negedge clk);
            wt_data = cmd;
            wrt = 1'b1;
            @(negedge clk);
            wrt = 1'b0;
        end
    endtask

    task automatic do_cmd(input logic [15:0] cmd, output logic [15:0] rsp_word);
        begin
            issue_cmd(cmd);
            @(posedge done);
            rsp_word = rd_data;
            @(negedge clk);
        end
    endtask

    task automatic expect_byte(
        input logic [15:0] cmd,
        input logic [7:0] exp_byte,
        input string msg
    );
        begin
            do_cmd(cmd, rsp);
            if (rsp[7:0] !== exp_byte) begin
                $error("%s failed: expected 0x%02h got 0x%02h", msg, exp_byte, rsp[7:0]);
                $stop;
            end else begin
                $display("PASS: %s -> 0x%02h", msg, rsp[7:0]);
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        wrt = 1'b0;
        wt_data = 16'h0000;

        repeat (4) @(negedge clk);
        rst_n = 1'b1;
        repeat (2) @(negedge clk);

        //WHO_AM_I register should return 0x6A.
        expect_byte(16'h8F00, 8'h6A, "WHO_AM_I read");

        if (done !== 1'b1) begin
            $error("done should remain high until the next wrt pulse");
            $stop;
        end

        //write 0x02 to register 0x0D.
        do_cmd(16'h0D02, rsp);
        if (SPI_NEMO1.NEMO_setup !== 1'b1) begin
            $error("INT config write failed: NEMO_setup did not assert");
            $stop;
        end else begin
            $display("PASS: INT configuration write asserted NEMO_setup");
        end

        //wait for first data-ready interrupt and verify first yaw sample.
        wait (INT === 1'b1);
        $display("PASS: first INT asserted");
        expect_byte(16'hA600, 8'h8D, "row0 yawL read");

        //check if int cleared
        @(negedge clk);
        if (INT !== 1'b0) begin
            $error("INT should clear after yawL read in the provided model");
            $stop();
        end

        expect_byte(16'hA700, 8'h99, "row0 yawH read");

        //wait for the next sample
        wait (INT === 1'b1);
        $display("PASS: second INT asserted");
        expect_byte(16'hA600, 8'h3D, "row1 yawL read");
        expect_byte(16'hA700, 8'hCD, "row1 yawH read");

        $display("All SPI_main_tb checks passed.");
        $stop();
    end

endmodule
