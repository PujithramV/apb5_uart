# AMBA APB5-Compliant UART Bridge for Zynq-Based SoCs

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Protocol: AMBA APB5](https://img.shields.io/badge/Protocol-AMBA_APB5-orange)
![Target: Xilinx Zynq](https://img.shields.io/badge/Target-Xilinx_Zynq-green)
![Verification: Cadence Xcelium](https://img.shields.io/badge/Verification-Cadence_Xcelium-red)
![Coverage: 100%](https://img.shields.io/badge/Coverage-100%25-brightgreen)

## 📌 Project Overview
This repository contains the RTL design, verification environment, and system integration guidelines for a custom **AMBA Advanced Peripheral Bus (APB5) compliant Universal Asynchronous Receiver-Transmitter (UART) bridge**. 

Designed as a memory-mapped peripheral, this Intellectual Property (IP) facilitates reliable asynchronous serial communication for System-on-Chip (SoC) environments. It is specifically tailored for integration into the Programmable Logic (PL) of a Xilinx Zynq UltraScale+ MPSoC architecture, interfacing with the Processing System (PS) via an AXI4-Lite to APB bridge.

This project was developed during a Summer Internship Research Program at **National Institute of Technology (NIT) Goa**.

---

## ✨ Key Features
* **AMBA APB5 Protocol Compliance:** Fully supports `PADDR`, `PSEL`, `PENABLE`, `PWRITE`, `PWDATA`, and `PRDATA`, along with APB5 specific signals (`PPROT`, `PSTRB`, `PWAKEUP`).
* **Memory-Mapped Architecture:** Seamlessly interfaces with ARM Cortex processing systems via standard AXI-to-APB interconnects.
* **Configurable Baud Rate Generator:** Derives standard serial baud rates (e.g., 115200 bps) from the primary `PCLK` domain.
* **Robust Receiver FSM:** Implements a 16x oversampling architecture with middle-sample voting to mitigate clock skew and noise.
* **Vivado IP Integrator Ready:** Utilizes `X_INTERFACE_INFO` pragmas to force interface bundling for automatic addressing and connection automation in Vivado.

---

## 🏗️ System Architecture

The target architecture is a heterogeneous processing platform. To optimize routing and logic utilization, a tiered bus architecture is employed:

1. **High-Speed Domain:** The ARM processor exposes an AXI4 Master port (`M_AXI_HPM0_FPD`) to an AXI SmartConnect.
2. **Protocol Translation:** An AXI4-Lite to APB Bridge translates high-performance transactions into low-latency APB transfers.
3. **Peripheral Domain:** The custom UART acts as an APB5 slave, receiving read/write commands and driving the physical `tx_pin` and `rx_pin`.

### 🗺️ Register Map
The peripheral occupies a contiguous memory space, decoded via the 32-bit `PADDR` bus:

| Offset | Register Name | Access | Description |
| :--- | :--- | :--- | :--- |
| `0x00` | **`TX_DATA`** | Write-Only | Transmit data buffer. Writing here initiates serialization. |
| `0x04` | **`RX_DATA`** | Read-Only | Receive data buffer. Contains the latest valid received byte. |
| `0x08` | **`STATUS`** | Read-Only | Flags: `TX_READY`, `RX_VALID`, Framing/Parity `ERR`. |
| `0x0C` | **`CTRL`** | Read/Write | Baud rate configuration and core enable bits. |

---

## 🛠️ Prerequisites & Tools
* **Verification:** Cadence Xcelium (v20.09 or later), SimVision for waveform viewing.
* **Synthesis & Implementation:** Xilinx Vivado Design Suite (v2025.2.1).
* **Languages:** Verilog-2001, SystemVerilog (for testbench).

---

## 🧪 Functional Verification (Cadence Xcelium)

Rigorous functional verification was conducted using a modern SystemVerilog testbench architecture, utilizing an APB Bus Functional Model (BFM) and an asynchronous UART Monitor/Driver.

### Running the Simulation
To execute the test suite and launch the SimVision GUI, run the following command from the `/sim` directory:

```bash
xrun -sv -access +rwc ../tb/tb_top.sv ../rtl/apb5_uart_bridge_wrapper.v ../rtl/apb5_uart_bridge.v -coverage all -covoverwrite -gui
```



## Expected Output
The testbench validates register read/write integrity, loopback testing, and baud rate accuracy. The scoreboard tracks all transactions. Upon completion, the terminal will output a 100% functional coverage log:
```
[SCOREBOARD] Success at Address 0x8
[MONITOR] Time=2805 | Addr=0x0 | Wr=1 | Data=0xed3fbf80 | Strobe=0x0 | Wake=1 | Rdata=0xf602ac81 | Err=0
...
[DRIVER] Time=3045 | Addr=0x4 | Wr=1 | Data=0xa7cc2ec | Strobe=0x0 | Wake=1 | Rdata=0xx | Err=x
====================================================
 FINAL FUNCTIONAL COVERAGE: 100.00%
====================================================
    TEST OOPS ENVIRONMENT COMPLETED SUCCESSFULLY
====================================================
Simulation complete via $finish(1) at time 5 US + 0
```

## 🧩 FPGA Integration (Xilinx Vivado)
This IP is designed for immediate integration into Vivado Block Designs.
1. Add Sources: Import apb5_uart_bridge.v and apb5_uart_bridge_wrapper.v into your Vivado project.
2. Interface Pragmas: The wrapper file includes specific Xilinx pragmas that automatically bundle the discrete APB pins into a standard AMBA interface:
```
(* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 s_apb PADDR" *)   input  wire [31:0] s_apb_paddr;
(* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 s_apb PSEL" *)    input  wire s_apb_psel;
// ...
```

3. Block Design:
* Drag the wrapper into your IP Integrator canvas.
* Connect the bundled s_apb port to the APB_M port of your AXI-APB bridge.
* Make rx_pin and tx_pin external.

4. Memory Mapping: Open the Address Editor and assign a base address (e.g., 0xA0000000).



## 👨‍💻 Author & Acknowledgments
* Author: Vemana Venkata Pujithram (B.Tech ECE, Manipal Institute of Technology)
* Project Mentor: Dr. Vasantha M H (ECE Department, National Institute of Technology Goa)

This project was developed under the guidance and mentorship of the NIT Goa ECE department during the Summer Internship 2026.
