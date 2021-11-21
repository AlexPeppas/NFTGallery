// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Admins.sol";

contract Market is ReentrancyGuard, Admins {
    using Counters for Counters.Counter;
    Counters.Counter private  _newMarketItem;
    address payable owner ;
   
    constructor(){
        owner  = payable(msg.sender);
    }
    
     enum Layer {Layer0, Layer1, Layer2} 
     
     struct MarketItem {
         uint256 marketId;
         string tokenUri;
         address payable creator;
         uint72 viewsPerMonth;
         Layer layerOption;
     }
     
     MarketItem[] private marketItem;
     
     event marketItemCreated(uint256 indexed itemId, string _tokenUri,  address _creator, Layer _layer);
     
     function createMarketItem(string memory _tokenUri, address payable _creator, uint24 _layerOption) external onlyAdmin() {
        Layer layer;
        
        if(_layerOption == 0){
             layer = Layer.Layer0;
        }else if(_layerOption == 1){
             layer = Layer.Layer1;
        }else layer = Layer.Layer2;
         
         marketItem.push(MarketItem(_newMarketItem.current(), _tokenUri, _creator, 0, layer));
         
         emit marketItemCreated(_newMarketItem.current(), _tokenUri, _creator, layer);
         
         _newMarketItem.increment();
     }
     
     function fetchLayer0Items() external view returns (MarketItem[] memory) {
         require(marketItem.length > 0, "Not any items");
         uint24 itemsFetched = 0;
         for(uint24 i = 0; i< marketItem.length; i++){
             if(marketItem[i].layerOption == Layer.Layer0){
                 itemsFetched++;
             }
         }
         MarketItem[] memory item = new MarketItem[](itemsFetched);
         for(uint24 i =0; i< marketItem.length; i++){
             if(marketItem[i].layerOption == Layer.Layer0){
                 MarketItem storage currentItem = marketItem[i];
                 item[i] = currentItem;
             }
         }
         return item;
     }
     
     function fetchLayer1Items() external view returns (MarketItem[] memory) {
         require(marketItem.length > 0, "Not any items");
         uint24 itemsFetched = 0;
         for(uint24 i = 0; i< marketItem.length; i++){
             if(marketItem[i].layerOption == Layer.Layer1){
                 itemsFetched++;
             }
         }
         MarketItem[] memory item = new MarketItem[](itemsFetched);
         for(uint24 i =0; i< marketItem.length; i++){
             if(marketItem[i].layerOption == Layer.Layer0){
                 MarketItem storage currentItem = marketItem[i];
                 item[i] = currentItem;
             }
         }
         return item;
     }
     
     function fetchLayer2Items() external view returns (MarketItem[] memory) {
         require(marketItem.length > 0, "Not any items");
         uint24 itemsFetched = 0;
         for(uint24 i = 0; i< marketItem.length; i++){
             if(marketItem[i].layerOption == Layer.Layer0){
                 itemsFetched++;
             }
         }
         MarketItem[] memory item = new MarketItem[](itemsFetched);
         for(uint24 i =0; i< marketItem.length; i++){
             if(marketItem[i].layerOption == Layer.Layer2){
                 MarketItem storage currentItem = marketItem[i];
                 item[i] = currentItem;
             }
         }
         return item;
     }
     
     
     
     
}