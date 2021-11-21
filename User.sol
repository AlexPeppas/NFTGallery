// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract User is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private  _userId;
    
    event NewUserCreated(uint256 indexed userId, string userName, address userAd);

    struct NewUser {
        uint256 userId;
        string userName;
        address payable  userAd;
    }
    
    NewUser[] public user;
    
    modifier notUser() {
        require(isNotUser());
        _;
    }
    
    function isNotUser() internal view returns (bool){
        if(user.length == 0) return true;
        for(uint32 i =0; i<user.length; i++){
            if(msg.sender == user[i].userAd){
                return false;
            }
        }
        return true;
    }
    
    function createUser(string memory _userName) external notUser {
        _userId.increment();
        user.push(NewUser(_userId.current(), _userName, payable(msg.sender) )); 
        emit NewUserCreated(_userId.current(), _userName, msg.sender);
    }
    
    // function fetchUsers() external view returns (NewUser[] memory) {
    //     require(user.length>0,"Not any users");
    //     NewUser[] memory usertemp = new NewUser[](_userId.current());
    //     for(uint32 i =0; i<user.length; i++){
    //         NewUser storage usermemory  = user[i];
    //         usertemp[i] = usermemory;
    //     }
    //     return usertemp;
    // }
    
    // function fetchUserslength() external view returns (uint) {
    //     return user.length;
    // }
    
}