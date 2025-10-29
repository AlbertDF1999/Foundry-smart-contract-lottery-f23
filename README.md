# Raffle Smart Contract

A decentralized raffle/lottery system built with Solidity that uses Chainlink VRF (Verifiable Random Function) for provably fair random winner selection.

## Overview

This project implements a transparent and verifiable raffle system where users can enter by paying an entrance fee, and a winner is automatically selected after a specified time interval using Chainlink's VRF v2.5 for secure randomness.

## Features

- **Provably Fair Randomness**: Uses Chainlink VRF v2.5 for verifiable random number generation
- **Automated Winner Selection**: Implements Chainlink Automation for time-based raffle execution
- **Secure State Management**: Prevents entries during winner calculation
- **Multi-Network Support**: Configured for both Sepolia testnet and local Anvil development
- **Comprehensive Testing**: Built with Foundry test suite

## Technology Stack

- **Solidity** ^0.8.19
- **Foundry** - Development framework
- **Chainlink VRF v2.5** - Random number generation
- **Chainlink Automation** - Automated upkeep functionality

## Contract Architecture

### Main Contract: `Raffle.sol`

**State Variables:**
- `i_entranceFee` - Minimum ETH required to enter the raffle
- `i_interval` - Time between raffle rounds
- `s_players` - Array of participants
- `s_raffleState` - Current state (OPEN/CALCULATING)
- `s_recentWinner` - Address of the last winner

**Key Functions:**
- `enterRaffle()` - Allows users to enter the raffle by paying the entrance fee
- `checkUpkeep()` - Checks if conditions are met to pick a winner
- `performUpkeep()` - Triggers the winner selection process
- `fulfillRandomWords()` - Callback function that selects and pays the winner

### Support Contracts

- **`DeployRaffle.s.sol`** - Deployment script
- **`HelperConfig.sol`** - Network configuration management
- **`RaffleTest.t.sol`** - Test suite

## Installation

```bash
# Clone the repository
git clone <repository-url>
cd raffle-project

# Install dependencies
forge install
```

## Configuration

### Sepolia Testnet
- Entrance Fee: 0.001 ETH
- Interval: 30 seconds
- VRF Coordinator: `0x694AA1769357215DE4FAC081bf1f309aDC325306`
- Gas Lane: `0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae`
- Callback Gas Limit: 500,000

### Local Development (Anvil)
- Uses VRFCoordinatorV2_5Mock for testing
- Entrance Fee: 0.25 ETH
- Interval: 30 seconds

## Usage

### Deploy

```bash
# Deploy to Sepolia
forge script script/DeployRaffle.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast

# Deploy locally
forge script script/DeployRaffle.s.sol --rpc-url http://localhost:8545 --broadcast
```

### Testing

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vvv
```

## How It Works

1. **Entry Phase**: Users call `enterRaffle()` with the required entrance fee
2. **Upkeep Check**: The contract continuously checks if conditions are met:
   - Sufficient time has passed (based on `i_interval`)
   - Raffle is in OPEN state
   - Contract has ETH balance
   - At least one player has entered
3. **Winner Selection**: When conditions are met, `performUpkeep()` is called, which:
   - Changes state to CALCULATING
   - Requests random number from Chainlink VRF
4. **Winner Payment**: `fulfillRandomWords()` callback:
   - Selects winner using modulo operation
   - Transfers entire balance to winner
   - Resets raffle state and player array
   - Emits `WinnerPicked` event

## Custom Errors

- `Raffle_SendEnoughEth()` - Insufficient entrance fee
- `Raffle_TransferFailed()` - ETH transfer to winner failed
- `Raffle_RaffleNotOpen()` - Raffle is calculating winner
- `Raffle_UpkeepNotNeeded()` - Conditions not met for upkeep

## Events

- `RaffleEntered(address indexed player)` - Emitted when a player enters
- `WinnerPicked(address indexed winner)` - Emitted when winner is selected

## Security Considerations

- Follows CEI (Checks-Effects-Interactions) pattern
- Uses custom errors for gas efficiency
- Prevents reentrancy through state management
- Immutable variables for gas optimization

## License

MIT

## Author

Albert Castro

---

**Note**: This is a sample project for educational purposes. Ensure proper auditing before deploying to mainnet.



## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
