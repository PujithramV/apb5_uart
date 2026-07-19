class apb5_uart_env;
    // --- Instances of the Verification Components ---
    apb5_uart_gen gen;
    apb5_uart_drv drv;
    apb5_uart_mon mon;
    apb5_uart_scb scb;
    apb5_uart_cov cov; // The new Coverage Collector

    // --- Mailboxes and Events ---
    mailbox #(apb5_uart_trans) gen2drv;
    mailbox #(apb5_uart_trans) mon2scb;
    event gen_done;

    // --- Virtual Interfaces ---
    virtual apb5_uart_if.DRIVER drv_vif;
    virtual apb5_uart_if.MONITOR mon_vif;

    // Constructor: Wires everything together
    function new(virtual apb5_uart_if.DRIVER d_vif, virtual apb5_uart_if.MONITOR m_vif);
        this.drv_vif = d_vif;
        this.mon_vif = m_vif;
        
        // 1. Create the mailboxes
        gen2drv = new();
        mon2scb = new();
        
        // 2. Instantiate the components and pass the mailboxes/interfaces to them
        gen = new(gen2drv, gen_done);
        drv = new(drv_vif, gen2drv);
        mon = new(mon_vif, mon2scb);
        scb = new(mon2scb);
        cov = new(); // Instantiate the Coverage Collector
    endfunction

    // Phase 1: Reset the DUT
    task pre_test();
        drv.reset();
    endtask

    // Phase 2: Run all components in parallel and route data
    task test();
        fork
            gen.run();
            drv.run();
            mon.run();
            
            // Scoreboard & Coverage Router
            begin
                apb5_uart_trans t;
                forever begin
                    mon2scb.get(t);
                    
                    // 1. Send to Scoreboard for error checking
                    if (t.pslverr) begin
                        $display("[SCOREBOARD] ERROR at Address 0x%0h", t.paddr);
                    end else begin
                        $display("[SCOREBOARD] Success at Address 0x%0h", t.paddr);
                    end
                    
                    // 2. Send to Coverage Collector to check off the boxes
                    cov.sample(t);
                end
            end
        join_any
    endtask

    // Phase 3: Wait for generation to finish, then flush the system
    task post_test();
        wait(gen_done.triggered);
        #5000; // Wait a bit for the last transactions to clear the UART serial line
        cov.display_coverage(); // Print the final grade!
    endtask

    // Main execution wrapper
    task run();
        pre_test();
        test();
        post_test();
    endtask
endclass
