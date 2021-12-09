// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
//import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";


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

contract Gallery is ReentrancyGuard, Stuff {
    using Counters for Counters.Counter;
    Counters.Counter private  _newGallery;
    uint256 constant tokenPrice = 1000000000000000;
    uint256 startingTimestamp;
    address payable owner ;
    address tokenContract;
    address constant burner =  0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199;
   
    constructor() Stuff(){
        owner  = payable(msg.sender);        
    }


    struct GalleryCollection {
        uint256 galleryItemId;
        uint256 startingTimestamp;
        uint256 endingTimestamp;
        uint72 ticketprice;
        uint72 ticketNo;
        string[] tokenUri;
        address payable creator;

     }

    struct GalleryItem {
        uint256 galleryId;
        uint256 itemId;
        string tokenUri;
    }



    GalleryCollection[] private newGallery;
    GalleryItem[] private newItem;
    
    mapping(address => mapping(uint256 => uint256)) userHasAccess;

    function createGalleryCollection(uint256 _stTimestamp, uint256 _enTimestamp, uint72 _ticketPrice, uint72 _ticketNo , string[] memory _tokenUris, address payable _creator) external  onlyAdmin {
        require(_tokenUris.length<=15, "Max collection 15 items");
        require(_tokenUris.length>0, "Invalid no of items");
        require(_ticketNo <=200, "Max 200 guests");
        _newGallery.increment();
        newGallery.push(GalleryCollection(_newGallery.current(), _stTimestamp, _enTimestamp, _ticketPrice, _ticketNo, _tokenUris, _creator));
        createCollectionItems();
     }

    function createCollectionItems() internal onlyAdmin{
        for(uint i =0; i<newGallery[newGallery.length-1].tokenUri.length; i++){
            newItem.push(GalleryItem(newGallery.length, i, newGallery[newGallery.length-1].tokenUri[i]));
        }
    }

    function transferTicket(uint256 _galleryId) external payable isUser {
        require(IERC1155(tokenContract).balanceOf(msg.sender, 0) >= newGallery[_galleryId-1].ticketprice,"Not valid price");
        require(newGallery[_galleryId-1].endingTimestamp > block.timestamp, "Gallery ended");
        IERC1155(tokenContract).safeTransferFrom(msg.sender, owner, 0, newGallery[_galleryId-1].ticketprice, "");
        IERC1155(tokenContract).safeTransferFrom(owner, msg.sender, _galleryId, 1, "");
    }

    function accessGallery(uint256 _galleryId) external isUser {
        require(IERC1155(tokenContract).balanceOf(msg.sender, _galleryId) > 0 , "Buy a ticket first");
        require(block.timestamp < newGallery[_galleryId-1].endingTimestamp, " Gallery ended this ticket is useless now");
        IERC1155(tokenContract).safeTransferFrom(msg.sender, burner, _galleryId, 1, "");
        userHasAccess[msg.sender][_galleryId] = block.timestamp;
    }

    function transferFunds(uint256 _galleryId) external payable {
        require(block.timestamp > newGallery[_galleryId].endingTimestamp, "Not finished yet");
        address payable creator = newGallery[_galleryId].creator;
        uint256 price = (newGallery[_galleryId].ticketNo - IERC1155(tokenContract).balanceOf(owner, _galleryId)) *newGallery[_galleryId].ticketprice ;
        creator.transfer(price * 2/10 );
    }

    function fetchGallery(uint256 _galleryId) external view returns (GalleryItem[] memory){
        require(newItem.length > 0, "Something went Wrong");
        require(block.timestamp > newGallery[_galleryId-1].startingTimestamp, "Not time yet");
        require(block.timestamp < newGallery[_galleryId-1].endingTimestamp, "Finished");
        require(block.timestamp < userHasAccess[msg.sender][_galleryId] * 3600 * 6,"Ticket expired");
        uint256 galleryItems = 0;
        uint256 currentIndex = 0;
        for(uint i =0 ; i <newItem.length; i++){
            if(newItem[i].galleryId == _galleryId){
                galleryItems++;
            }
        }
        GalleryItem[] memory item = new GalleryItem[](galleryItems);

        for(uint i = 0; i<newItem.length; i++){
            if(newItem[i].galleryId == _galleryId){
                item[currentIndex] = newItem[i];
                currentIndex +=1;
            }
        }

        return item;
    }

    function setTokenContract(address _tokenContract) external onlyAdmin {
        tokenContract = _tokenContract;
    }

    function buyCurrency(uint256 _quantity) external payable isUser{
        require(msg.value == tokenPrice * _quantity,"Not the right ammount");
        IERC1155(tokenContract).safeTransferFrom(owner, msg.sender,0,_quantity, "");
    }
    
}
