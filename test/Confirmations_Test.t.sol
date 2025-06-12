// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "./Base_Test.t.sol";

contract Confirmations_Test is Base_Test {

    function testConfirmVerses() public virtual {
        bytes memory _bookId = abi.encodePacked("0x1234567890abcdef");

        (uint256[] memory _verseNumbers, uint256[] memory _chapterNumbers, string[] memory _verseContent) = _makeVerses(1, ARRAY_LEN);

        vm.recordLogs();
        _m.addBatchVerses(_bookId, _verseNumbers, _chapterNumbers, _verseContent);
        Vm.Log[] memory recordedLogs = vm.getRecordedLogs();

        for (uint256 i = 0; i < recordedLogs.length; i++) {
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

            // this verse ID bytes array is just for the subgraph
            bytes memory _verseBytesId = abi.encodePacked("0xverse", vm.toString(i + 1));

            // now test a confirmation by Alice
            vm.startPrank(alice);
            vm.expectEmit(true, true, true, true);
            emit BookManager.Confirmation(alice, _verseBytesId);
            _m.confirmVerse(_verseBytesId, loggedVerseId);
            vm.stopPrank();

            // now test a second confirmation by Bob
            vm.startPrank(bob);
            vm.expectEmit(true, true, true, true);
            emit BookManager.Confirmation(bob, _verseBytesId);
            _m.confirmVerse(_verseBytesId, loggedVerseId);
            vm.stopPrank();
        }
    }

    function test_RevertsWhen_samePersonConfirmsVerseTwice() public virtual {
        bytes memory _bookId = abi.encodePacked("0x1234567890abcdef");
        (uint256[] memory _verseNumbers, uint256[] memory _chapterNumbers, string[] memory _verseContent) = _makeVerses(1, ARRAY_LEN);

        vm.recordLogs();
        _m.addBatchVerses(_bookId, _verseNumbers, _chapterNumbers, _verseContent);
        Vm.Log[] memory recordedLogs = vm.getRecordedLogs();

        for (uint256 i = 0; i < recordedLogs.length; i++) {
            // The .data field contains the ABI-encoded values of the event's non-indexed arguments, packed together in the order they appear in the event definition
            (
                bytes memory loggedBookId,
                uint256 loggedVerseId,
                uint256 loggedVerseNumber,
                uint256 loggedChapterNumber,
                string memory loggedVerseContent
            ) = abi.decode(recordedLogs[i].data, (bytes, uint256, uint256, uint256, string));

            // this verse ID bytes array is just for the subgraph
            bytes memory _verseBytesId = abi.encodePacked("0xverse", vm.toString(i + 1));

            // now test a confirmation
            vm.startPrank(alice);
            vm.expectEmit(true, true, true, true);
            emit BookManager.Confirmation(alice, _verseBytesId);
            _m.confirmVerse(_verseBytesId, loggedVerseId);

            vm.expectRevert("This address has already confirmed this verse.");
            _m.confirmVerse(_verseBytesId, loggedVerseId);
            vm.stopPrank();
        }
    }
}