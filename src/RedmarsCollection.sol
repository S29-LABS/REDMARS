// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./interfaces/IERC721Metadata.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/IRedmarsCollection.sol";
import "./RedmarsBacker.sol";

contract RedmarsCollection is IERC721Metadata, IERC721, IRedmarsCollection {

    uint256 public idCount;

    uint256 private backerCount;


   /**
   * @dev List of revert message codes. Implementing dApp should handle showing the correct message.
   * Based on 0xcert framework error codes.
   */
    string constant ERR_ZERO_ADDRESS = "60001";

    string constant ERR_NOT_VALIDNFT = "60002";

    string constant ERR_NOT_OWNER    = "60003";

    string constant ERR_NOT_OWNER_APPROVED = "60004";

    string constant ERR_TRANSFER_TO_SELF = "60005";

    string constant ERR_NFT_ALREADYEXISTS = "60006";

    string constant ERR_IS_OWNER = "60007";
  
    /**
    * @dev A mapping from NFT ID to its backer contract address.
    */
    mapping (uint256 => address) public idTobacker;
    /**
    * @dev A mapping from NFT ID to the address that owns it.
    */
    mapping (uint256 => address) private idToOwner;
    /**
    * @dev A mapping from NFT ID to boolean to indicate whether burnt.
    */
    mapping (uint256 => bool) private idToBurnt;
    /**
    * @dev Mapping from NFT ID to approved address.
    */
    mapping (uint256 => address) private idToApproval;
    /**
    * @dev Mapping from owner address to count of their tokens.
    */
    mapping (address => uint256) private ownerToNFTokenCount;

    modifier canTransfer(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];

        require(tokenOwner == msg.sender || idToApproval[_tokenId] == msg.sender,
            ERR_NOT_OWNER_APPROVED
        );
        _;
    }

    modifier validNFToken(uint256 _tokenId) {
        require(idToOwner[_tokenId] != address(0), ERR_NOT_VALIDNFT);
        _;
    }

    constructor() { }

    function name() external pure returns (string memory) {
        return "V E T I G O"; 
    }

    function symbol() external pure returns (string memory) {
        return " ~ V ~ ";
    }

    function tokenURI(uint256 _tokenId) external pure returns (string memory) {
        return " * R E D M A R S   C O L L E C T I O N   V E T I G O * ";
    }

    function description() external pure returns (string memory) {
        return " * R E D M A R S   C O L L E C T I O N   V E T I G O * ";
    }

    function addBacker() private returns (address newbacker) {
        bytes memory bytecode = type(Redmarsbacker).creationCode;

        assembly {
            newbacker := create(0, add(bytecode, 0x20), mload(bytecode))
        }
    }

    function addToken(address _to, uint256 _tokenId) private {
        require(_tokenId != uint256(0), ERR_NOT_VALIDNFT);

        assembly {
            mstore(0x00, _tokenId)

            mstore(0x20, idToOwner.slot)

            let _idToOwnerLoc := keccak256(0x00, 0x40)

            sstore(_idToOwnerLoc, _to)

            mstore(0x00, _to)

            mstore(0x20, ownerToNFTokenCount.slot)

            let _ownerToNFTokenCountLoc := keccak256(0x00, 0x40)

            sstore(_ownerToNFTokenCountLoc, add(sload(_ownerToNFTokenCountLoc), 1))
        }
    }

    
    function removeToken(address _from, uint256 _tokenId) private {
        require(idToOwner[_tokenId] == _from, ERR_NOT_OWNER);

        require(_tokenId != uint256(0), ERR_NOT_VALIDNFT);

        assembly {
            // decrement ownerToNFTokenCount mapping 
            mstore(0x00, _from)

            mstore(0x20, ownerToNFTokenCount.slot)

            let ownerToNFTokenCountLoc_ := keccak256(0x00,0x40)

            sstore(ownerToNFTokenCountLoc_, sub(sload(ownerToNFTokenCountLoc_), 1))

            // delete idToOwner i.e set ownership to zero
            mstore(0x00, _tokenId)

            mstore(0x20, idToOwner.slot)

            let idToOwnerLoc_ := keccak256(0x00, 0x40)

            sstore(idToOwnerLoc_, 0x00)
        }
    }

    /// @dev mint add's base token to an already created backer or it creates a backer and add's base token to it
    function mint(address _to, uint256 _amountForBacker, uint256 prevId, bool _backedMint) payable external {
        require(_to != address(0), ERR_ZERO_ADDRESS);

        uint256 tokenId;
        assembly {
            tokenId := add(sload(idCount.slot), 1)
        }

        bool isValidMinter = _backedMint ?
                                     idToOwner[prevId] == address(0) 
                                     : 
                                     idToOwner[prevId] == msg.sender && idToOwner[prevId] != address(0);
        
        require(isValidMinter, ERR_NOT_OWNER);

        bool isValidPrevId = _backedMint ? 
                                prevId == uint256(0) 
                                :
                                prevId != 0;

        require(isValidPrevId, ERR_NOT_VALIDNFT);

        address backer = _backedMint ? addBacker() : idTobacker[prevId];

        require(backer != address(0), ERR_ZERO_ADDRESS);

        seed(backer, tokenId, _amountForBacker);

        addToken(_to, tokenId);

        updateRedeemer(backer, _to, tokenId);

        // increase token count
        assembly {
              sstore(idCount.slot, tokenId)
        }
    
        emit Transfer(address(0), _to, tokenId);
    }

    function seed(address _backer, uint256 tokenId, uint256 _amountForBacker) private {
        require(tokenId != uint256(0), ERR_NOT_VALIDNFT);
        assembly {
            let freeMemPointer := mload(0x40)

            mstore(freeMemPointer, 0x6862362a)

            mstore(add(freeMemPointer, 0x20), tokenId)

            mstore(add(freeMemPointer, 0x40), _amountForBacker) 

            mstore(0x40, add(freeMemPointer, 0x60))

            // memory will look like:
            // 0x0380 -> 000000000000000000000000000000000000000000000000000000006862362a
            // 0x03A0 -> 0000000000000000000000000000000000000000000000000000000000000000 (tokenId) not known yet
            // 0x03C0 -> 0000000000000000000000000000000000000000000000000000000000000000 (_amountForBacker) not known yet
            
            if iszero(call(gas(), _backer, _amountForBacker, add(freeMemPointer, 0x1C), mload(0x40), 0x00, 0x20 )) {
                revert (0,0)
            }   

            // update backer mapping 
            mstore(0x00, tokenId)

            mstore(0x20, idTobacker.slot)  

            let idTobackerLoc_ := keccak256(0x00, 0x40)

            sstore(idTobackerLoc_, _backer)
        }
        emit Backed(_backer, msg.sender, tokenId );
    }

    function burn(uint256 tokenId) external validNFToken(tokenId) {
        address tokenOwner;
        address backer;

        assembly {
            // get token owner
            mstore(0x00, tokenId)

            mstore(0x20, idToOwner.slot)

            let idToOwnerLoc_ := keccak256(0x00,0x40)

            tokenOwner := mload(idToOwnerLoc_)

            // get backer
            mstore(0x20, idTobacker.slot)

            let idToBackerLoc_ := keccak256(0x00, 0x40)

            backer := sload(idToBackerLoc_)
        }

        require(tokenOwner == msg.sender, ERR_NOT_OWNER);

        clearApproval(tokenId);

        removeToken(tokenOwner, tokenId);

        assembly {
            mstore(0x00, tokenId)

            mstore(0x20, idToBurnt.slot)

            let idToBurntLoc_ := keccak256(0x00, 0x40)

            sstore(idToBurntLoc_, 1)
        }

        updateRedeemer(backer, address(0), tokenId);

        emit Transfer(tokenOwner, address(0), tokenId);
    }

    function updateRedeemer(address _backer, address _newredeemer, uint256 _tokenId ) private {
        require(_tokenId != uint256(0), ERR_NOT_VALIDNFT);

        assembly {
            let freemempointer := mload(0x40)

            mstore(freemempointer, 0xe75f8035)

            mstore(add(freemempointer, 0x20), _tokenId)

            mstore(add(freemempointer, 0x40), _newredeemer)

            mstore(0x40, add(freemempointer, 0x60))

            if iszero(call(gas(), _backer, 0, add(freemempointer, 0x1C), mload(0x40), 0x00, 0x20)) {
                revert (0,0) // understand how to return revert mesages in yul
            }
        }
    }

    function balanceOf(address _owner) external view returns (uint256 value) {
        require(_owner != address(0), ERR_ZERO_ADDRESS);

        assembly {
            mstore(0x00, _owner)

            mstore(0x20, ownerToNFTokenCount.slot)

            let ownerToNFTokenCountLoc_ := keccak256(0x00, 0x40)

            value := sload(ownerToNFTokenCountLoc_)
        }
    }

    function ownerOf(uint256 _tokenId) external view  returns (address _owner) {
        require(_tokenId != uint256(0), ERR_NOT_VALIDNFT);

        assembly {
            mstore(0x00, _tokenId)

            mstore(0x20, idToOwner.slot)

            let idToOwnerLoc_ := keccak256(0x00, 0x40)

            _owner := sload(idToOwnerLoc_)
        }
        
        require(_owner != address(0), ERR_NOT_VALIDNFT);
    }

    function transfer(address _to, uint256 _tokenId) public {
        require(_tokenId != uint256(0), ERR_NOT_VALIDNFT);

        address from;
        address backer;
        assembly {
            // get from address
            mstore(0x00, _tokenId)

            mstore(0x20, idToOwner.slot)

            let idToOwnerLoc_ := keccak256(0x00, 0x40)

            from := sload(idToOwnerLoc_)

            // get backer
            mstore(0x20, idTobacker.slot)

            let idToBackerLoc_ := keccak256(0x00, 0x40)

            backer := sload(idToBackerLoc_)
        }
        
        clearApproval(_tokenId); // i havent worked on removing approval // create a way to capture approvals

        require(from == msg.sender, ERR_NOT_OWNER);

        require(from != _to, ERR_TRANSFER_TO_SELF);

        removeToken(from, _tokenId);

        addToken(_to, _tokenId);

        updateRedeemer(backer, _to, _tokenId);
    
        emit Transfer(from, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner;

        assembly {
            // get token owner
            mstore(0x00, _tokenId)

            mstore(0x20, idToOwner.slot)

            let idToOwnerLoc_ := keccak256(0x00,0x40)

            tokenOwner := mload(idToOwnerLoc_)
        }

        require(tokenOwner == _from, ERR_NOT_OWNER );

        require(_to != address(0), ERR_ZERO_ADDRESS);

        transfer(_to, _tokenId);
    }



    function getSelector() public pure returns (bytes32) {
        // "updateRedeemer(uint256,address)"
        // "seedId(uint256,uint256)"
        return keccak256("updateRedeemer(uint256,address)");
    }


    function approve(address _toBeApproved, uint256 _tokenId) external validNFToken(_tokenId) {
        address tokenOwner;

        assembly {
            // get token owner
            mstore(0x00, _tokenId)

            mstore(0x20, idToOwner.slot)

            let idToOwnerLoc_ := keccak256(0x00,0x40)

            tokenOwner := mload(idToOwnerLoc_)
        }

        require(tokenOwner == msg.sender, ERR_NOT_OWNER );

        require(_toBeApproved != tokenOwner, ERR_IS_OWNER);

        assembly {
            mstore(0x20, idToApproval.slot)

            let idToApprovalLoc_ := keccak256(0x00, 0x40)

            sstore(idToApprovalLoc_, _toBeApproved)
        }
         emit Approval(tokenOwner, _toBeApproved, _tokenId);
    }

    function clearApproval(uint256 _tokenId) private {
        assembly {
            mstore(0x00, _tokenId)

            mstore(0x20, idToApproval.slot)

            let idToApprovalLoc_ := keccak256(0x00, 0x40)

            sstore(idToApprovalLoc_, 0x00) 
        }
    }
}





    