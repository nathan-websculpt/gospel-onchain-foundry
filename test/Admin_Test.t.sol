// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "./Base_Test.t.sol";

contract Admin_Test is Base_Test {

    function testDeployerOwnershipTransfer() public virtual {
        assertEq(_deployer.owner(), owner);
        _deployer.transferOwnership(alice);
        assertEq(_deployer.owner(), alice);

        // should revert when old owner makes a book
        vm.expectRevert();
        _deployBook(2, "Book Two");

        // make sure alice can deploy a book
        vm.prank(alice);
        _deployBook(2, "Book Two");
        assertEq(_books.length, 2);
    }

    function testManagerOwnershipTransfer() public virtual {
        assertEq(_m.owner(), owner);
        _m.transferOwnership(alice);
        assertEq(_m.owner(), alice);

        // set up some verses
        bytes memory _bookId = abi.encodePacked("0x1234567890abcdef");

        (uint256[] memory _verseNumbers, uint256[] memory _chapterNumbers, string[] memory _verseContent) =_makeVerses(1, ARRAY_LEN);

        // should revert when old owner stores verses
        vm.expectRevert();
        _m.addBatchVerses(_bookId, _verseNumbers, _chapterNumbers, _verseContent);

        // make sure alice can store verses
        vm.prank(alice);
        _m.addBatchVerses(_bookId, _verseNumbers, _chapterNumbers, _verseContent);

        // make sure that ONLY Alice's verses are stored
        assertEq(_m.numberOfVerses(), ARRAY_LEN);
    }

    function testDeployBook() public virtual {
        assertEq(_books.length, 1); // TODO: add a few more
    }

    function testOnlyOwnerCanDeployNewBook() public virtual {
        vm.startPrank(alice);
        vm.expectRevert();
        _deployer.deployBook(2, "test");
        vm.stopPrank();
    }

    function testOnlyOwnerCanStoreVerses() public virtual {
        bytes memory _bookId = abi.encodePacked("0x1234567890abcdef");
        (uint256[] memory _verseNumbers, uint256[] memory _chapterNumbers, string[] memory _verseContent) = _makeVerses(1, ARRAY_LEN);

        vm.startPrank(alice);
        vm.expectRevert();
        _m.addBatchVerses(_bookId, _verseNumbers, _chapterNumbers, _verseContent);
        vm.stopPrank();
    }

    function testFinalizeBook() public virtual {
        bytes memory _bookId = abi.encodePacked("0x1234567890abcdef"); //only for subgraph
        vm.expectEmit(true, true, true, true);
        emit BookManager.Finalization(address(this), _bookId);
        _m.finalizeBook(_bookId);
    }

    function testOnlyOwnerCanFinalizeBook() public virtual {
        bytes memory _bookId = abi.encodePacked("0x1234567890abcdef"); //only for subgraph
        assertEq(_m.owner(), owner);
        _m.transferOwnership(alice);
        assertEq(_m.owner(), alice);

        // make sure old owner can't finalize book
        vm.expectRevert();
        _m.finalizeBook(_bookId);

        // make sure new owner can finalize book
        vm.startPrank(alice);
        vm.expectEmit(true, true, true, true);
        emit BookManager.Finalization(alice, _bookId);
        _m.finalizeBook(_bookId);
        vm.stopPrank();
    }
}