# Test Organization

This test suite contains **465 tests** organized by functionality and network dependency.

## Quick Start

```bash
# Load environment variables
source .env  # or: export CELO="..." && export ETH="..."

# Run all tests (fast dev profile)
./bin/test

# Run only Ethereum fork tests
./bin/test --match-path "src/test/oracles/Chainlink*.sol" \
  --match-path "src/test/oracles/Convex*.sol" \
  --match-path "src/test/oracles/Crab*.sol" \
  --match-path "src/test/oracles/RETH*.sol" \
  --match-path "src/test/oracles/Strategy*.sol" \
  --match-path "src/test/oracles/Uniswap*.sol" \
  --match-path "src/test/oracles/YieldSpace*.sol" \
  --match-path "src/test/modules/*.sol" \
  --match-path "src/test/other/notional/*.sol"

# Run only Celo fork tests
./bin/test --match-path "src/test/oracles/VariableIR*.sol" \
  --match-path "src/test/other/tether/*.sol"
```

## Test Categories

### ⛓️ Ethereum Mainnet Fork Tests (11 files)
**Requires**: `ETH` environment variable pointing to Ethereum mainnet RPC with archive access

**Oracle Tests** (`src/test/oracles/`):
- `ChainlinkUSDMultiOracle.t.sol` - Chainlink USD price feeds
- `ConvexOracle.t.sol` - Curve/Convex 3CRV oracle
- `CrabOracle.t.sol` - Crab Strategy (Squeeth) oracle
- `RETHOracle.t.sol` - Rocket Pool rETH oracle
- `StrategyOracle.t.sol` - Yield Strategy oracle
- `UniswapOracle.t.sol` - Uniswap V3 oracle
- `YieldSpaceMultiOracle.dai.it.t.sol` - YieldSpace DAI integration
- `YieldSpaceMultiOracle.usdc.it.t.sol` - YieldSpace USDC integration

**Module Tests** (`src/test/modules/`):
- `HealerModule.t.sol` - Vault healing module
- `RepayFromLadleModule.t.sol` - Repayment module

**Integration Tests** (`src/test/other/notional/`):
- `NotionalJoin.t.sol` - Notional Finance integration

### 🌴 Celo Mainnet Fork Tests (2 files)
**Requires**: `CELO` environment variable pointing to Celo mainnet RPC with archive access

- `src/test/oracles/VariableIROracle.t.sol` - Variable interest rate oracle
- `src/test/other/tether/TetherJoin.t.sol` - Tether join adapter

### 🧪 Network-Agnostic Tests (~75 files)
**No RPC required** - Pure unit tests

**Variable Rate Protocol** (`src/test/variable/`):
- `VRCauldron.t.sol` - Variable rate cauldron (vault system)
- `VRLadle.t.sol` - Variable rate ladle (router/builder)
- `VRWitch.t.sol` - Variable rate witch (liquidations)
- `VYToken.t.sol` - Variable rate yield tokens

**Fixed-Yield Tokens** (`src/test/fyToken/`):
- `FYToken.t.sol` - Fixed-yield token core
- `FYTokenFlash.t.sol` - Flash loan functionality

**Join Contracts** (`src/test/join/`):
- `Join.t.sol` - Standard join adapter
- `FlashJoin.t.sol` - Flash-mintable join

**Oracle Tests** (`src/test/oracles/`):
- `MentoSpotOracle.t.sol` - Mento spot price oracle (Celo)
- `LidoOracle.t.sol` - Lido stETH/wstETH oracle
- `ChainlinkMultiOracle.t.sol` - Chainlink multi-oracle
- `CompositeMultiOracle.t.sol` - Composite oracle paths
- `CompoundMultiOracle.t.sol` - Compound cToken oracle
- `CTokenMultiOracle.t.sol` - Generic cToken oracle
- `ETokenMultiOracle.t.sol` - EToken oracle
- `IdentityOracle.t.sol` - 1:1 oracle
- `NotionalMultiOracle.t.sol` - Notional oracle
- `YearnVaultMultiOracle.t.sol` - Yearn vault oracle
- `YieldSpaceMultiOracle.t.sol` - YieldSpace oracle (unit tests)

**Liquidations** (`src/test/`):
- `Witch.t.sol` - Fixed-rate liquidation engine

**Other** (`src/test/other/`):
- `contango/ContangoLadle.t.sol` - Contango integration
- `notional/NotionalJoinHarness.t.sol` - Notional test harness

## Running Tests

### All Tests
```bash
source .env
./bin/test
```

### By Category
```bash
# Variable rate tests only
./bin/test --match-path "src/test/variable/*.sol"

# Oracle tests only
./bin/test --match-path "src/test/oracles/*.sol"

# FYToken tests only
./bin/test --match-path "src/test/fyToken/*.sol"
```

### By Network Requirement
```bash
# Ethereum-dependent tests
./bin/test --match-path "src/test/oracles/Chainlink*.sol"

# Celo-dependent tests
./bin/test --match-path "src/test/oracles/VariableIR*.sol"

# No RPC needed
./bin/test --match-path "src/test/variable/*.sol"
```

### Specific Test
```bash
./bin/test --match-contract RETHOracleTest --match-test testPeek -vvv
```

## Environment Setup

Create `.env` file:
```bash
ETH=https://eth-mainnet.g.alchemy.com/v2/YOUR_ETH_API_KEY
CELO=https://celo-mainnet.g.alchemy.com/v2/YOUR_CELO_API_KEY
```

**Note**: Archive node access required for fork tests at historical blocks.

## Forge Profiles

| Profile | via_ir | optimizer | Compilation | Use Case |
|---------|--------|-----------|-------------|----------|
| default | ✅ true | ✅ true | ~120s+ | Production builds, releases |
| dev | ❌ false | ❌ false | ~1-2s | **Development, testing** |

**Recommendation**: Use `./bin/test` (defaults to the dev profile) to avoid 100x slower compilation. Set `FOUNDRY_PROFILE=default` if you need production-like builds.

## Test Statistics

- **Total Tests**: 465
- **Ethereum Fork**: 11 files
- **Celo Fork**: 2 files
- **Network-Agnostic**: ~75 files
- **Compilation (dev)**: 1-2 seconds
- **Compilation (default)**: 120+ seconds ⚠️

## Common Issues

### `environment variable 'ETH' not found`
**Solution**: Load `.env` file before running tests:
```bash
source .env
```

### `block is out of range`
**Solution**: Your RPC endpoint doesn't have archive access. Use Alchemy, Infura Growth plan, or QuickNode.

### Tests timeout after 120s
**Solution**: Use the dev profile:
```bash
./bin/test
```

## Network-Specific Test Details

### Ethereum Tests - Block Numbers
- ChainlinkUSDMultiOracle: 15044600
- ConvexOracle: 15044600
- CrabOracle: 15974678
- RETHOracle: 16384773
- StrategyOracle: 15917726
- UniswapOracle: 15044600
- YieldSpace (DAI): 15313316
- YieldSpace (USDC): 15313316
- NotionalJoin: 16017869
- HealerModule: 15266900
- RepayFromLadleModule: 15266900

### Celo Tests - Block Numbers
- VariableIROracle: Uses CELO fork
- TetherJoin: Uses CELO fork

## Contributing

When adding new tests:
1. **Use network-agnostic tests when possible** - Faster, no RPC needed
2. **If forking required**: Clearly comment which network and why
3. **Update this README** with new test categories
4. **Use ChainHelpers.isCelo()** to skip Ethereum tests on Celo
