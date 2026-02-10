# FPGA-Based Temperature and Light Intensity Measurement using UART

A Verilog HDL–based FPGA project that measures temperature and light intensity data and transmits it reliably using the **UART communication protocol**. The design implements a complete synchronous digital data pipeline and is fully verified using Xilinx Vivado.

---

## 🔍 Project Overview

The system acquires parallel sensor data, serializes it using a UART transmitter, recovers it using a UART receiver, and prepares it for display via an LCD driver. A central top module manages timing, sequencing, and data flow.

**Data Flow:**

- System Clock: **50 MHz**
- UART Baud Rate: **9600 bps**
- Update Cycle: **100 ms**

---

## ⚙️ Key Features

- Modular FPGA-based design using Verilog HDL  
- FSM-based UART TX/RX implementation  
- Center-sampling UART receiver for noise immunity  
- Time-Division Multiplexing of temperature and light data  
- Synthesis-ready and FPGA deployable  
- Fully verified using Vivado simulation  

---

## 🧩 Modules

- `adc_interface.v` – Synchronizes sensor inputs  
- `uart_tx.v` – Serializes 8-bit data at 9600 baud  
- `uart_rx.v` – Recovers serial data using center sampling  
- `lcd_driver.v` – Generates LCD control signals  
- `top_module.v` – Controls timing and data sequencing  
- `top_module_tb.v` – Testbench for verification  

---

## 🧪 Verification

- Behavioral simulation in **Xilinx Vivado**
- Verified UART frame structure (Start, Data, Stop)
- Correct bit timing (~104 µs per bit)
- Successful end-to-end transmission of test data (`0x41`)
- Total system cycle time ≈ **102 ms**

RTL, synthesis, and implementation schematics are available in the `docs/` folder.

---

## 🚀 Applications

- FPGA-based environmental monitoring  
- Smart agriculture and storage systems  
- UART protocol learning and verification  
