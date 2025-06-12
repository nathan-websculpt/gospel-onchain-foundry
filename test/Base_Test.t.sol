// SPDX-License-Idenifier: MIT

// forge coverage --ir-minimum
// forge coverage --ir-minimum --report debug
// forge coverage --ir-minimum --report debug > coverage.txt

// html coverage report
// forge coverage --ir-minimum --report lcov
// genhtml lcov.info --output-directory coverage-html

// html coverage branches report
// genhtml lcov.info -o report --branch-coverage --rc derive_function_end_line=0 --output-directory coverage-branches-html

// in coverage html: 
//                  Blue Highlighted Line = Not relevant for coverage (not executable code).
//                  Red Highlighted Line  = Code not executed at all during tests.
//                  Blue +                = Not executable, for reference only.
//                  Red ++                = Uncovered branch (a logical path was never executed in tests).
//                                              usually appears next to a conditional where one or more possible execution paths have not been tested



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
    BookManager _m;
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

        _m = BookManager(_books[0].bookAddress);
    }

    // HELPERS

    // sets up a new book, gets all deployments afterwards
    function _deployBook(uint256 _bookId, string memory _bookName) internal {
        _deployer.deployBook(_bookId, _bookName);
        _books = _deployer.getDeployments();
    }

    // mock data
    // returns 3 generic arrays for verse numbers, chapter numbers, and verse text-content
    function _makeVerses(uint256 chapterNumber, uint256 len) internal returns (uint256[] memory, uint256[] memory, string[] memory) {
        uint256[] memory _verseNumbers = new uint256[](len);
        uint256[] memory _chapterNumbers = new uint256[](len);
        string[] memory _verseContent = new string[](len);

        for (uint256 i = 0; i < len; i++) {
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
    function _makeVersesFromBook(JSONVerses memory _jsonVerses) internal returns (uint256[] memory, uint256[] memory, string[] memory) {
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
    function _getBook(string memory _bookName) internal returns (JSONVerses memory) {
        string memory root = vm.projectRoot();
        string memory fileName = string.concat(_bookName, ".json");
        string memory path = string.concat("/test/json/json_bible/", fileName);
        string memory fullpath = string.concat(root, path);
        string memory json = vm.readFile(fullpath);
        bytes memory data = vm.parseJson(json);
        JSONVerses memory jsonVerses = abi.decode(data, (JSONVerses));
        return jsonVerses;
    }

    // TODO: add to other proj
    function provideBatchTuple(uint256 len) internal returns(uint256[] memory, uint256[] memory, string[] memory){
        return(new uint256[](len), new uint256[](len), new string[](len));
    }

    // END: HELPERS
}
