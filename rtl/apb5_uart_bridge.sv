module apb5_uart_bridge (
    // Global Signals
    input  logic        PCLK,       
    input  logic        PRESETn,    
    
    // AMBA 5 APB Signals
    input  logic [31:0] PADDR,      
    input  logic        PSEL,       
    input  logic        PENABLE,    
    input  logic        PWRITE,     
    input  logic [31:0] PWDATA,     
    input  logic [3:0]  PSTRB,      
    input  logic [2:0]  PPROT,      
    input  logic        PWAKEUP,    
    
    output logic        PREADY,     
    output logic [31:0] PRDATA,     
    output logic        PSLVERR,    
    
    // UART Physical Interface
    input  logic        rx_pin,     
    output logic        tx_pin,     
    output logic        interrupt   
);

    //--- FSM State Definitions ---
    typedef enum logic [1:0] {
        IDLE   = 2'b00,
        SETUP  = 2'b01,
        ACCESS = 2'b10
    } apb_state_e;

    apb_state_e current_state, next_state;

    //--- Register Map & Internal Signals ---
    logic [31:0] control_reg; // 0x08: [31:16]=Oversample Div, [15:0]=Baud Div
    logic [31:0] status_reg;  // 0x04: [2]=Frame Error, [1]=RX Valid, [0]=TX Busy
    logic        awake_status;

    // UART TX Connections
    logic        tx_start;
    logic [7:0]  tx_data;
    logic        tx_busy;
    
    // UART RX Connections
    logic [7:0]  rx_data;
    logic        rx_valid;
    logic        frame_error;

    // Tie Status Register to hardware flags
    assign status_reg = {29'd0, frame_error, rx_valid, tx_busy};

    // Hardware Interrupt (Triggers if valid data received or frame error occurs)
    assign interrupt = rx_valid | frame_error;

    //--- APB Bus FSM ---
    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE:   if (PSEL && PWAKEUP) next_state = SETUP;
            SETUP:  if (PENABLE)         next_state = ACCESS;
            ACCESS: if (PREADY)          next_state = PSEL ? SETUP : IDLE;
            default: next_state = IDLE;
        endcase
    end

    //--- Read/Write Logic ---
    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            PREADY       <= 1'b0;
            PRDATA       <= 32'h0;
            PSLVERR      <= 1'b0;
            control_reg  <= 32'h0;
            awake_status <= 1'b0;
            tx_start     <= 1'b0;
            tx_data      <= 8'h0;
        end else begin
            PREADY   <= 1'b0;
            PSLVERR  <= 1'b0;
            tx_start <= 1'b0; // Default to 0 so it pulses for exactly 1 clock cycle
            awake_status <= PWAKEUP;

            if (current_state == ACCESS) begin
                PREADY <= 1'b1; // Zero wait-state peripheral
                
                if (PWRITE) begin
                    case (PADDR[7:0])
                        8'h00: begin 
                            tx_data  <= PWDATA[7:0]; 
                            tx_start <= 1'b1; // Pulse high to start transmission
                        end
                        8'h08: begin
                            if (PSTRB[0]) control_reg[7:0]   <= PWDATA[7:0];
                            if (PSTRB[1]) control_reg[15:8]  <= PWDATA[15:8];
                            if (PSTRB[2]) control_reg[23:16] <= PWDATA[23:16];
                            if (PSTRB[3]) control_reg[31:24] <= PWDATA[31:24];
                        end
                        default: PSLVERR <= 1'b1;
                    endcase
                end else begin
                    case (PADDR[7:0])
                        8'h00: PRDATA <= {24'h0, rx_data}; // Read RX buffer
                        8'h04: PRDATA <= status_reg;       // Read Status
                        8'h08: PRDATA <= control_reg;      // Read Control
                        default: begin
                            PRDATA  <= 32'hDEADBEEF;
                            PSLVERR <= 1'b1;
                        end
                    endcase
                end
            end
        end
    end

    //--- Instantiate UART Transmitter ---
    uart_tx i_uart_tx (
        .clk          (PCLK),
        .rst_n        (PRESETn),
        .tx_start     (tx_start),
        .tx_data      (tx_data),
        .baud_divisor (control_reg[15:0]),
        .tx_pin       (tx_pin),
        .tx_busy      (tx_busy)
    );

    //--- Instantiate UART Receiver ---
    uart_rx i_uart_rx (
        .clk                (PCLK),
        .rst_n              (PRESETn),
        .rx_pin             (rx_pin),
        .oversample_divisor (control_reg[31:16]),
        .rx_data            (rx_data),
        .rx_valid           (rx_valid),
        .frame_error        (frame_error)
    );

endmodule
