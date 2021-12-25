//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Nft is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter  _newNft;
    address contractAddress ;
    address immutable owner;

    constructor() ERC721("NftGallery", "NFG"){
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function setContract(address _contract) external onlyOwner{
        contractAddress = _contract;
    }

    function mintNft(string memory _tokenURI) external{
        require(contractAddress != address(0));
        _mint(contractAddress, _newNft.current());
        _setTokenURI(_newNft.current(), _tokenURI);
        _newNft.increment();
        setApprovalForAll(contractAddress, true);
    }

    function reSetApprovalAfterBuying() external {
        setApprovalForAll(contractAddress, true);
    }
}