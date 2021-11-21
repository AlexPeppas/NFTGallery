// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Admins is ReentrancyGuard {
    address[] admin;
    
    constructor(){
        admin.push(msg.sender);
    }
    
    modifier onlyAdmin() {
        require(isAdmin(), "Not Admin");
        _;
    }
    
    function isAdmin() internal view returns (bool) {
        for(uint24 i = 0; i< admin.length; i++){
            if(msg.sender == admin[i]){
                return true;
            }
        }
        return false;
    }
    event AdminCreated(address _newAdmin);
    
    function setAdmin(address _newAdmin) external onlyAdmin {
        admin.push(_newAdmin);
        emit AdminCreated(_newAdmin);
    }
}