module apb5_uart_sva (
    input logic PCLK,
    input logic PRESETn,
    input logic PSEL,
    input logic PENABLE,
    input logic PREADY
);

    // Rule 1: If PSEL goes high (a transfer starts), PENABLE MUST go high on the very next clock cycle.
    property p_psel_penable;
        @(posedge PCLK) disable iff (!PRESETn) // Ignore during reset
        $rose(PSEL) |=> PENABLE;               // |=> means "implies on the next clock cycle"
    endproperty
    
    assert_psel_penable: assert property(p_psel_penable) 
        else $error("SVA ERROR: APB Protocol Violation! PSEL rose, but PENABLE didn't follow.");

    // Rule 2: If the slave is not ready (PREADY=0), PENABLE MUST stay high. The master cannot drop it.
    property p_penable_wait;
        @(posedge PCLK) disable iff (!PRESETn)
        (PENABLE && !PREADY) |=> PENABLE;
    endproperty
    
    assert_penable_wait: assert property(p_penable_wait) 
        else $error("SVA ERROR: APB Protocol Violation! Master dropped PENABLE before PREADY went high.");

endmodule
