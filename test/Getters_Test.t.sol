// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "./Base_Test.t.sol";

contract Getters_Test is Base_Test {

    function testGetLastVerseAdded() public virtual {
        _deployBook(2, "Book Two");
        BookManager _thisManager = BookManager(_books[1].bookAddress);

        bytes memory _bookId = abi.encodePacked("0x1234567890abcdef");

        (uint256[] memory _verseNumbers, uint256[] memory _chapterNumbers, string[] memory _verseContent) = _makeVerses(1, ARRAY_LEN); // TODO: make ARRAY_LEN_MIN = 5 and use in places like this

        _thisManager.addBatchVerses(_bookId, _verseNumbers, _chapterNumbers, _verseContent);

        BookManager.VerseStr memory lastVerseAdded = _thisManager.getLastVerseAdded();

        assertEq(lastVerseAdded.verseNumber, ARRAY_LEN);
        assertEq(lastVerseAdded.verseContent, string(abi.encodePacked("TEST ", vm.toString(ARRAY_LEN))));
    }

    function testGetVerseByNumber() public virtual {
        _deployBook(2, "Book Two");
        BookManager _thisManager = BookManager(_books[1].bookAddress);

        bytes memory _bookId = abi.encodePacked("0x1234567890abcdef");

        (uint256[] memory _verseNumbers, uint256[] memory _chapterNumbers, string[] memory _verseContent) = _makeVerses(1, ARRAY_LEN);

        _thisManager.addBatchVerses(_bookId, _verseNumbers, _chapterNumbers, _verseContent);

        BookManager.VerseStr memory firstVerse = _thisManager.getVerseByNumber(1);

        assertEq(firstVerse.verseNumber, 1);
        assertEq(firstVerse.verseContent, "TEST 1");

        BookManager.VerseStr memory anotherTest = _thisManager.getVerseByNumber(11);

        assertEq(anotherTest.verseNumber, 11);
        assertEq(anotherTest.verseContent, "TEST 11");
    }
}