class apb5_uart_scb;
    // Mailbox to receive packets from the Monitor
    mailbox #(apb5_uart_trans) mon2scb;

    // Constructor
    function new(mailbox #(apb5_uart_trans) m2s);
        this.mon2scb = m2s;
    endfunction

    // Main execution task
    task run();
        apb5_uart_trans trans;
        forever begin
            // Wait for a packet from the Monitor
            mon2scb.get(trans);
            
            // Basic logging (we will add robust pass/fail checks here later)
            if (trans.pslverr) begin
                $display("[SCOREBOARD] ERROR FLAG DETECTED at Address 0x%0h", trans.paddr);
            end else begin
                $display("[SCOREBOARD] Successful transaction observed at Address 0x%0h", trans.paddr);
            end
        end
    endtask
endclass
