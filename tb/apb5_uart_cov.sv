class apb5_uart_cov;
    // Pointer to the transaction we are currently measuring
    apb5_uart_trans trans;

    // The Coverage Checklist
    covergroup cg_apb;
        option.per_instance = 1;
        
        // 1. Did we hit every address in our register map?
        cp_paddr: coverpoint trans.paddr[7:0] {
            bins TX_RX_REG  = {8'h00};
            bins STATUS_REG = {8'h04};
            bins CTRL_REG   = {8'h08};
        }
        
        // 2. Did we do both Reads and Writes?
        cp_pwrite: coverpoint trans.pwrite {
            bins READ  = {1'b0};
            bins WRITE = {1'b1};
        }
        
        // 3. CROSS COVERAGE: Did we read AND write to EVERY register? 
        // (This generates 3x2 = 6 unique bins to check off)
        cr_addr_rw: cross cp_paddr, cp_pwrite;

        // 4. Did we test the AMBA 5 Low-Power states?
        cp_pwakeup: coverpoint trans.pwakeup {
            bins SLEEPING = {1'b0};
            bins AWAKE    = {1'b1};
        }
    endgroup

    // Constructor
    function new();
        cg_apb = new();
    endfunction

    // This function is called by the Monitor every time a packet is seen on the bus
    function void sample(apb5_uart_trans t);
        this.trans = t;
        cg_apb.sample(); // Tells Xcelium to update the checklist!
    endfunction
    
    // Quick helper to print our grade at the end
    function void display_coverage();
        $display("==================================================");
        $display(" FINAL FUNCTIONAL COVERAGE: %0.2f%%", cg_apb.get_inst_coverage());
        $display("==================================================");
    endfunction
endclass
