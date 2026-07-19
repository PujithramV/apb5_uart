// Include the class files so the compiler can find them
`include "../tb/apb5_uart_trans.sv"
`include "../tb/apb5_uart_gen.sv"
`include "../tb/apb5_uart_drv.sv"
`include "../tb/apb5_uart_mon.sv"
`include "../tb/apb5_uart_scb.sv"
`include "../tb/apb5_uart_cov.sv" // <-- NEW: Include the Coverage class
`include "../tb/apb5_uart_env.sv"

module tb_top;

    // System Clock and Reset
    bit PCLK;
    bit PRESETn;

    // Generate 100MHz clock
    always #5 PCLK = ~PCLK;

    // Generate Reset independently in the background
    initial begin
        PRESETn = 1'b1;
        #15 PRESETn = 1'b0; // Pull reset low
        #20 PRESETn = 1'b1; // Release reset
    end

    // Instantiate the Virtual Interface
    apb5_uart_if vif(PCLK, PRESETn);

    // Instantiate the DUT (RTL) and connect it to the interface
    apb5_uart_bridge dut (
        .PCLK      (vif.PCLK),
        .PRESETn   (vif.PRESETn),
        .PADDR     (vif.PADDR),
        .PSEL      (vif.PSEL),
        .PENABLE   (vif.PENABLE),
        .PWRITE    (vif.PWRITE),
        .PWDATA    (vif.PWDATA),
        .PSTRB     (vif.PSTRB),
        .PPROT     (vif.PPROT),
        .PWAKEUP   (vif.PWAKEUP),
        .PREADY    (vif.PREADY),
        .PRDATA    (vif.PRDATA),
        .PSLVERR   (vif.PSLVERR),
        .rx_pin    (vif.rx_pin),
        .tx_pin    (vif.tx_pin),
        .interrupt (vif.interrupt)
    );

    // --- NEW: Bind the Protocol Police (SVA) to the Virtual Interface pins ---
    apb5_uart_sva protocol_check (
        .PCLK    (vif.PCLK),
        .PRESETn (vif.PRESETn),
        .PSEL    (vif.PSEL),
        .PENABLE (vif.PENABLE),
        .PREADY  (vif.PREADY)
    );

    // Instantiate the Environment
    apb5_uart_env env;

    initial begin
        // Setup waveform dumping
        $shm_open("waves.shm"); 
        $shm_probe("AS"); 
        
        // Pass the interface modports to the environment
        env = new(vif.DRIVER, vif.MONITOR);
        
        // Tell the generator to create exactly 100 random packets to build coverage
        env.gen.trans_count = 100;
        
        // Start the simulation!
        env.run();
        
        $display("==================================================");
        $display("   TEST OOPS ENVIRONMENT COMPLETED SUCCESSFULLY   ");
        $display("==================================================");
        $finish;
    end

endmodule
