// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Redmars.sol";
import "../src/RedmarsCollection.sol";

contract RedmarsTest is Test {
  
    Redmars redmars;
    RedmarsCollection vetigo;
    function setUp() public {
      redmars = new Redmars();
    }

    // forge test --match-path test/Redmars.t.sol --match-test testStartNewCollection -vvvv
    function testStartNewCollection() public {
        vetigo = RedmarsCollection(redmars.startNewCollection());
    }

    // forge test --match-path test/Redmars.t.sol --match-test testBackAndMint1 -vvvv
    function testBackAndMint1() public {
        testStartNewCollection();
        // get selector 
        vetigo.getSelector();
        
      
        // true backed mint 
        vetigo.mint{ value: 10 }(address(0x2Ac), 10, 0, true);
        // uint256 balanceOf0x2Ac = vetigo.balanceOf(address(0x2Ac));
        // assertEq(balanceOf0x2Ac, 1);
    
    }

    // forge test --match-path test/Redmars.t.sol --match-test testBackAndMint -vvvv
    function testBackAndMint() public {
        testBackAndMint1();
      
        // true backed mint (address _to, uint256 _amountForBacker, uint256 prevId, bool _backedMint)
        vetigo.mint{ value: 10 }(address(0x2Ac), 10, 0, true);
        uint256 balanceOf0x2Ac = vetigo.balanceOf(address(0x2Ac));
        assertEq(balanceOf0x2Ac, 2);
        
    }
    // forge test --match-path test/Redmars.t.sol --match-test testTransfer -vvvv
    function testTransfer() public {
        testBackAndMint();
        vetigo.ownerOf(1);
        testBackAndMint();

        // (address _to, uint256 _tokenId) 
        vm.startPrank(address(0x2Ac));
        vetigo.transfer(address(0x3Ac), 1);
        vm.stopPrank();
        vetigo.idCount();
        vetigo.ownerOf(1);
    }


}
