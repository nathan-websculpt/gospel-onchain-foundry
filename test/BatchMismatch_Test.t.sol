// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "./Base_Test.t.sol";

contract BatchMismatch_Test is Base_Test {

    // new
    // when the amount of chapters is different than verses
    function test_RevertsWhen_numberOfChaptersIsWrong() public virtual {
        bytes memory _bookId = abi.encodePacked("0xbookone");

        uint256[] memory _verseNumbers = new uint256[](5);
        uint256[] memory _chapterNumbers = new uint256[](4); // get amount of chapters out of whack
        string[] memory _verseContent = new string[](5);

        for (uint256 i = 0; i < 5; i++) {
            uint256 ip1 = i + 1;
            _verseNumbers[i] = ip1;
            _verseContent[i] = string(abi.encodePacked("TEST ", vm.toString(ip1)));
        }
        for (uint256 i = 0; i < 4; i++) { _chapterNumbers[i] = 1; } // handle chapters separately

        vm.expectRevert("Invalid array lengths - lengths did not match.");
        _m.addBatchVerses(_bookId, _verseNumbers, _chapterNumbers, _verseContent);
    }

    // new
    // when the amount of verse contents is different than verses
    function test_RevertsWhen_numberOfVerseContentsIsWrong() public virtual {
        bytes memory _bookId = abi.encodePacked("0xbookone");

        uint256[] memory _verseNumbers = new uint256[](5);
        uint256[] memory _chapterNumbers = new uint256[](5); 
        string[] memory _verseContent = new string[](4); // get amount of verse contents out of whack

        for (uint256 i = 0; i < 5; i++) {
            uint256 ip1 = i + 1;
            _verseNumbers[i] = ip1;
            _chapterNumbers[i] = 1;            
        }
        for (uint256 i = 0; i < 4; i++) { _verseContent[i] = "test"; } // handle verse contents separately

        vm.expectRevert("Invalid array lengths - lengths did not match.");
        _m.addBatchVerses(_bookId, _verseNumbers, _chapterNumbers, _verseContent);
    }

    
}