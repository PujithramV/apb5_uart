class apb5_uart_mon;
    // Virtual interface for passive observation
    virtual apb5_uart_if.MONITOR vif;
    
    // Mailbox to send reconstructed packets to the Scoreboard
    mailbox #(apb5_uart_trans) mon2scb;

    // Constructor
    function new(virtual apb5_uart_if.MONITOR v, mailbox #(apb5_uart_trans) m2s);
        this.vif = v;
        this.mon2scb = m2s;
    endfunction

    // Main execution task
    task run();
        apb5_uart_trans trans;
        forever begin
            // Sample on the clock edge
            @(vif.mon_cb);
            
            // Wait for a valid AMBA 5 APB Access Phase (PSEL, PENABLE, and PREADY all high)
            if (vif.mon_cb.PSEL && vif.mon_cb.PENABLE && vif.mon_cb.PREADY) begin
                trans = new();
                
                // Reconstruct the transaction object from the physical pins
                trans.paddr   = vif.mon_cb.PADDR;
                trans.pwrite  = vif.mon_cb.PWRITE;
                trans.pwdata  = vif.mon_cb.PWDATA;
                trans.pstrb   = vif.mon_cb.PSTRB;
                trans.pwakeup = vif.mon_cb.PWAKEUP;
                trans.prdata  = vif.mon_cb.PRDATA;
                trans.pslverr = vif.mon_cb.PSLVERR;
                
                // Send the captured packet to the scoreboard
                mon2scb.put(trans);
                
                // Display for debugging
                trans.display("MONITOR");
            end
        end
    endtask
endclass
