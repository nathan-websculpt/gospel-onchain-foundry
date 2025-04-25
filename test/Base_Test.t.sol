// SPDX-License-Idenifier: MIT

pragma solidity 0.8.28;

import {BookDeployer} from "../src/BookDeployer.sol";
import {BookManager} from "../src/BookManager.sol";
import {Test, console2} from "forge-std/Test.sol";

abstract contract Base_Test is Test {
    BookDeployer _deployer;
    BookManager _manager;
    address owner;
    address alice;
    // address bob;

    function setUp() public virtual {
        owner = address(this); // The test contract is the deployer/owner.
        alice = address(0x1);
        // bob = address(0x2);
        _deployer = new BookDeployer(owner);
        _manager = new BookManager(0, "cloneable blank", owner);
    }

    function testDeployBook() public virtual {
        _deployer.deployBook(1, "Book One");

        BookDeployer.Deployment[] memory deployments = _deployer.getDeployments();

        assertEq(deployments.length, 1);
    }

    function testStoreVerses() public virtual {
        uint256 ARRAY_LEN = 10;
        _deployer.deployBook(1, "Book One");

        BookDeployer.Deployment[] memory deployments = _deployer.getDeployments();


        uint256[] memory _verseNumbers = new uint256[](ARRAY_LEN);
        uint256[] memory _chapterNumbers = new uint256[](ARRAY_LEN);
        string[] memory _verseContent = new string[](ARRAY_LEN);

        for (uint256 i = 0; i < ARRAY_LEN; i++) {
            uint256 ip1 = i + 1;
            _verseNumbers[i] = ip1;
            _chapterNumbers[i] = 1;
            _verseContent[i] = string(abi.encodePacked("TEST ", vm.toString(ip1)));
        }

        bytes memory _bookId = abi.encodePacked("0x1234567890abcdef");

        _manager.addBatchVerses(_bookId, _verseNumbers, _chapterNumbers, _verseContent);

        BookManager.VerseStr memory lastVerseAdded = _manager.getLastVerseAdded();

        assertEq(lastVerseAdded.verseNumber, ARRAY_LEN);
        assertEq(lastVerseAdded.verseContent, "TEST 10");
    }

    function testGetLastVerseAdded() public virtual {
        uint256 ARRAY_LEN = 30;
        _deployer.deployBook(1, "Book One");

        BookDeployer.Deployment[] memory deployments = _deployer.getDeployments();


        uint256[] memory _verseNumbers = new uint256[](ARRAY_LEN);
        uint256[] memory _chapterNumbers = new uint256[](ARRAY_LEN);
        string[] memory _verseContent = new string[](ARRAY_LEN);

        for (uint256 i = 0; i < ARRAY_LEN; i++) {
            uint256 ip1 = i + 1;
            _verseNumbers[i] = ip1;
            _chapterNumbers[i] = 1;
            _verseContent[i] = string(abi.encodePacked("TEST ", vm.toString(ip1)));
        }

        bytes memory _bookId = abi.encodePacked("0x1234567890abcdef");

        _manager.addBatchVerses(_bookId, _verseNumbers, _chapterNumbers, _verseContent);

        BookManager.VerseStr memory lastVerseAdded = _manager.getLastVerseAdded();

        assertEq(lastVerseAdded.verseNumber, ARRAY_LEN);
        assertEq(lastVerseAdded.verseContent, "TEST 30");
    }

    function testGetVerseByNumber() public virtual {
        uint256 ARRAY_LEN = 20;
        _deployer.deployBook(1, "Book One");

        BookDeployer.Deployment[] memory deployments = _deployer.getDeployments();


        uint256[] memory _verseNumbers = new uint256[](ARRAY_LEN);
        uint256[] memory _chapterNumbers = new uint256[](ARRAY_LEN);
        string[] memory _verseContent = new string[](ARRAY_LEN);

        for (uint256 i = 0; i < ARRAY_LEN; i++) {
            uint256 ip1 = i + 1;
            _verseNumbers[i] = ip1;
            _chapterNumbers[i] = 1;
            _verseContent[i] = string(abi.encodePacked("TEST ", vm.toString(ip1)));
        }

        bytes memory _bookId = abi.encodePacked("0x1234567890abcdef");

        _manager.addBatchVerses(_bookId, _verseNumbers, _chapterNumbers, _verseContent);

        BookManager.VerseStr memory firstVerse = _manager.getVerseByNumber(1);

        assertEq(firstVerse.verseNumber, 1);
        assertEq(firstVerse.verseContent, "TEST 1");

        BookManager.VerseStr memory anotherTest = _manager.getVerseByNumber(11);

        assertEq(anotherTest.verseNumber, 11);
        assertEq(anotherTest.verseContent, "TEST 11");
    }

    // tests:
    //          confirmVerse
    //          finalizeBook
    //          
    //          PRIVATES:
    //                      preventSkippingVerse
    //                      preventSkippingChapter
    //                      enforceFirstVerseOfNewChapter
    //                      enforceFirstVerse
}
