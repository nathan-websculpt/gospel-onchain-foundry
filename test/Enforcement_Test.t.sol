// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "./Base_Test.t.sol";

contract Enforcement_Test is Base_Test {

    // VERSE/CHAPTER ORDER ENFORCEMENT

    // The contract's functionality is expecting all within the batch to be consecutive; however, the prevention occurs based on the last added to the previous batch
    function test_RevertsWhen_skippingVerseNumber() public virtual {
        // At the end of the day, _bookId is only for the subgraph
        bytes memory _bookId = abi.encodePacked("0xbookone");

        //store first batch
        (uint256[] memory _verseNumbers, uint256[] memory _chapterNumbers, string[] memory _verseContent) = provideBatchTuple(5);

        for (uint256 i = 0; i < 5; i++) {
            uint256 ip1 = i + 1;
            _verseNumbers[i] = ip1;
            _chapterNumbers[i] = 1;
            _verseContent[i] = string(abi.encodePacked("TEST ", vm.toString(ip1)));
        }
        _m.addBatchVerses(_bookId, _verseNumbers, _chapterNumbers, _verseContent);

        //store second batch (which will start with a skipped verse, and revert)
        (uint256[] memory _b2verseNumbers, uint256[] memory _b2chapterNumbers, string[] memory _b2verseContent) = provideBatchTuple(5);

        for (uint256 i = 0; i < 5; i++) {
            uint256 ip1 = i + 7; //will get the verse number out of whack (skipping a verse)
            _b2verseNumbers[i] = ip1;
            _b2chapterNumbers[i] = 1;
            _b2verseContent[i] = string(abi.encodePacked("TEST ", vm.toString(ip1)));
        }

        vm.expectRevert("The contract is preventing you from skipping a verse.");
        _m.addBatchVerses(_bookId, _b2verseNumbers, _b2chapterNumbers, _b2verseContent);
    }

    function test_RevertsWhen_skippingChapterNumber() public virtual {
        // At the end of the day, _bookId is only for the subgraph
        bytes memory _bookId = abi.encodePacked("0xbookone");

        //store first batch
        (uint256[] memory _verseNumbers, uint256[] memory _chapterNumbers, string[] memory _verseContent) = provideBatchTuple(5);

        for (uint256 i = 0; i < 5; i++) {
            uint256 ip1 = i + 1;
            _verseNumbers[i] = ip1;
            _chapterNumbers[i] = 1;
            _verseContent[i] = string(abi.encodePacked("TEST ", vm.toString(ip1)));
        }
        _m.addBatchVerses(_bookId, _verseNumbers, _chapterNumbers, _verseContent);

        //store second batch (which will start with a skipped chapter, and revert)
        (uint256[] memory _b2verseNumbers, uint256[] memory _b2chapterNumbers, string[] memory _b2verseContent) = provideBatchTuple(5);

        for (uint256 i = 0; i < 5; i++) {
            uint256 ip1 = i + 1;
            _b2verseNumbers[i] = ip1;
            _b2chapterNumbers[i] = 3; //will get the chapter number out of whack (skipping a chapter)
            _b2verseContent[i] = string(abi.encodePacked("TEST ", vm.toString(ip1)));
        }

        vm.expectRevert("The contract is preventing you from skipping a chapter.");
        _m.addBatchVerses(_bookId, _b2verseNumbers, _b2chapterNumbers, _b2verseContent);
    }

    function test_RevertsWhen_skippingFirstVerseOfBible() public virtual {
        bytes memory _bookId = abi.encodePacked("0xbookone");

        //store first batch
        uint256[] memory _verseNumbers = new uint256[](5);
        uint256[] memory _chapterNumbers = new uint256[](5);
        string[] memory _verseContent = new string[](5);

        for (uint256 i = 0; i < 5; i++) {
            uint256 ip1 = i + 2; // like starting with Genesis 1:2
            _verseNumbers[i] = ip1;
            _chapterNumbers[i] = 1;
            _verseContent[i] = string(abi.encodePacked("TEST ", vm.toString(ip1)));
        }

        vm.expectRevert("The contract is preventing you from starting with a verse that is not 1:1");
        _m.addBatchVerses(_bookId, _verseNumbers, _chapterNumbers, _verseContent);
    }

    function test_RevertsWhen_skippingFirstChapterOfBible() public virtual {
        bytes memory _bookId = abi.encodePacked("0xbookone");

        //store first batch
        uint256[] memory _verseNumbers = new uint256[](5);
        uint256[] memory _chapterNumbers = new uint256[](5);
        string[] memory _verseContent = new string[](5);

        for (uint256 i = 0; i < 5; i++) {
            uint256 ip1 = i + 1;
            _verseNumbers[i] = ip1;
            _chapterNumbers[i] = 2; // like starting with Genesis 2:1
            _verseContent[i] = string(abi.encodePacked("TEST ", vm.toString(ip1)));
        }

        vm.expectRevert("The contract is preventing you from starting with a verse that is not 1:1");
        _m.addBatchVerses(_bookId, _verseNumbers, _chapterNumbers, _verseContent);
    }

    function test_RevertsWhen_skippingFirstVerseOfNewChapter() public virtual {
        bytes memory _bookId = abi.encodePacked("0xbookone");

        //store first batch
        uint256[] memory _verseNumbers = new uint256[](5);
        uint256[] memory _chapterNumbers = new uint256[](5);
        string[] memory _verseContent = new string[](5);

        for (uint256 i = 0; i < 5; i++) {
            uint256 ip1 = i + 1;
            _verseNumbers[i] = ip1;
            _chapterNumbers[i] = 1;
            _verseContent[i] = string(abi.encodePacked("TEST ", vm.toString(ip1)));
        }
        _m.addBatchVerses(_bookId, _verseNumbers, _chapterNumbers, _verseContent);

        //store second batch (which will start with a skipped verse, and revert)
        uint256[] memory _b2verseNumbers = new uint256[](5);
        uint256[] memory _b2chapterNumbers = new uint256[](5);
        string[] memory _b2verseContent = new string[](5);

        for (uint256 i = 0; i < 5; i++) {
            uint256 ip1 = i + 2; // starts a new chapter off on verse 2, which should revert
            _b2verseNumbers[i] = ip1;
            _b2chapterNumbers[i] = 2;
            _b2verseContent[i] = string(abi.encodePacked("TEST ", vm.toString(ip1)));
        }

        vm.expectRevert("The contract is preventing you from starting a new chapter with a verse that is not 1.");
        _m.addBatchVerses(_bookId, _b2verseNumbers, _b2chapterNumbers, _b2verseContent);
    }
    // END: VERSE/CHAPTER ORDER ENFORCEMENT






    // new
    // specifically testing the bool return of preventSkippingChapter()
    // to appease branch-coverage
    function test_ContinuesWhen_notSkippingChapter() public virtual {
        bytes memory _bookId = abi.encodePacked("0xbookone");

        //make first batch
        (uint256[] memory _verseNumbers, uint256[] memory _chapterNumbers, string[] memory _verseContent) = provideBatchTuple(5);

        for (uint256 i = 0; i < 5; i++) {
            uint256 ip1 = i + 1;
            _verseNumbers[i] = ip1;
            _chapterNumbers[i] = 1;
            _verseContent[i] = string(abi.encodePacked("TEST ", vm.toString(ip1)));
        }

        // store first batch
        vm.recordLogs();
        _m.addBatchVerses(_bookId, _verseNumbers, _chapterNumbers, _verseContent);

        //store second batch (which will NOT skip a chapter, and NOT revert)
        (uint256[] memory _b2verseNumbers, uint256[] memory _b2chapterNumbers, string[] memory _b2verseContent) = provideBatchTuple(5);

        for (uint256 i = 0; i < 5; i++) {
            uint256 ip1 = i + 6;
            _b2verseNumbers[i] = ip1;
            _b2chapterNumbers[i] = 1;           // SAME CHAPTER AS ABOVE, FIRST BATCH
            _b2verseContent[i] = string(abi.encodePacked("TEST ", vm.toString(ip1)));
        }

        _m.addBatchVerses(_bookId, _b2verseNumbers, _b2chapterNumbers, _b2verseContent);

        Vm.Log[] memory recordedLogs = vm.getRecordedLogs();
        assertEq(recordedLogs.length, 10);

        for (uint256 i = 0; i < 10; i++) {
            // The .data field contains the ABI-encoded values of the event's non-indexed arguments, packed together in the order they appear in the event definition
            (
                bytes memory loggedBookId,
                uint256 loggedVerseId,
                uint256 loggedVerseNumber,
                uint256 loggedChapterNumber,
                string memory loggedVerseContent
            ) = abi.decode(recordedLogs[i].data, (bytes, uint256, uint256, uint256, string));

            if (i < 5) {
                //chapter one [5 items]
                assertEq(loggedBookId, _bookId);
                assertEq(loggedVerseId, _verseNumbers[i]);
                assertEq(loggedVerseNumber, _verseNumbers[i]);
                assertEq(loggedChapterNumber, _chapterNumbers[i]);
                assertEq(loggedVerseContent, _verseContent[i]);
            } else {
                //chapter two [5 items]
                assertEq(loggedBookId, _bookId);
                assertEq(loggedVerseId, _b2verseNumbers[i - 5]);
                assertEq(loggedVerseNumber, _b2verseNumbers[i - 5]);
                assertEq(loggedChapterNumber, _b2chapterNumbers[i - 5]);
                assertEq(loggedVerseContent, _b2verseContent[i - 5]);
            }
        }
    }
}