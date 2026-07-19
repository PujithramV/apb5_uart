class apb5_uart_drv;
    // Virtual interface to access the physical pins
    virtual apb5_uart_if.DRIVER vif;
    
    // Mailbox to receive transactions from the Generator
    mailbox #(apb5_uart_trans) gen2drv;

    // Constructor
    function new(virtual apb5_uart_if.DRIVER v, mailbox #(apb5_uart_trans) g2d);
        this.vif = v;
        this.gen2drv = g2d;
    endfunction

    // Task to initialize the bus during reset
    task reset();
        wait(!vif.PRESETn); // Wait for reset to go active (low)
        vif.drv_cb.PADDR   <= 32'h0;
        vif.drv_cb.PSEL    <= 1'b0;
        vif.drv_cb.PENABLE <= 1'b0;
        vif.drv_cb.PWRITE  <= 1'b0;
        vif.drv_cb.PWDATA  <= 32'h0;
        vif.drv_cb.PSTRB   <= 4'h0;
        vif.drv_cb.PWAKEUP <= 1'b0;
        wait(vif.PRESETn);  // Wait for reset to be released
        $display("[DRIVER] Reset dropped. Ready to drive.");
    endtask

    // Main execution task
    task run();
        apb5_uart_trans trans;
        forever begin
            // 1. Wait for a packet from the generator
            gen2drv.get(trans);

            // 2. AMBA APB SETUP Phase
            @(vif.drv_cb);
            vif.drv_cb.PADDR   <= trans.paddr;
            vif.drv_cb.PWRITE  <= trans.pwrite;
            vif.drv_cb.PSEL    <= 1'b1;
            vif.drv_cb.PENABLE <= 1'b0;
            vif.drv_cb.PWAKEUP <= trans.pwakeup;
            
            if (trans.pwrite) begin
                vif.drv_cb.PWDATA <= trans.pwdata;
                vif.drv_cb.PSTRB  <= trans.pstrb;
            end

            // 3. AMBA APB ACCESS Phase
            @(vif.drv_cb);
            vif.drv_cb.PENABLE <= 1'b1;

            // Wait for the slave to pull PREADY high
            while (vif.drv_cb.PREADY !== 1'b1) begin
                @(vif.drv_cb);
            end

            // 4. Return to IDLE / Cleanup
            @(vif.drv_cb);
            vif.drv_cb.PSEL    <= 1'b0;
            vif.drv_cb.PENABLE <= 1'b0;
            vif.drv_cb.PSTRB   <= 4'h0;
            
            // Print out what we just drove for debugging
            trans.display("DRIVER");
        end
    endtask
endclass
