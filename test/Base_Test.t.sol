// SPDX-License-Idenifier: MIT

// forge coverage --ir-minimum
// forge coverage --ir-minimum --report debug
// forge coverage --ir-minimum --report debug > coverage.txt

pragma solidity 0.8.28;

import {BookDeployer} from "../src/BookDeployer.sol";
import {BookManager} from "../src/BookManager.sol";
import {DeployScript} from "../script/Deploy.s.sol";
import {Test, console2, Vm} from "forge-std/Test.sol";

// TODO: tests for ownership misuse
// TODO: tests empty verses/content?

abstract contract Base_Test is Test {
    DeployScript deployer = new DeployScript();

    uint256 constant ARRAY_LEN = 100;
    BookDeployer _deployer;
    BookManager _manager;
    BookDeployer.Deployment[] _books;
    address owner;
    address alice;
    address bob;
    string constant titleOne = "Genesis";
    string constant titleTwo = "Exodus";
    string constant titleThree = "Leviticus";

    // vm.parseJson - json data is decoded into struct fields aplphabetically
    struct AlphabeticalVerseStruct {
        uint256 ChapterNumber;
        string FullVerseChapter;
        uint256 StringLength;
        string VerseContent;
        uint256 VerseNumber;
    }

    struct JSONVerses {
        AlphabeticalVerseStruct[] verses;
    }

    function setUp() public virtual {
        owner = address(this); // The test contract is the deployer/owner.
        alice = address(0x1);
        bob = address(0x2);

        //use deployer
        // (_deployer, _manager) = deployer.run();

        _deployer = new BookDeployer(owner);
        _manager = new BookManager(0, "cloneable blank", owner);

        _deployBook(1, "Book One");
    }

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
        BookManager _thisManager = BookManager(_books[0].bookAddress);
        assertEq(_thisManager.owner(), owner);
        _thisManager.transferOwnership(alice);
        assertEq(_thisManager.owner(), alice);

        // set up some verses
        bytes memory _bookId = abi.encodePacked("0x1234567890abcdef");

        (uint256[] memory _verseNumbers, uint256[] memory _chapterNumbers, string[] memory _verseContent) =
            _makeVerses(1);

        // should revert when old owner stores verses
        vm.expectRevert();
        _thisManager.addBatchVerses(_bookId, _verseNumbers, _chapterNumbers, _verseContent);

        // make sure alice can store verses
        vm.prank(alice);
        _thisManager.addBatchVerses(_bookId, _verseNumbers, _chapterNumbers, _verseContent);

        // make sure that ONLY Alice's verses are stored
        assertEq(_thisManager.numberOfVerses(), ARRAY_LEN);
    }

    function testDeployBook() public virtual {
        assertEq(_books.length, 1);
    }

    function testOnlyOwnerCanDeployNewBook() public virtual {
        vm.startPrank(alice);
        vm.expectRevert();
        _deployer.deployBook(2, "test");
        vm.stopPrank();
    }

    function testStoreVerses() public virtual {
        BookManager _thisManager = BookManager(_books[0].bookAddress);

        // At the end of the day, _bookId is only for the subgraph
        bytes memory _bookId = abi.encodePacked("0x1234567890abcdef");

        (uint256[] memory _verseNumbers, uint256[] memory _chapterNumbers, string[] memory _verseContent) =
            _makeVerses(1);

        vm.recordLogs();
        _thisManager.addBatchVerses(_bookId, _verseNumbers, _chapterNumbers, _verseContent);
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

        //Book One's verses (same as in other tests [20 items])
        (uint256[] memory _verseNumbers, uint256[] memory _chapterNumbers, string[] memory _verseContent) =
            _makeVerses(1);

        //Book Two's verses [5 items]
        uint256[] memory _b2verseNumbers = new uint256[](5);
        uint256[] memory _b2chapterNumbers = new uint256[](5);
        string[] memory _b2verseContent = new string[](5);

        for (uint256 i = 0; i < 5; i++) {
            uint256 ip1 = i + 1;
            _b2verseNumbers[i] = ip1;
            _b2chapterNumbers[i] = 1;
            _b2verseContent[i] = string(abi.encodePacked("Book Two ", vm.toString(ip1)));
        }

        //Book Three's verses [5 items]
        uint256[] memory _b3verseNumbers = new uint256[](5);
        uint256[] memory _b3chapterNumbers = new uint256[](5);
        string[] memory _b3verseContent = new string[](5);

        for (uint256 i = 0; i < 5; i++) {
            uint256 ip1 = i + 1;
            _b3verseNumbers[i] = ip1;
            _b3chapterNumbers[i] = 1;
            _b3verseContent[i] = string(abi.encodePacked("Book Three ", vm.toString(ip1)));
        }

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

            if (i < ARRAY_LEN) {
                //book one [20 items]
                assertEq(loggedBookId, _b1Id);
                assertEq(loggedVerseId, _verseNumbers[i]);
                assertEq(loggedVerseNumber, _verseNumbers[i]);
                assertEq(loggedChapterNumber, _chapterNumbers[i]);
                assertEq(loggedVerseContent, _verseContent[i]);
            } else if (i < 105) {
                //book two [5 items]
                assertEq(loggedBookId, _b2Id);
                assertEq(loggedVerseId, _b2verseNumbers[i - ARRAY_LEN]);
                assertEq(loggedVerseNumber, _b2verseNumbers[i - ARRAY_LEN]);
                assertEq(loggedChapterNumber, _b2chapterNumbers[i - ARRAY_LEN]);
                assertEq(loggedVerseContent, _b2verseContent[i - ARRAY_LEN]);
            } else {
                // book three [5 items]
                assertEq(loggedBookId, _b3Id);
                assertEq(loggedVerseId, _b3verseNumbers[i - 105]);
                assertEq(loggedVerseNumber, _b3verseNumbers[i - 105]);
                assertEq(loggedChapterNumber, _b3chapterNumbers[i - 105]);
                assertEq(loggedVerseContent, _b3verseContent[i - 105]);
            }
        }
    }

    function testOnlyOwnerCanStoreVerses() public virtual {
        BookManager _thisManager = BookManager(_books[0].bookAddress);

        // At the end of the day, _bookId is only for the subgraph
        bytes memory _bookId = abi.encodePacked("0x1234567890abcdef");

        (uint256[] memory _verseNumbers, uint256[] memory _chapterNumbers, string[] memory _verseContent) =
            _makeVerses(1);

        vm.startPrank(alice);
        vm.expectRevert();
        _thisManager.addBatchVerses(_bookId, _verseNumbers, _chapterNumbers, _verseContent);
        vm.stopPrank();
    }

    function testGetLastVerseAdded() public virtual {
        _deployBook(2, "Book Two");
        BookManager _thisManager = BookManager(_books[1].bookAddress);

        bytes memory _bookId = abi.encodePacked("0x1234567890abcdef");

        (uint256[] memory _verseNumbers, uint256[] memory _chapterNumbers, string[] memory _verseContent) =
            _makeVerses(1);

        _thisManager.addBatchVerses(_bookId, _verseNumbers, _chapterNumbers, _verseContent);

        BookManager.VerseStr memory lastVerseAdded = _thisManager.getLastVerseAdded();

        assertEq(lastVerseAdded.verseNumber, ARRAY_LEN);
        assertEq(lastVerseAdded.verseContent, string(abi.encodePacked("TEST ", vm.toString(ARRAY_LEN))));
    }

    function testGetVerseByNumber() public virtual {
        _deployBook(2, "Book Two");
        BookManager _thisManager = BookManager(_books[1].bookAddress);

        bytes memory _bookId = abi.encodePacked("0x1234567890abcdef");

        (uint256[] memory _verseNumbers, uint256[] memory _chapterNumbers, string[] memory _verseContent) =
            _makeVerses(1);

        _thisManager.addBatchVerses(_bookId, _verseNumbers, _chapterNumbers, _verseContent);

        BookManager.VerseStr memory firstVerse = _thisManager.getVerseByNumber(1);

        assertEq(firstVerse.verseNumber, 1);
        assertEq(firstVerse.verseContent, "TEST 1");

        BookManager.VerseStr memory anotherTest = _thisManager.getVerseByNumber(11);

        assertEq(anotherTest.verseNumber, 11);
        assertEq(anotherTest.verseContent, "TEST 11");
    }

    function testConfirmVerses() public virtual {
        BookManager _thisManager = BookManager(_books[0].bookAddress);

        bytes memory _bookId = abi.encodePacked("0x1234567890abcdef");

        (uint256[] memory _verseNumbers, uint256[] memory _chapterNumbers, string[] memory _verseContent) =
            _makeVerses(1);

        vm.recordLogs();
        _thisManager.addBatchVerses(_bookId, _verseNumbers, _chapterNumbers, _verseContent);
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
            _thisManager.confirmVerse(_verseBytesId, loggedVerseId);
            vm.stopPrank();

            // now test a second confirmation by Bob
            vm.startPrank(bob);
            vm.expectEmit(true, true, true, true);
            emit BookManager.Confirmation(bob, _verseBytesId);
            _thisManager.confirmVerse(_verseBytesId, loggedVerseId);
            vm.stopPrank();
        }
    }

    function testFinalizeBook() public virtual {
        bytes memory _bookId = abi.encodePacked("0x1234567890abcdef"); //only for subgraph
        BookManager _thisManager = BookManager(_books[0].bookAddress);
        vm.expectEmit(true, true, true, true);
        emit BookManager.Finalization(address(this), _bookId);
        _thisManager.finalizeBook(_bookId);
    }

    function testOnlyOwnerCanFinalizeBook() public virtual {
        bytes memory _bookId = abi.encodePacked("0x1234567890abcdef"); //only for subgraph
        BookManager _thisManager = BookManager(_books[0].bookAddress);
        assertEq(_thisManager.owner(), owner);
        _thisManager.transferOwnership(alice);
        assertEq(_thisManager.owner(), alice);

        // make sure old owner can't finalize book
        vm.expectRevert();
        _thisManager.finalizeBook(_bookId);

        // make sure new owner can finalize book
        vm.startPrank(alice);
        vm.expectEmit(true, true, true, true);
        emit BookManager.Finalization(alice, _bookId);
        _thisManager.finalizeBook(_bookId);
        vm.stopPrank();
    }

    function test_RevertWhen_storeVerseAfterFinalization() public virtual {
        bytes memory _bookId = abi.encodePacked("0x1234567890abcdef"); //only for subgraph
        BookManager _thisManager = BookManager(_books[0].bookAddress);
        _thisManager.finalizeBook(_bookId);

        // now try to add verses to this finalized book (should fail)

        (uint256[] memory _verseNumbers, uint256[] memory _chapterNumbers, string[] memory _verseContent) =
            _makeVerses(1);

        vm.expectRevert("This contract has already been finalized.");
        _thisManager.addBatchVerses(_bookId, _verseNumbers, _chapterNumbers, _verseContent);
    }

    function test_RevertsWhen_samePersonConfirmsVerseTwice() public virtual {
        BookManager _thisManager = BookManager(_books[0].bookAddress);

        bytes memory _bookId = abi.encodePacked("0x1234567890abcdef");

        (uint256[] memory _verseNumbers, uint256[] memory _chapterNumbers, string[] memory _verseContent) =
            _makeVerses(1);

        vm.recordLogs();
        _thisManager.addBatchVerses(_bookId, _verseNumbers, _chapterNumbers, _verseContent);
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
            _thisManager.confirmVerse(_verseBytesId, loggedVerseId);

            vm.expectRevert("This address has already confirmed this verse.");
            _thisManager.confirmVerse(_verseBytesId, loggedVerseId);
            vm.stopPrank();
        }
    }

    // VERSE/CHAPTER ORDER ENFORCEMENT

    // The contract's functionality is expecting all within the batch to be consecutive; however, the prevention occurs based on the last added to the previous batch
    function test_RevertsWhen_skippingVerseNumber() public virtual {
        BookManager _thisManager = BookManager(_books[0].bookAddress);

        // At the end of the day, _bookId is only for the subgraph
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
        _thisManager.addBatchVerses(_bookId, _verseNumbers, _chapterNumbers, _verseContent);

        //store second batch (which will start with a skipped verse, and revert)
        uint256[] memory _batch2verseNumbers = new uint256[](5);
        uint256[] memory _batch2chapterNumbers = new uint256[](5);
        string[] memory _batch2verseContent = new string[](5);

        for (uint256 i = 0; i < 5; i++) {
            uint256 ip1 = i + 7; //will get the verse number out of whack (skipping a verse)
            _batch2verseNumbers[i] = ip1;
            _batch2chapterNumbers[i] = 1;
            _batch2verseContent[i] = string(abi.encodePacked("TEST ", vm.toString(ip1)));
        }

        vm.expectRevert("The contract is preventing you from skipping a verse.");
        _thisManager.addBatchVerses(_bookId, _batch2verseNumbers, _batch2chapterNumbers, _batch2verseContent);
    }

    function test_RevertsWhen_skippingChapterNumber() public virtual {
        BookManager _thisManager = BookManager(_books[0].bookAddress);

        // At the end of the day, _bookId is only for the subgraph
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
        _thisManager.addBatchVerses(_bookId, _verseNumbers, _chapterNumbers, _verseContent);

        //store second batch (which will start with a skipped verse, and revert)
        uint256[] memory _batch2verseNumbers = new uint256[](5);
        uint256[] memory _batch2chapterNumbers = new uint256[](5);
        string[] memory _batch2verseContent = new string[](5);

        for (uint256 i = 0; i < 5; i++) {
            uint256 ip1 = i + 1;
            _batch2verseNumbers[i] = ip1;
            _batch2chapterNumbers[i] = 3; //will get the chapter number out of whack (skipping a chapter)
            _batch2verseContent[i] = string(abi.encodePacked("TEST ", vm.toString(ip1)));
        }

        vm.expectRevert("The contract is preventing you from skipping a chapter.");
        _thisManager.addBatchVerses(_bookId, _batch2verseNumbers, _batch2chapterNumbers, _batch2verseContent);
    }

    function test_RevertsWhen_skippingFirstVerseOfBible() public virtual {
        BookManager _thisManager = BookManager(_books[0].bookAddress);

        // At the end of the day, _bookId is only for the subgraph
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
        _thisManager.addBatchVerses(_bookId, _verseNumbers, _chapterNumbers, _verseContent);
    }

    function test_RevertsWhen_skippingFirstChapterOfBible() public virtual {
        BookManager _thisManager = BookManager(_books[0].bookAddress);

        // At the end of the day, _bookId is only for the subgraph
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
        _thisManager.addBatchVerses(_bookId, _verseNumbers, _chapterNumbers, _verseContent);
    }

    function test_RevertsWhen_skippingFirstVerseOfNewChapter() public virtual {
        BookManager _thisManager = BookManager(_books[0].bookAddress);

        // At the end of the day, _bookId is only for the subgraph
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
        _thisManager.addBatchVerses(_bookId, _verseNumbers, _chapterNumbers, _verseContent);

        //store second batch (which will start with a skipped verse, and revert)
        uint256[] memory _batch2verseNumbers = new uint256[](5);
        uint256[] memory _batch2chapterNumbers = new uint256[](5);
        string[] memory _batch2verseContent = new string[](5);

        for (uint256 i = 0; i < 5; i++) {
            uint256 ip1 = i + 2; // starts a new chapter off on verse 2, which should revert
            _batch2verseNumbers[i] = ip1;
            _batch2chapterNumbers[i] = 2;
            _batch2verseContent[i] = string(abi.encodePacked("TEST ", vm.toString(ip1)));
        }

        vm.expectRevert("The contract is preventing you from starting a new chapter with a verse that is not 1.");
        _thisManager.addBatchVerses(_bookId, _batch2verseNumbers, _batch2chapterNumbers, _batch2verseContent);
    }
    // END: VERSE/CHAPTER ORDER ENFORCEMENT

    // HELPERS

    // sets up a new book, gets all deployments afterwards
    function _deployBook(uint256 _bookId, string memory _bookName) private {
        _deployer.deployBook(_bookId, _bookName);
        _books = _deployer.getDeployments();
    }

    // mock data
    // returns 3 generic arrays for verse numbers, chapter numbers, and verse text-content
    function _makeVerses(uint256 chapterNumber) private returns (uint256[] memory, uint256[] memory, string[] memory) {
        uint256[] memory _verseNumbers = new uint256[](ARRAY_LEN);
        uint256[] memory _chapterNumbers = new uint256[](ARRAY_LEN);
        string[] memory _verseContent = new string[](ARRAY_LEN);

        for (uint256 i = 0; i < ARRAY_LEN; i++) {
            uint256 ip1 = i + 1;
            _verseNumbers[i] = ip1;
            _chapterNumbers[i] = chapterNumber;
            _verseContent[i] = string(abi.encodePacked("TEST ", vm.toString(ip1)));
        }

        return (_verseNumbers, _chapterNumbers, _verseContent);
    }

    // real data
    // takes an array (jsonVerses.verses) and breaks it up...
    // returns 3 arrays for verse numbers, chapter numbers, and verse text-content
    function _makeVersesFromBook(JSONVerses memory _jsonVerses) private returns (uint256[] memory, uint256[] memory, string[] memory) {
        uint256 _len = _jsonVerses.verses.length;
        uint256[] memory _verseNumbers = new uint256[](_len);
        uint256[] memory _chapterNumbers = new uint256[](_len);
        string[] memory _verseContent = new string[](_len);
        for (uint256 i = 0; i < _len; i++) {
            _verseNumbers[i] = _jsonVerses.verses[i].VerseNumber;
            _chapterNumbers[i] = _jsonVerses.verses[i].ChapterNumber;
            _verseContent[i] = _jsonVerses.verses[i].VerseContent;
        }

        return (_verseNumbers, _chapterNumbers, _verseContent);
    }

    // real data
    // returns an array of structs (representing verses) for the provided book title
    function _getBook(string memory _bookName) private returns (JSONVerses memory) {
        string memory root = vm.projectRoot();
        string memory fileName = string.concat(_bookName, ".json");
        string memory path = string.concat("/test/json/json_bible/", fileName);
        string memory fullpath = string.concat(root, path);
        string memory json = vm.readFile(fullpath);
        bytes memory data = vm.parseJson(json);
        JSONVerses memory jsonVerses = abi.decode(data, (JSONVerses));
        return jsonVerses;
    }

    // END: HELPERS
}
