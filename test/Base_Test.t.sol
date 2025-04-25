// SPDX-License-Idenifier: MIT

pragma solidity 0.8.28;

import {BookDeployer} from "../src/BookDeployer.sol";
import {Test, console2} from "forge-std/Test.sol";

abstract contract Base_Test is Test {
    BookDeployer bookDeployerContract;

    function setUp() public virtual {
        bookDeployerContract = new BookDeployerContract();
    }
}
