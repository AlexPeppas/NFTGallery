// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./Developers.sol";

contract Gallery is ReentrancyGuard, Developers {
    using Counters for Counters.Counter;
    Counters.Counter private  _newGallery;
    address payable owner ;
    address tokenContract;
   
    constructor(){
        owner  = payable(msg.sender);        
    }
  
    struct GalleryCollection {
        uint256 galleryItemId;
        uint256 startingTimestamp;
        uint256 endingTimestamp;
        uint72 ticketprice;
        uint72 ticketNo;
        string[] tokenUri;
        string accessTokenUri;
        address payable creator;

     }
     
    GalleryCollection[] private newGallery;

    struct GalleryItem {
        uint256 galleryId;
        uint256 itemId;
        string tokenUri;
    }
     
    GalleryItem[] private newItem;

    function createGalleryCollection(uint256 _stTimestamp, uint256 _enTimestamp, uint72 _ticketPrice, uint72 _ticketNo , string[] memory _tokenUris, string memory _accessTokenUri, address payable _creator) external  onlyAdmin {
        require(_tokenUris.length<=15, "Max collection 15 items");
        require(_tokenUris.length>0, "Invalid no of items");
        require(_ticketNo <=200, "Max 200 guests");
        newGallery.push(GalleryCollection(_newGallery.current(), _stTimestamp, _enTimestamp, _ticketPrice, _ticketNo, _tokenUris, _accessTokenUri, _creator));
        _newGallery.increment();
        createCollectionItems();
     }

    function createCollectionItems() internal onlyAdmin{
        for(uint i =0; i<newGallery[newGallery.length-1].tokenUri.length; i++){
            newItem.push(GalleryItem(newGallery.length -1, i, newGallery[newGallery.length-1].tokenUri[i]));
        }
    }
    function setTokenContract(address _tokenContract) external onlyAdmin {
        tokenContract = _tokenContract;
    }

    function transferTicket(uint256 _galleryId) external payable {
        require(msg.value == newGallery[_galleryId].ticketprice,"Not valid price");
        require(tokenContract != address(0), "Set Token's Contract address first");
        require(newGallery[_galleryId].endingTimestamp < block.timestamp, "Gallery ended");
        IERC1155(tokenContract).safeTransferFrom(owner, msg.sender, _galleryId, 1, "");
    }

    function accessGallery(uint256 _galleryId) external {
        require(IERC1155(tokenContract).balanceOf(msg.sender, _galleryId) > 0 , "Buy a ticket first");
        //IERC1155(tokenContract).safeTransferFrom(msg.sender, to, id, amount, data);();
        //na ginete burn to token after access? one time access - all time access until edning? -might transfer token to other address 

    }


    


     //event marketItemCreated(uint256 indexed itemId, string _tokenUri,  address _creator, Layer _layer);
     //token uri is an array for 1 call multi token creation
    //  function createMarketItem(string[] memory _tokenUri, string memory _accessTokenUri, address payable _creator, uint24 _layerOption) external onlyAdmin() {
    //     Layer layer;
        
    //     if(_layerOption == 0){
    //          layer = Layer.Layer0;
    //     }else if(_layerOption == 1){
    //          layer = Layer.Layer1;
    //     }else layer = Layer.Layer2;
         
    //      marketItem.push(MarketItem(_newMarketItem.current(), _tokenUri[i], _accessTokenUri, _creator, 0, layer));
         
    //      emit marketItemCreated(_newMarketItem.current(), _tokenUri, _creator, layer);
         
    //      _newMarketItem.increment();
    //  }
     
    //  function fetchLayer0Items() external view returns (MarketItem[] memory) {
    //      require(marketItem.length > 0, "Not any items");
    //      uint24 itemsFetched = 0;
    //      for(uint24 i = 0; i< marketItem.length; i++){
    //          if(marketItem[i].layerOption == Layer.Layer0){
    //              itemsFetched++;
    //          }
    //      }
    //      MarketItem[] memory item = new MarketItem[](itemsFetched);
    //      for(uint24 i =0; i< marketItem.length; i++){
    //          if(marketItem[i].layerOption == Layer.Layer0){
    //              MarketItem storage currentItem = marketItem[i];
    //              item[i] = currentItem;
    //          }
    //      }
    //      return item;
    //  }
     
    //  function fetchLayer1Items() external view returns (MarketItem[] memory) {
    //      require(marketItem.length > 0, "Not any items");
    //      uint24 itemsFetched = 0;
    //      for(uint24 i = 0; i< marketItem.length; i++){
    //          if(marketItem[i].layerOption == Layer.Layer1){
    //              itemsFetched++;
    //          }
    //      }
    //      MarketItem[] memory item = new MarketItem[](itemsFetched);
    //      for(uint24 i =0; i< marketItem.length; i++){
    //          if(marketItem[i].layerOption == Layer.Layer0){
    //              MarketItem storage currentItem = marketItem[i];
    //              item[i] = currentItem;
    //          }
    //      }
    //      return item;
    //  }
     
    //  function fetchLayer2Items() external view returns (MarketItem[] memory) {
    //      require(marketItem.length > 0, "Not any items");
    //      uint24 itemsFetched = 0;
    //      for(uint24 i = 0; i< marketItem.length; i++){
    //          if(marketItem[i].layerOption == Layer.Layer0){
    //              itemsFetched++;
    //          }
    //      }
    //      MarketItem[] memory item = new MarketItem[](itemsFetched);
    //      for(uint24 i =0; i< marketItem.length; i++){
    //          if(marketItem[i].layerOption == Layer.Layer2){
    //              MarketItem storage currentItem = marketItem[i];
    //              item[i] = currentItem;
    //          }
    //      }
    //      return item;
    //  }
     
     
     
     
}