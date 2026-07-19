class apb5_uart_trans;

    // Randomized variables for Constrained Random Testing
    rand logic [31:0] paddr;
    rand logic        pwrite;
    rand logic [31:0] pwdata;
    rand logic [3:0]  pstrb;
    rand logic [2:0]  pprot;
    rand logic        pwakeup;

    // Non-random variables (Outputs captured from the DUT)
    logic [31:0] prdata;
    logic        pslverr;

    // --- Constraints to ensure valid AMBA 5 scenarios ---
    // Constraint 1: Restrict address to our valid register map boundaries
    constraint valid_address {
        paddr[7:0] inside {8'h00, 8'h04, 8'h08};
        paddr[31:8] == 24'h0; // Clear upper address bits for simplification
    }

    // Constraint 2: Maintain AMBA 5 power aware distribution
    constraint power_distribution {
        pwakeup dist {1'b1 := 90, 1'b0 := 10}; // 90% chance device is awake
    }

    // Constraint 3: Strobe byte alignment constraints (AMBA 4/5 requirement)
    constraint valid_strobe {
        if (pwrite && (paddr[7:0] == 8'h08)) {
            pstrb inside {4'h1, 4'h3, 4'h7, 4'hF}; // Valid byte/word mappings
        } else {
            pstrb == 4'h0;
        }
    }

    // Utility function to print transaction details to the terminal/log
    function void display(string tag);
        $display("[%s] Time=%0t | Addr=0x%0h | Wr=%0b | Data=0x%0h | Strobe=0x%0h | Wake=%0b | Rdata=0x%0h | Err=%0b", 
                 tag, $time, paddr, pwrite, pwdata, pstrb, pwakeup, prdata, pslverr);
    endfunction

endclass
