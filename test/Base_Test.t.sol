// SPDX-License-Idenifier: MIT

pragma solidity 0.8.28;

import {BookDeployer} from "../src/BookDeployer.sol";
import {BookManager} from "../src/BookManager.sol";
import {Test, console2, Vm} from "forge-std/Test.sol";

abstract contract Base_Test is Test {
    uint256 constant ARRAY_LEN = 20;
    BookDeployer _deployer;
    BookManager _manager;
    BookDeployer.Deployment[] _books;
    address owner;
    address alice;
    // address bob;

    function setUp() public virtual {
        owner = address(this); // The test contract is the deployer/owner.
        alice = address(0x1);
        // bob = address(0x2);
        _deployer = new BookDeployer(owner);
        _manager = new BookManager(0, "cloneable blank", owner);

        _deployBook(1, "Book One");
    }

    function testDeployBook() public virtual {
        assertEq(_books.length, 1);
    }

    function testStoreVerses() public virtual {
        BookManager _thisManager = BookManager(_books[0].bookAddress);

        bytes memory _bookId = abi.encodePacked("0x1234567890abcdef");

        (
            uint256[] memory _verseNumbers,
            uint256[] memory _chapterNumbers,
            string[] memory _verseContent
        ) = _makeVerses();

        vm.recordLogs();
        _thisManager.addBatchVerses(
            _bookId,
            _verseNumbers,
            _chapterNumbers,
            _verseContent
        );
        Vm.Log[] memory recordedLogs = vm.getRecordedLogs();
        assertEq(recordedLogs.length, ARRAY_LEN);

        for (uint256 i = 0; i < recordedLogs.length; i++) {
            // Match indexed parameters
            address signer = address(
                uint160(uint256(recordedLogs[i].topics[1]))
            );
            assertEq(signer, address(this));

            // The .data field contains the ABI-encoded values of the event's non-indexed arguments, packed together in the order they appear in the event definition
            (
                bytes memory loggedBookId,
                uint256 loggedVerseId,
                uint256 loggedVerseNumber,
                uint256 loggedChapterNumber,
                string memory loggedVerseContent
            ) = abi.decode(recordedLogs[i].data, (bytes, uint256, uint256, uint256, string));

            assertEq(loggedBookId, _bookId);
            assertEq(loggedVerseId, _verseNumbers[i]);
            assertEq(loggedVerseNumber, _verseNumbers[i]);
            assertEq(loggedChapterNumber, _chapterNumbers[i]);
            assertEq(loggedVerseContent, _verseContent[i]);
        }
    }

    function testGetLastVerseAdded() public virtual {
        _deployBook(2, "Book Two");
        BookManager _thisManager = BookManager(_books[1].bookAddress);

        bytes memory _bookId = abi.encodePacked("0x1234567890abcdef");

        (
            uint256[] memory _verseNumbers,
            uint256[] memory _chapterNumbers,
            string[] memory _verseContent
        ) = _makeVerses();

        _thisManager.addBatchVerses(
            _bookId,
            _verseNumbers,
            _chapterNumbers,
            _verseContent
        );

        BookManager.VerseStr memory lastVerseAdded = _thisManager
            .getLastVerseAdded();

        assertEq(lastVerseAdded.verseNumber, ARRAY_LEN);
        assertEq(lastVerseAdded.verseContent, "TEST 20");
    }

    function testGetVerseByNumber() public virtual {
        _deployBook(2, "Book Two");
        BookManager _thisManager = BookManager(_books[1].bookAddress);

        bytes memory _bookId = abi.encodePacked("0x1234567890abcdef");

        (
            uint256[] memory _verseNumbers,
            uint256[] memory _chapterNumbers,
            string[] memory _verseContent
        ) = _makeVerses();

        _thisManager.addBatchVerses(
            _bookId,
            _verseNumbers,
            _chapterNumbers,
            _verseContent
        );

        BookManager.VerseStr memory firstVerse = _thisManager.getVerseByNumber(
            1
        );

        assertEq(firstVerse.verseNumber, 1);
        assertEq(firstVerse.verseContent, "TEST 1");

        BookManager.VerseStr memory anotherTest = _thisManager.getVerseByNumber(
            11
        );

        assertEq(anotherTest.verseNumber, 11);
        assertEq(anotherTest.verseContent, "TEST 11");
    }

    // HELPERS

    // sets up a new book, gets all deployments afterwards
    function _deployBook(uint256 _bookId, string memory _bookName) private {
        _deployer.deployBook(_bookId, _bookName);
        _books = _deployer.getDeployments();
    }

    // returns 3 generic arrays for verse numbers, chapter numbers, and verse text-content
    function _makeVerses()
        private
        returns (uint256[] memory, uint256[] memory, string[] memory)
    {
        uint256[] memory _verseNumbers = new uint256[](ARRAY_LEN);
        uint256[] memory _chapterNumbers = new uint256[](ARRAY_LEN);
        string[] memory _verseContent = new string[](ARRAY_LEN);

        for (uint256 i = 0; i < ARRAY_LEN; i++) {
            uint256 ip1 = i + 1;
            _verseNumbers[i] = ip1;
            _chapterNumbers[i] = 1;
            _verseContent[i] = string(
                abi.encodePacked("TEST ", vm.toString(ip1))
            );
        }

        return (_verseNumbers, _chapterNumbers, _verseContent);
    }
    // END: HELPERS

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
