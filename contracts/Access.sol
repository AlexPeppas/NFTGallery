// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
//import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./NewGallery.sol";

contract Stuff {
    using Counters for Counters.Counter;
    Counters.Counter private  _userId;
    
    address[] admin;
    address[] developers;

    struct NewUser {
        uint256 userId;
        string userName;
        address payable  userAd;
    }
    
    NewUser[] public user;

    mapping(address => bool) isuser;
    mapping(address => bool) isDeveloper;
    mapping(address => bool) isAdmin;
    
    constructor(){
        admin.push(msg.sender);
        isAdmin[msg.sender] = true;
    }
    
    modifier onlyAdmin() {
        require(isAdmin[msg.sender] == true, "Not Admin");
        _;
    }

    modifier developersAndHigher() {
        require(isAdmin[msg.sender] == true || isDeveloper[msg.sender] == true, "Not an admin nor a developer");
        _;
    }

    modifier notUser() {
        require(isuser[msg.sender] != true, "Already a user");
        _;
    }

    modifier isUser() {
        require(isuser[msg.sender] == true, "Not a user");
        _;
    }

    event AdminCreated(address _newAdmin);
    
    function setAdmin(address _newAdmin) external onlyAdmin {
        admin.push(_newAdmin);
        isAdmin[_newAdmin] = true;
        emit AdminCreated(_newAdmin);
    }

    function addDeveloper(address _address) external onlyAdmin {
        developers.push(_address);
        isDeveloper[_address] = true;
    }
    
    event NewUserCreated(uint256 indexed userId, string userName, address userAd);
    
    
    function createUser(string memory _userName) external notUser {
        _userId.increment();
        user.push(NewUser(_userId.current(), _userName, payable(msg.sender) )); 
        isuser[msg.sender] = true;
        emit NewUserCreated(_userId.current(), _userName, msg.sender);
    }

}

contract Access is ReentrancyGuard, Stuff {
    using Counters for Counters.Counter;
    Counters.Counter private  _newGallery;
    uint256 constant tokenPrice = 1000000000000000;
    address payable owner ;
    address tokenContract;
    address constant burner =  0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199;
   
    constructor() Stuff(){
        owner  = payable(msg.sender);        
    }

    mapping(address => mapping(uint256 => uint256)) userHasAccessToGallerySinceTimestamp;
    mapping (uint256 => address) galleryIdToGalleryAddress;

    struct GalleryItems {
        uint256 galleryId;
        uint256 itemId;
        string uri;
    }

    function createGalleryCollection(uint256 _stTimestamp, uint256 _enTimestamp, uint72 _ticketPrice, uint72 _ticketNo , string[] memory _tokenUris, address payable _creator) external  onlyAdmin {
        require(_tokenUris.length<=15, "Max collection 15 items");
        require(_tokenUris.length>0, "Invalid no of items");
        require(_ticketNo <=200, "Max 200 guests");
        _newGallery.increment();
        NewGallery gallery = new NewGallery(_newGallery.current(), _stTimestamp, _enTimestamp, _ticketPrice, _ticketNo, _tokenUris, _creator); 
        galleryIdToGalleryAddress[_newGallery.current()] = address(gallery);
    }

    function transferTicket(uint256 _galleryId) external payable isUser {
        uint256 ticketPrice = NewGallery(galleryIdToGalleryAddress[_galleryId]).ticketprice();
        uint256 endingTimestamp = NewGallery(galleryIdToGalleryAddress[_galleryId]).endingTimestamp();
        require(IERC1155(tokenContract).balanceOf(msg.sender, 0) >= ticketPrice ,"Not valid price");
        require( endingTimestamp> block.timestamp, "Gallery ended");
        IERC1155(tokenContract).safeTransferFrom(msg.sender, owner, 0, ticketPrice, "");
        IERC1155(tokenContract).safeTransferFrom(owner, msg.sender, _galleryId, 1, "");
    }

    function accessGallery(uint256 _galleryId) external isUser {
        uint256 endingTimestamp = NewGallery(galleryIdToGalleryAddress[_galleryId]).endingTimestamp();
        uint256 startingTimestamp = NewGallery(galleryIdToGalleryAddress[_galleryId]).startingTimestamp();
        require(IERC1155(tokenContract).balanceOf(msg.sender, _galleryId) > 0 , "Buy a ticket first");
        require(block.timestamp < endingTimestamp, " Gallery ended this ticket is useless now");
        require(block.timestamp > startingTimestamp, "Gallery Not Started Yet");
        IERC1155(tokenContract).safeTransferFrom(msg.sender, burner, _galleryId, 1, "");
        userHasAccessToGallerySinceTimestamp[msg.sender][_galleryId] = block.timestamp;
    }

    function transferFunds(uint256 _galleryId) external payable {
        uint256 endingTimestamp = NewGallery(galleryIdToGalleryAddress[_galleryId]).endingTimestamp();
        require(block.timestamp > endingTimestamp, "Not finished yet");
        uint256 ticketPrice = NewGallery(galleryIdToGalleryAddress[_galleryId]).ticketprice();
        uint256 ticketNo = NewGallery(galleryIdToGalleryAddress[_galleryId]).ticketNo();
        address payable creator = NewGallery(galleryIdToGalleryAddress[_galleryId]).creator();
        uint256 price = (ticketNo - IERC1155(tokenContract).balanceOf(owner, _galleryId)) * ticketPrice ;
        creator.transfer(price * 2/10 );
    }

    function fetchGallery(uint256 _galleryId) external view returns (GalleryItems[] memory){
        require(_galleryId <= _newGallery.current(), "Wrong id");
        uint256 endingTimestamp = NewGallery(galleryIdToGalleryAddress[_galleryId]).endingTimestamp();
        require(block.timestamp < endingTimestamp, "Gallery Ended");
        require(userHasAccessToGallerySinceTimestamp[msg.sender][_galleryId] + (6*3600) > block.timestamp, "Ticket Expired");
        uint256 length = NewGallery(galleryIdToGalleryAddress[_galleryId]).itemLength();
        GalleryItems[] memory items = new GalleryItems[](length);
        for(uint i=0; i<length; i++){
            (uint256 galleryid , uint256 itemid, string memory uri) = NewGallery(galleryIdToGalleryAddress[_galleryId]).item(i);
            items[i].galleryId = galleryid;
            items[i].itemId = itemid;
            items[i].uri = uri;
            
        }
        return (items);      
    } 

    function setTokenContract(address _tokenContract) external onlyAdmin {
        tokenContract = _tokenContract;
    }

    function buyCurrency(uint256 _quantity) external payable isUser{
        require(msg.value == tokenPrice * _quantity,"Not the right ammount");
        IERC1155(tokenContract).safeTransferFrom(owner, msg.sender,0,_quantity, "");
    }
    
}

