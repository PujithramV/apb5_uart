interface apb5_uart_if (input bit PCLK, input bit PRESETn);

    // --- AMBA 5 APB Signals ---
    logic [31:0] PADDR;
    logic        PSEL;
    logic        PENABLE;
    logic        PWRITE;
    logic [31:0] PWDATA;
    logic [3:0]  PSTRB;
    logic [2:0]  PPROT;
    logic        PWAKEUP;
    logic        PREADY;
    logic [31:0] PRDATA;
    logic        PSLVERR;

    // --- UART Physical Signals ---
    logic        rx_pin;
    logic        tx_pin;
    logic        interrupt;

    // --- Clocking Block for Driver (Master Component) ---
    // Inputs are sampled 1ns before the edge; outputs are driven 1ns after
    clocking drv_cb @(posedge PCLK);
        default input #1ns output #1ns;
        output PADDR, PSEL, PENABLE, PWRITE, PWDATA, PSTRB, PPROT, PWAKEUP;
        input  PREADY, PRDATA, PSLVERR;
        output rx_pin;
        input  tx_pin, interrupt;
    endclocking

    // --- Clocking Block for Monitor (Passive Component) ---
    clocking mon_cb @(posedge PCLK);
        default input #1ns output #1ns;
        input PADDR, PSEL, PENABLE, PWRITE, PWDATA, PSTRB, PPROT, PWAKEUP;
        input PREADY, PRDATA, PSLVERR;
        input rx_pin, tx_pin, interrupt;
    endclocking

    // --- Modports to restrict access rights ---
    modport DRIVER  (clocking drv_cb, input PRESETn);
    modport MONITOR (clocking mon_cb, input PRESETn);

endinterface
