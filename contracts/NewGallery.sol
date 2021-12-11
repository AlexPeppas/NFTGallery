//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";

contract NewGallery {
    using Counters for Counters.Counter;
    Counters.Counter private  _itemId;
    uint256 galleryId;
    uint256 public immutable startingTimestamp;
    uint256 public immutable endingTimestamp;
    uint72 public immutable ticketprice;
    uint72 public immutable ticketNo;
    string[] tokenUri;
    uint256 public immutable  itemLength;
    address payable public immutable creator;
    address[] hasAccess;

    struct GalleryItems {
        uint256 galleryId;
        uint256 itemId;
        string uri;
    }

    GalleryItems[] public item;

    constructor(
        uint256 _id,
        uint256 _stTS,
        uint256 _enTS,
        uint72 _tokensPerTicket,
        uint72 _maxTickets,
        string[] memory _uris,
        address payable _creator
    ){
        galleryId = _id;
        startingTimestamp = _stTS;
        endingTimestamp = _enTS;
        ticketprice = _tokensPerTicket;
        ticketNo = _maxTickets;
        tokenUri = _uris;
        creator = _creator;
        itemLength = tokenUri.length;

        for(uint8 i =0; i< tokenUri.length; i++){
            _itemId.increment();
            item.push(GalleryItems(galleryId, _itemId.current(), tokenUri[i]));
        }
    }




}