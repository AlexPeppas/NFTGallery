// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract AccessTokens is ERC1155 {
    using Counters for Counters.Counter;
    Counters.Counter private _newTicketId;

    address marketAddress;
    address private owner ;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner can mint tokens");
        _;
    }

    constructor(address _marketAdress) ERC1155(""){
        marketAddress = _marketAdress;
        owner = msg.sender;
        

    }

    function createTickets(uint256 _totalSupply) external onlyOwner{
        _mint(msg.sender, _newTicketId.current(), _totalSupply, "" );
        _newTicketId.increment();
        _setApprovalForAll(msg.sender, marketAddress, true);
    }

    function reSetApproval() external {
        _setApprovalForAll(msg.sender, marketAddress, true);
    }
}
