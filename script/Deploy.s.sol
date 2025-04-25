// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import "../src/BookDeployer.sol";
import "../src/BookManager.sol";

// TODO: later
contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        BookDeployer bookDeployer = new BookDeployer(address(this));
        BookManager bookManager = new BookManager(0, "clone", address(this));
        
        console.log("sdfsfsasf deployed at:", address(bookDeployer));
        
        vm.stopBroadcast();
    }
}