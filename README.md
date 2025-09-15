# UART-Integrated-16-bit-ALU-System

## Overview
This project implements a modular digital system in **VHDL** consisting of a **UART transmitter**, a **Receiver-ALU**, and a **RAM storage block**, all coordinated by a **Top Module**. The design is built around FSM-based mechanisms, parameterizable baud rate generation, and synchronous/asynchronous behavior management.  

The purpose of the system is to:
- **Serialize and transmit data** (`opcode`, `data1`, `data2`) via UART.  
- **Receive and process data** in an ALU (arithmetic/logic operations selected by `opcode`).  
- **Store results** into RAM for later retrieval.  

---

## Top Module
The **Top Module** serves as the integration layer:
- Connects the **Transmitter** output to the **Receiver-ALU** input through the `tx_rx` line.  
- Distributes control signals (`ready`, `ready_ram`) and system clock/reset.  
- Provides a unified **DataOut** output, which reflects the latest stored RAM value.  
- Implements generics for configurability:
  - `clk_frequency` (default: 100 MHz)  
  - `baudrate` (default: 19200)  
  - `depth` (RAM size, default: 128 words)  

---

## Module Breakdown

### 1. Transmitter (FSM-Based UART TX)
- **Inputs**: `opcode (2 bits)`, `data1 (8 bits)`, `data2 (8 bits)`, `ready`.  
- **Output**: `txBit` (serial data line).  
- **Operation**:
  - Concatenates inputs into an 18-bit frame.  
  - Appends **Start bit (0)** at the beginning and **Stop bit (1)** at the end.  
  - Uses **baud rate clocking**:  
    ```
    data rate = clk_frequency / baudrate
    ```
    to time each bit.  
- **FSM States**:
  - `idle`: waits for `ready`.  
  - `start`: drives start bit.  
  - `sending`: shifts data bits (LSB first).  
  - `stop`: drives stop bit before returning to idle.  

---

### 2. Receiver-ALU (FSM-Based UART RX + Processing)
- **Input**: `tx_rx` (serial data from Transmitter).  
- **Outputs**: `out_alu (16 bits)`, `ready_ram`.  
- **Operation**:
  - Detects **start bit (0)** to begin reception.  
  - Samples each incoming bit in the middle of its baud interval.  
  - Reconstructs `opcode`, `data1`, `data2`.  
  - Executes operation based on `opcode`:  

    | Opcode | Operation     |
    |--------|---------------|
    | `00`   | Concatenation |
    | `01`   | XOR           |
    | `11`   | XNOR          |
    | `10`   | AND           |

  - Produces a **16-bit result** (`out_alu`).  
  - Asserts `ready_ram` for 1 cycle when the result is valid.  

- **FSM States**:
  - `idle` → wait for start bit.  
  - `startBit` → confirm transition.  
  - `receiving` → shift in data bits.  
  - `stopBit` → validate stop bit.  
  - `arithmetic` → apply ALU operation.  

- **Configurability and Upgradability**:  
  - The ALU is designed as a **modular, opcode-driven block**, making it simple to expand.  
  - New operations can be introduced by extending the `opcode` encoding table and updating the `arithmetic` FSM state.  
  - Example future upgrades: addition, subtraction, shift/rotate operations, multiplication, or even integration with a small RISC-style instruction set.  

---

### 3. RAM (Synchronous Write, Read-Through)
- **Size**: Parameterized by `depth` (default 128).  
- **Inputs**: `inData (16 bits)`, `ready_ram`, `clk`.  
- **Outputs**: `recentData (16 bits)`.  
- **Operation**:
  - On rising edge of `clk`, if `ready_ram = '1'`, the ALU result is stored into the **next available address**.  
  - Simultaneously, `recentData` reflects the newly stored value.  
- **Reset behavior**: Clears memory and resets write pointer to 0.  

---

## Asynchronous vs. Synchronous Behavior
- **UART link (`tx_rx`)** behaves **asynchronously** relative to system logic, requiring precise baud-rate sampling.  
- **FSM control** ensures synchronization of transmission and reception, despite asynchronous data arrival.  
- **RAM writes** are fully **synchronous** to the system clock, ensuring safe storage of ALU results.  

---

## Baud Rate and Timing
- Baud rate: **19,200 bps** (default).  
- Clock frequency: **100 MHz** (default).  
- Derived **data rate** (ticks per bit):  
