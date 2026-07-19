module uart_rx (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        rx_pin,
    input  logic [15:0] oversample_divisor, // Generates a tick at 16x the baud rate

    output logic [7:0]  rx_data,
    output logic        rx_valid,
    output logic        frame_error   // High if stop bit is not detected
);

    // FSM States
    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        START = 2'b01,
        DATA  = 2'b10,
        STOP  = 2'b11
    } rx_state_e;

    rx_state_e state, next_state;

    // Internal Registers
    logic [15:0] tick_counter;
    logic        oversample_tick;
    logic [3:0]  sample_counter; // Counts 0 to 15 (the 16x oversampling ticks)
    logic [2:0]  bit_index;      // Counts data bits 0 to 7
    logic [7:0]  shift_reg;

    // 16x Baud Rate Generator
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tick_counter    <= 16'd0;
            oversample_tick <= 1'b0;
        end else begin
            if (tick_counter == oversample_divisor - 1) begin
                tick_counter    <= 16'd0;
                oversample_tick <= 1'b1;
            end else begin
                tick_counter    <= tick_counter + 1'b1;
                oversample_tick <= 1'b0;
            end
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
            IDLE: begin
                // Detect falling edge of start bit
                if (~rx_pin) next_state = START; 
            end
            START: begin
                if (oversample_tick) begin
                    if (sample_counter == 4'd7) begin // Wait to middle of start bit
                        if (~rx_pin) next_state = DATA; // Valid start bit
                        else         next_state = IDLE; // Glitch, go back
                    end
                end
            end
            DATA: begin
                if (oversample_tick && sample_counter == 4'd15) begin
                    if (bit_index == 3'd7) next_state = STOP;
                end
            end
            STOP: begin
                if (oversample_tick && sample_counter == 4'd15) begin
                    next_state = IDLE;
                end
            end
        endcase
    end

    // Datapath Logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_counter <= 4'd0;
            bit_index      <= 3'd0;
            shift_reg      <= 8'd0;
            rx_data        <= 8'd0;
            rx_valid       <= 1'b0;
            frame_error    <= 1'b0;
        end else begin
            // Default pulse signals
            rx_valid <= 1'b0; 

            case (state)
                IDLE: begin
                    sample_counter <= 4'd0;
                    bit_index      <= 3'd0;
                end

                START: begin
                    if (oversample_tick) begin
                        if (sample_counter == 4'd7) begin
                            sample_counter <= 4'd0; // Reset counter for the data bits
                        end else begin
                            sample_counter <= sample_counter + 1'b1;
                        end
                    end
                end

                DATA: begin
                    if (oversample_tick) begin
                        sample_counter <= sample_counter + 1'b1;
                        if (sample_counter == 4'd15) begin
                            // We are perfectly in the middle of the data bit! Sample it.
                            shift_reg <= {rx_pin, shift_reg[7:1]};
                            bit_index <= bit_index + 1'b1;
                        end
                    end
                end

                STOP: begin
                    if (oversample_tick) begin
                        sample_counter <= sample_counter + 1'b1;
                        if (sample_counter == 4'd15) begin
                            // Middle of stop bit. Should be HIGH.
                            if (rx_pin) begin
                                rx_data     <= shift_reg; // Push valid data out
                                rx_valid    <= 1'b1;
                                frame_error <= 1'b0;
                            end else begin
                                frame_error <= 1'b1; // Stop bit was low? Frame error!
                            end
                        end
                    end
                end
            endcase
        end
    end

endmodule
