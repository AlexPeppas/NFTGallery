// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";


contract Stuff {
    using Counters for Counters.Counter;
    Counters.Counter private  _userId;
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

    modifier isUser() {
        bool exists;
        exists = !isNotUser();
        if(exists == false){
            if(developers.length > 0){
                for(uint i = 0 ; i<developers.length; i++){
                    if(msg.sender == developers[i]){
                        exists = true;
                        break;
                    }
                }
            }
        }
        if(exists == false){
            for(uint i =0; i<admin.length; i++){
                if(msg.sender == admin[i]){
                    exists = true;
                    break;
                }
            }
        }
        require(exists, "Not a user or an admin/developer");
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

}

contract Gallery is ReentrancyGuard, Stuff {
    using Counters for Counters.Counter;
    Counters.Counter private  _newGallery;
    address payable owner ;
    address constant burner =  0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199;
    address tokenContract;
   
    constructor() Stuff(){
        owner  = payable(msg.sender);        
    }


    struct GalleryCollection {
        uint256 galleryItemId;
        uint256 startingTimestamp;
        uint256 endingTimestamp;
        uint72 ticketprice;
        uint72 ticketNo;
        uint72 ticketsSold;
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

    function createGalleryCollection(uint256 _stTimestamp, uint256 _enTimestamp, uint72 _ticketPrice, uint72 _ticketNo , string[] memory _tokenUris, address payable _creator) external  onlyAdmin {
        require(_tokenUris.length<=15, "Max collection 15 items");
        require(_tokenUris.length>0, "Invalid no of items");
        require(_ticketNo <=200, "Max 200 guests");
        newGallery.push(GalleryCollection(_newGallery.current(), _stTimestamp, _enTimestamp, _ticketPrice, _ticketNo, 0, _tokenUris, _creator));
        _newGallery.increment();
        createCollectionItems();
     }

    function createCollectionItems() internal onlyAdmin{
        for(uint i =0; i<newGallery[newGallery.length-1].tokenUri.length; i++){
            newItem.push(GalleryItem(newGallery.length -1, i, newGallery[newGallery.length-1].tokenUri[i]));
        }
    }

    function transferTicket(uint256 _galleryId) external payable isUser {
        require(msg.value == newGallery[_galleryId].ticketprice,"Not valid price");
        require(tokenContract != address(0), "Set Token's Contract address first");
        require(newGallery[_galleryId].endingTimestamp > block.timestamp, "Gallery ended");
        IERC1155(tokenContract).safeTransferFrom(owner, msg.sender, _galleryId, 1, "");
        newGallery[_galleryId].ticketsSold++;
    }

    function accessGallery(uint256 _galleryId) external isUser {
        require(IERC1155(tokenContract).balanceOf(msg.sender, _galleryId) > 0 , "Buy a ticket first");
        require(block.timestamp < newGallery[_galleryId].endingTimestamp, " Gallery ended this ticket is useless now");
        IERC1155(tokenContract).safeTransferFrom(msg.sender, burner, _galleryId, 1, "");
    }

    function transferFunds(uint256 _galleryId) external payable {
        require(block.timestamp > newGallery[_galleryId].endingTimestamp, "Not finished yet");
        address payable creator = newGallery[_galleryId].creator;
        uint72 price = newGallery[_galleryId].ticketsSold *newGallery[_galleryId].ticketprice ;
        creator.transfer(price * 2/10 );
    }

    function fetchGallery(uint256 _galleryId) external view returns (GalleryItem[] memory){
        require(newItem.length > 0, "Something went Wrong");
        require(block.timestamp > newGallery[_galleryId].startingTimestamp, "Not time yet");
        require(block.timestamp < newGallery[_galleryId].endingTimestamp, "Finished");
        uint256 galleryItems = 0;
        for(uint i =0 ; i <newItem.length; i++){
            if(newItem[i].galleryId == _galleryId){
                galleryItems++;
            }
        }
        GalleryItem[] memory item = new GalleryItem[](galleryItems);

        for(uint i = 0; i<newItem.length; i++){
            if(newItem[i].galleryId == _galleryId){
                GalleryItem storage currentItem = newItem[i];
                item[i] = currentItem;
            }
        }

        return item;
    }

    function setTokenContract(address _tokenContract) external onlyAdmin {
        tokenContract = _tokenContract;
    }

    function buyCurrency() external payable{

    }
    
}