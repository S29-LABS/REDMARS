// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;



contract Redmarsbacker {
    string constant ERR_ALREADY_SEEDED = "07001";
    string constant ERR_MSGVALUE_AMOUNT_MISMATCH = "07009";

    address public protocol;

    mapping (uint256 => address) idToRedeemer; 
    mapping (uint256 => uint256) idToAmountRedeemable;

    constructor() {
        protocol = msg.sender;
    }

    modifier onlyProtocol() {
        require(protocol == msg.sender);
        _;
    }

    function updateRedeemer(uint256 _tokenId, address _newredeemer) external onlyProtocol() {
        idToRedeemer[_tokenId] = _newredeemer;
    }

    function seedId(uint256 _tokenId, uint256 _amount) payable external onlyProtocol() {
        require(idToAmountRedeemable[_tokenId] == 0, ERR_ALREADY_SEEDED);
        require(msg.value == _amount, ERR_MSGVALUE_AMOUNT_MISMATCH);
        
        idToAmountRedeemable[_tokenId] = _amount;
    }


    
}