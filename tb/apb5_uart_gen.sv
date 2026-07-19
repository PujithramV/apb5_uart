class apb5_uart_gen;
    // Mailbox to send randomized transactions down to the Driver
    mailbox #(apb5_uart_trans) gen2drv;
    
    // Event to let the main environment know we are done generating
    event gen_done;
    
    // Configurable number of transactions to send
    int trans_count;

    // Constructor
    function new(mailbox #(apb5_uart_trans) g2d, event done);
        this.gen2drv = g2d;
        this.gen_done = done;
    endfunction

    // Main execution task
    task run();
        apb5_uart_trans trans;
        for (int i = 0; i < trans_count; i++) begin
            trans = new();
            // Randomize the packet. If it fails our constraints, throw a fatal error.
            if (!trans.randomize()) $fatal("Generator: Randomization failed!");
            
            // Put the packet in the mailbox
            gen2drv.put(trans);
        end
        
        // Trigger the event to signal completion
        -> gen_done;
    endtask
endclass
