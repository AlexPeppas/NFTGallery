// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Admins.sol";

contract Developers is ReentrancyGuard, Admins {
    address[] developers;

    modifier developersAndHigher() {
        bool requirement = false;
        if(developers.length > 0){
            for(uint i = 0 ; i<developers.length; i++){
            if(msg.sender == developers[i]){
                requirement = true;
                break;
            }
        }
        }
        if(requirement == false){
            for(uint i =0; i<admin.length; i++){
                if(msg.sender == admin[i]){
                    requirement = true;
                    break;
                }
            }
        }
        require(requirement, "Not an admin nor a developer");
        _;
    }

    function addDeveloper(address _address) external onlyAdmin {
        developers.push(_address);
    }
    
}