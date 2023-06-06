// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./RedmarsCollection.sol";

contract Redmars {

    string public ERR_NOT_OWNER = "6010";
    // string public ERR_COLLECTION_NOTSTARTED = "6024";
    
    string public name = "R E D M A R S";

    address owner;

    struct Collection {
        string  name;
        string  symbol;
        string  description;
        uint32  tokenCount;
        bool    started;
        address at;
    }

    mapping (uint256 => Collection) public collections;

    modifier onlyOwner() {
        require(owner == msg.sender, ERR_NOT_OWNER);
        _;
    }

    constructor() {
        owner = msg.sender;
    }
    

    function startNewCollection() external onlyOwner() returns(address addr) {
        bytes memory bytecode = type(RedmarsCollection).creationCode;

    
        // address newcollection;
        
    
        assembly {
            
            addr := create(0,add(bytecode, 0x20), mload(bytecode))
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }

        // collections[_collectionId] = _collection;

        // return bytecodeSize;
    }







    // function mintInCollection(uint256 _collectionId) external  {
    //     Collection memory _collection = collections[_collectionId];

    //     require( _collection.started, ERR_COLLECTION_NOTSTARTED );


    //     collections[_collectionId].tokenCount += 1;
    // }

}