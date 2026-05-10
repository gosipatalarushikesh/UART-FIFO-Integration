# UART with TX & RX FIFO Integration

A complete synthesizable UART controller with separate Transmit and Receive FIFOs, implemented in Verilog.

## Features

- Configurable Baud Rate Generator (50 MHz → 9600 baud with 16x oversampling)
- TX FIFO (Depth: 16) – Buffers data from host processor
- RX FIFO (Depth: 16) – Buffers received serial data
- Standard 8N1 UART protocol (1 Start bit, 8 Data bits LSB first, 1 Stop bit)
- Reusable synchronous FIFO module
- Modular and clean design
- Fully synthesizable

## Repository Structure

```bash
uart-fifo-integration/
├── README.md
├── LICENSE                  # (Optional)
│
├── src/                     # RTL Source Files
│   ├── baud_rate_generator.v
│   ├── uart_tx.v
│   ├── uart_rx.v
│   ├── fifo.v
│   └── uart_top.v
│
├── tb/                      # Testbenches
│   ├── tb_baud_rate_generator.v
│   ├── tb_uart_tx.v
│   ├── tb_uart_rx.v
│   └── tb_fifo.v
│
├── sim/                     # Simulation Results
│   └── waveforms/           # Waveform screenshots (to be added)
│
└── docs/                    # Documentation
    ├── block_diagram.drawio
    └── architecture.md

## Modules Overview

| Module                    | Description |
|---------------------------|-----------|
| `baud_rate_generator`     | Generates `tx_enb` and `rx_enb` (16x oversampling) |
| `fifo`                    | Reusable synchronous FIFO (used for both TX & RX) |
| `uart_tx`                 | Serializes data from TX FIFO |
| `uart_rx`                 | Deserializes incoming data + pushes to RX FIFO |
| `uart_top`                | Top-level integration module |

## Simulation Status

- Individual module testbenches **completed and passing**
- Full system loopback testbench → To be added
- Waveform screenshots → To be added

## How to Simulate

1. Open [EDA Playground](https://www.edaplayground.com/)
2. Add all files from `src/` folder
3. Choose the desired testbench file
4. Run simulation

## Tools Used

- **Language**: Verilog
- **Simulator**: EDA Playground / Icarus Verilog
- **Editor**: VS Code

## Learning Outcomes

- FIFO design and circular buffering
- UART protocol implementation
- 16x oversampling technique
- Proper handshaking between modules
- Professional testbench development

## Future Improvements

- Programmable baud rate
- Parity bit support
- Error detection (framing, overrun)
- AXI4-Lite interface
- FPGA board testing

---

**Project by:** G Rushikesh
**Date:** May 2026
