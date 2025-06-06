// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import "../src/BookDeployer.sol";
import "../src/BookManager.sol";
import {BookDeployer} from "../src/BookDeployer.sol";
import {BookManager} from "../src/BookManager.sol";

// anvil
// forge script script/Deploy.s.sol:DeployScript --rpc-url http://127.0.0.1:8545 --private-key <> --broadcast
contract DeployScript is Script {
    uint256 public DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    function setUp() public {}

    function run() public returns (BookDeployer, BookManager) {
        uint256 deployerPrivateKey = DEFAULT_ANVIL_PRIVATE_KEY;
        vm.startBroadcast(deployerPrivateKey);

        BookDeployer bookDeployer = new BookDeployer(address(this));
        BookManager bookManager = new BookManager(0, "clone", address(this));
        vm.stopBroadcast();
        return (bookDeployer, bookManager);
    }
}
