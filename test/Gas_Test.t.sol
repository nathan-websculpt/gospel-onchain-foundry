// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "./Base_Test.t.sol";

contract Gas_Test is Base_Test {    

    // forge test --mt testjsonfile
    // function testjsonfile() public virtual {
    //     // JSONVerses memory jsonVerses = _getBook("genesis");
    //     JSONVerses memory jsonVerses = _getBook("ruth");

    //     for (uint256 i = 0; i < jsonVerses.verses.length; i++) {
    //         AlphabeticalVerseStruct memory v = jsonVerses.verses[i];

    //         console2.log(
    //             // "verse: %d, chapter: %d, verseContent: %s",
    //             "verse: %d, chapter: %d, length: %d",
    //             v.VerseNumber,
    //             v.ChapterNumber,
    //             v.StringLength
    //         );
    //         // v.VerseContent,
    //     }
    // }

    // real data
    // forge test --mt testLogGasIncreasePerBatch_RealData
    // TODO: add asserts - currently just for console
    function testLogGasIncreasePerBatch_RealData() public virtual {
        bytes memory _bookId = abi.encodePacked("0x1234567890abcdef");

        uint256 scale = 10000; // for precision/fixed-point arithmetic
        uint256 oldGasUsed = 0;
        uint256 gas = gasleft();
        uint256 firstTxGas = 0;
        uint256 lastTxGas = 0;
        console2.log("initial gas: %d \n\n", gas);

        JSONVerses memory jsonVerses = _getBook("genesis");
        (uint256[] memory _verseNumbers, uint256[] memory _chapterNumbers, string[] memory _verseContent) = _makeVersesFromBook(jsonVerses);
        uint256 _len = jsonVerses.verses.length;

        for (uint256 start = 0; start < _len; start += 100) {
            uint256 end = start + 100 > _len ? _len : start + 100;
            uint256 batchSize = end - start;
            console2.log("start: %d, end: %d, batch size: %d", start, end, batchSize);

            uint256[] memory batchVerseNumbers = new uint256[](batchSize);
            uint256[] memory batchChapterNumbers = new uint256[](batchSize);
            string[] memory batchVerseContent = new string[](batchSize);

            for (uint256 j = 0; j < batchSize; j++) {
                batchVerseNumbers[j] = _verseNumbers[start + j];
                batchChapterNumbers[j] = _chapterNumbers[start + j];
                batchVerseContent[j] = _verseContent[start + j];
            }

            _manager.addBatchVerses(_bookId, batchVerseNumbers, batchChapterNumbers, batchVerseContent);

            uint256 gasUsed = gas - gasleft();

            // percentage increase = ((newVal - oldVal) / oldVal) x 100%
            if (oldGasUsed != 0) {
                if (oldGasUsed < gasUsed) {
                    uint256 diff = gasUsed - oldGasUsed;
                    uint256 scaledPercentage = (diff * scale) / oldGasUsed;

                    uint256 integerPart = scaledPercentage / 100;
                    uint256 decimalPart = scaledPercentage % 100;

                    string memory rslt = string(
                        abi.encodePacked(
                            vm.toString(integerPart), ".", decimalPart < 10 ? "0" : "", vm.toString(decimalPart), "%"
                        )
                    );
                    console2.log("gas used:", gasUsed);
                    console2.log("increase:", diff);
                    console2.log("percentage increase:", rslt);
                } else {
                    console2.log("gas used: %d \n  no increase", gasUsed);
                }
            } else {
                firstTxGas = gas - gasleft();
                console2.log("FIRST RUN, gas used: ", vm.toString(firstTxGas));
            }
            if (end == _len) lastTxGas = gasUsed; // last batch/tx 
            oldGasUsed = gasUsed;

            gas = gasleft();
            console2.log("ENDOFLOOP gasLeft: %d \n", gas);
        }

        console2.log("\n\n firstTxGas: %d \n lastTxGas: %d \n", firstTxGas, lastTxGas);

        //now log the entire increase (across all batches)
        if (lastTxGas > firstTxGas) {
            uint256 diff = lastTxGas - firstTxGas;
            uint256 scaledPercentage = (diff * scale) / firstTxGas;

            uint256 integerPart = scaledPercentage / 100;
            uint256 decimalPart = scaledPercentage % 100;

            string memory rslt = string(
                abi.encodePacked(
                    vm.toString(integerPart), ".", decimalPart < 10 ? "0" : "", vm.toString(decimalPart), "%"
                )
            );
            console2.log("\n entire % increase", rslt);
            console2.log("first tx gas", firstTxGas);
            console2.log("last tx gas: %d \n", lastTxGas);
        }        
    }
    
}