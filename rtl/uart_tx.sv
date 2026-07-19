module uart_tx (
    input  logic       clk,          // System clock (PCLK)
    input  logic       rst_n,        // Active-low reset
    input  logic       tx_start,     // Pulse high to start transmission
    input  logic [7:0] tx_data,      // 8-bit data to transmit
    input  logic [15:0] baud_divisor,// Clock divider value for baud rate
    
    output logic       tx_pin,       // Serial output pin
    output logic       tx_busy       // High while transmitting
);

    // FSM States
    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        START = 2'b01,
        DATA  = 2'b10,
        STOP  = 2'b11
    } tx_state_e;

    tx_state_e state, next_state;

    // Internal Registers
    logic [15:0] baud_counter;
    logic [2:0]  bit_index;      // Counts from 0 to 7
    logic [7:0]  shift_reg;
    logic        baud_tick;

    // Baud Rate Generator (Divides system clock)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_counter <= 16'd0;
            baud_tick    <= 1'b0;
        end else if (state != IDLE) begin
            if (baud_counter == baud_divisor - 1) begin
                baud_counter <= 16'd0;
                baud_tick    <= 1'b1;
            end else begin
                baud_counter <= baud_counter + 1'b1;
                baud_tick    <= 1'b0;
            end
        end else begin
            baud_counter <= 16'd0;
            baud_tick    <= 1'b0;
        end
    end

    // FSM State Register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else        state <= next_state;
    end

    // FSM Next State Logic
    always_comb begin
        next_state = state;
        case (state)
            IDLE:  if (tx_start)  next_state = START;
            START: if (baud_tick) next_state = DATA;
            DATA:  if (baud_tick && bit_index == 3'd7) next_state = STOP;
            STOP:  if (baud_tick) next_state = IDLE;
        endcase
    end

    // Datapath & Output Logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_pin    <= 1'b1; // UART idle line state is HIGH
            tx_busy   <= 1'b0;
            bit_index <= 3'd0;
            shift_reg <= 8'd0;
        end else begin
            case (state)
                IDLE: begin
                    tx_pin  <= 1'b1;
                    tx_busy <= 1'b0;
                    if (tx_start) begin
                        shift_reg <= tx_data; // Latch data
                        tx_busy   <= 1'b1;
                    end
                end

                START: begin
                    tx_pin <= 1'b0; // Start bit is LOW
                end

                DATA: begin
                    tx_pin <= shift_reg[0]; // Transmit LSB first
                    if (baud_tick) begin
                        shift_reg <= {1'b0, shift_reg[7:1]}; // Shift right
                        bit_index <= bit_index + 1'b1;
                    end
                end

                STOP: begin
                    tx_pin <= 1'b1; // Stop bit is HIGH
                    if (baud_tick) begin
                        tx_busy   <= 1'b0;
                        bit_index <= 3'd0;
                    end
                end
            endcase
        end
    end

endmodule
