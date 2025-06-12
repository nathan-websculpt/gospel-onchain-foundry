// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "./Base_Test.t.sol";

contract Verses_Test is Base_Test {

    function testStoreVerses() public virtual {
        bytes memory _bookId = abi.encodePacked("0x1234567890abcdef");
        (uint256[] memory _verseNumbers, uint256[] memory _chapterNumbers, string[] memory _verseContent) = _makeVerses(1, ARRAY_LEN); // chapter 1

        vm.recordLogs();
        _m.addBatchVerses(_bookId, _verseNumbers, _chapterNumbers, _verseContent);
        Vm.Log[] memory recordedLogs = vm.getRecordedLogs();
        assertEq(recordedLogs.length, ARRAY_LEN);

        for (uint256 i = 0; i < recordedLogs.length; i++) {
            address signer = address(uint160(uint256(recordedLogs[i].topics[1])));
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

    function testStoreVerses_inMultipleBooks() public virtual {
        _deployBook(2, "Book Two");
        _deployBook(3, "Book Three");
        BookManager _b1Manager = BookManager(_books[0].bookAddress);
        BookManager _b2Manager = BookManager(_books[1].bookAddress);
        BookManager _b3Manager = BookManager(_books[2].bookAddress);

        // At the end of the day, _bookId is only for the subgraph
        bytes memory _b1Id = abi.encodePacked("0xbookone");
        bytes memory _b2Id = abi.encodePacked("0xbooktwo");
        bytes memory _b3Id = abi.encodePacked("0xbookthree");

        //Book One's verses (same as in other tests [100 items])
        (uint256[] memory _verseNumbers, uint256[] memory _chapterNumbers, string[] memory _verseContent) = _makeVerses(1, ARRAY_LEN);

        //Book Two's verses [5 items]
        (uint256[] memory _b2verseNumbers, uint256[] memory _b2chapterNumbers, string[] memory _b2verseContent) = _makeVerses(1, 5);

        //Book Three's verses [5 items]
        (uint256[] memory _b3verseNumbers, uint256[] memory _b3chapterNumbers, string[] memory _b3verseContent) = _makeVerses(1, 5);

        vm.recordLogs();
        _b1Manager.addBatchVerses(_b1Id, _verseNumbers, _chapterNumbers, _verseContent);
        _b2Manager.addBatchVerses(_b2Id, _b2verseNumbers, _b2chapterNumbers, _b2verseContent);
        _b3Manager.addBatchVerses(_b3Id, _b3verseNumbers, _b3chapterNumbers, _b3verseContent);
        Vm.Log[] memory recordedLogs = vm.getRecordedLogs();
        assertEq(recordedLogs.length, 110);

        for (uint256 i = 0; i < 110; i++) {
            // The .data field contains the ABI-encoded values of the event's non-indexed arguments, packed together in the order they appear in the event definition
            (
                bytes memory loggedBookId,
                uint256 loggedVerseId,
                uint256 loggedVerseNumber,
                uint256 loggedChapterNumber,
                string memory loggedVerseContent
            ) = abi.decode(recordedLogs[i].data, (bytes, uint256, uint256, uint256, string));

            // TODO: check titles?
            if (i < ARRAY_LEN) {
                //book one
                assertEq(loggedBookId, _b1Id);
                assertEq(loggedVerseId, _verseNumbers[i]);
                assertEq(loggedVerseNumber, _verseNumbers[i]);
                assertEq(loggedChapterNumber, _chapterNumbers[i]);
                assertEq(loggedVerseContent, _verseContent[i]);
            } else if (i < 105) {
                //book two
                assertEq(loggedBookId, _b2Id);
                assertEq(loggedVerseId, _b2verseNumbers[i - ARRAY_LEN]);
                assertEq(loggedVerseNumber, _b2verseNumbers[i - ARRAY_LEN]);
                assertEq(loggedChapterNumber, _b2chapterNumbers[i - ARRAY_LEN]);
                assertEq(loggedVerseContent, _b2verseContent[i - ARRAY_LEN]);
            } else {
                // book three
                assertEq(loggedBookId, _b3Id);
                assertEq(loggedVerseId, _b3verseNumbers[i - 105]);
                assertEq(loggedVerseNumber, _b3verseNumbers[i - 105]);
                assertEq(loggedChapterNumber, _b3chapterNumbers[i - 105]);
                assertEq(loggedVerseContent, _b3verseContent[i - 105]);
            }
        }
    }

    function test_RevertWhen_storeVerseAfterFinalization() public virtual {
        bytes memory _bookId = abi.encodePacked("0x1234567890abcdef"); //only for subgraph
        _m.finalizeBook(_bookId);

        // now try to add verses to this finalized book (should fail)

        (uint256[] memory _verseNumbers, uint256[] memory _chapterNumbers, string[] memory _verseContent) = _makeVerses(1, ARRAY_LEN);

        vm.expectRevert("This contract has already been finalized.");
        _m.addBatchVerses(_bookId, _verseNumbers, _chapterNumbers, _verseContent);
    }
}