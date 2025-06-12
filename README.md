#### Notes

Useful for viewing test coverage

```bash
# html coverage report
forge coverage --ir-minimum --report lcov
genhtml lcov.info --output-directory coverage-html

# html coverage branches report
genhtml lcov.info -o report --branch-coverage --rc derive_function_end_line=0 --output-directory coverage-branches-html

```

Viewing coverage html:
- Blue Highlighted Line = Not relevant for coverage (not executable code).
- Red Highlighted Line  = Code not executed at all during tests.
- Blue +                = Not executable, for reference only.
- Red ++                = Uncovered branch (a logical path was never executed in tests).


## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

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
