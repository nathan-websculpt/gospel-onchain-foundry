// SPDX-License-Idenifier: MIT

pragma solidity 0.8.28;

import {BookDeployer} from "../src/BookDeployer.sol";
import {BookManager} from "../src/BookManager.sol";
import {Test, console2} from "forge-std/Test.sol";

abstract contract Base_Test is Test {
    BookDeployer bookDeployerContract;
    BookManager bookManagerContract;
    address owner;
    address alice;
    // address bob;

    function setUp() public virtual {
        owner = address(this); // The test contract is the deployer/owner.
        alice = address(0x1);
        // bob = address(0x2);
        bookDeployerContract = new BookDeployer(owner);
        bookManagerContract = new BookManager(0, "cloneable blank", owner);
        // bookManagerContract = new BookManager(0, "cloneable blank", address(bookDeployerContract));
    }

    function testCanDeployBook() public virtual {
        bookDeployerContract.deployBook(1, "Test One");

        BookDeployer.Deployment[] memory deployments = bookDeployerContract.getDeployments();

        console2.log(deployments.length);

        // vm.expectEmit(true, false, false, true);
        // emit Book(address(bookDeployerContract), 1, "Test One");
    }
}
