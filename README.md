# Design and Verification of AXI4-Lite Master and Slave

## Project Overview

This project implements and verifies an **AXI4-Lite Master and Slave** system using SystemVerilog.

The AXI4-Lite slave is connected to an internal memory, allowing the master to perform read and write transactions through the AXI4-Lite interface.

The project covers both:
- RTL design of the AXI4-Lite Master and Slave
- Functional verification using a SystemVerilog-based verification environment

## Objectives

- Understand the AMBA AXI4-Lite protocol
- Design an AXI4-Lite Master
- Design an AXI4-Lite Slave
- Interface the slave with a memory
- Implement independent AXI read and write channels
- Verify AXI transactions using a testbench
- Check protocol behavior using assertions
- Measure functional coverage

## AXI4-Lite Architecture

```text
                 +----------------------+
                 |    Testbench / TB    |
                 |                      |
                 | Generator            |
                 | Driver               |
                 | Monitor              |
                 | Scoreboard            |
                 | Coverage             |
                 +----------+-----------+
                            |
                            v
                 +----------------------+
                 |    AXI4-Lite Master  |
                 +----------+-----------+
                            |
             AXI4-Lite Interface / Bus
                            |
                            v
                 +----------------------+
                 |    AXI4-Lite Slave   |
                 +----------+-----------+
                            |
                            v
                 +----------------------+
                 |        Memory        |
                 +----------------------+
```

## AXI4-Lite Channels

AXI4-Lite contains five independent channels:

### Write Channels

1. **Write Address Channel**
   - `AWVALID`
   - `AWREADY`
   - `AWADDR`

2. **Write Data Channel**
   - `WVALID`
   - `WREADY`
   - `WDATA`
   - `WSTRB`

3. **Write Response Channel**
   - `BVALID`
   - `BREADY`
   - `BRESP`

### Read Channels

4. **Read Address Channel**
   - `ARVALID`
   - `ARREADY`
   - `ARADDR`

5. **Read Data Channel**
   - `RVALID`
   - `RREADY`
   - `RDATA`
   - `RRESP`

## Project Structure

```text
.
├── axi_bus_if.sv
├── axi_if.sv
├── axi_master.sv
├── axi_pkg.sv
├── axi_system_top.sv
├── axi_transaction.sv
├── axi_assertion.sv
├── coverage.sv
├── driver.sv
├── environment.sv
├── generator.sv
├── memory.sv
├── monitor.sv
├── read_fsm.sv
├── scoreboard.sv
├── slave_top.sv
├── tb_top.sv
├── test.sv
├── write_fsm.sv
│
├── Presentation/
│   └── G3_Design and verification of axi4 lite master and slave_ppt.pptx
│
└── Reports/
    └── coverage report.txt
```

## RTL Design

### AXI4-Lite Master

The master controls AXI4-Lite transactions and contains separate read and write control logic.

The write path handles:
- Write address transfer
- Write data transfer
- Write response
- Write completion

The read path handles:
- Read address transfer
- Read data reception
- Read response
- Read completion

### AXI4-Lite Slave

The slave accepts AXI4-Lite read and write transactions from the master.

The slave:
- Captures write address and write data
- Performs memory writes using `WSTRB`
- Generates write responses
- Accepts read addresses
- Reads data from memory
- Generates read responses

### Memory

The slave uses a synchronous memory with:

- 32-bit data width
- 64 memory locations
- Byte write enable using `WSTRB`
- Address indexing suitable for 32-bit aligned accesses

For 64 memory locations:

```text
log2(64) = 6 address bits
```

For 32-bit data, each word contains 4 bytes, so the lower two address bits select the byte position. For word-aligned accesses, these two bits are `00`.

Therefore, the memory index can be obtained using:

```text
AXI address[7:2]
```

## Verification Environment

The verification environment contains:

```text
Generator
    |
    v
 Driver
    |
    v
 AXI Master
    |
    v
 AXI Slave
    |
    v
 Memory
```

The monitor observes AXI transactions and sends them to the scoreboard.

The scoreboard compares the observed results against expected results maintained in a reference memory.

## Verification Components

### Transaction

`axi_transaction.sv`

Defines the transaction-level representation of AXI read and write operations.

### Generator

`generator.sv`

Generates different read and write scenarios, including randomized transactions.

### Driver

`driver.sv`

Transfers generated transactions toward the master control interface.

### Monitor

`monitor.sv`

Observes the AXI4-Lite bus and reconstructs read and write transactions.

### Scoreboard

`scoreboard.sv`

Maintains a reference memory and compares expected and actual transaction results.

### Coverage

`coverage.sv`

Collects functional coverage for important transaction combinations and scenarios.

### Assertions

`axi_assertion.sv`

Contains SystemVerilog assertions for checking important AXI4-Lite protocol and reset behavior.

## Verification Scenarios

The verification environment can test scenarios such as:

- Basic write transaction
- Basic read transaction
- Multiple consecutive writes
- Multiple consecutive reads
- Alternating read and write transactions
- Same-address accesses
- Random addresses
- Random write strobes
- Invalid address accesses
- Reset behavior
- AXI handshake behavior
- Read-after-write operation
- Write response checking
- Read response checking

## Responses

AXI4-Lite response signals are used to indicate transaction status.

### Write Response

`BRESP` provides the write response.

### Read Response

`RRESP` provides the read response.

Typical response values include:

```text
00 -> OKAY
10 -> SLVERR
```

## Tools

The project can be simulated using SystemVerilog-compatible simulators and developed using FPGA/EDA tools such as:

- AMD Vivado
- XSim
- QuestaSim
- Riviera-PRO
- EDA Playground

## Project Deliverables

The repository contains:

- AXI4-Lite RTL design files
- SystemVerilog verification environment
- AXI protocol assertions
- Functional coverage
- Project presentation
- Project report
- Coverage report

## Authors

**Group G3**

Project: **Design and Verification of AXI4-Lite Master and Slave**

## Conclusion

This project demonstrates the design and verification of an AXI4-Lite Master and Slave system with a memory-based AXI4-Lite Slave. The verification environment uses transaction generation, monitoring, scoreboard checking, functional coverage, and assertions to validate the design behavior.
