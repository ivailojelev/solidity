// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract AuctionPlatform {
    struct Auction {
        uint256 startTime;
        uint256 endTime;
        string itemName;
        string itemDescription;
        uint256 startingPrice;
        address payable creator;
        bool finalized;
    }
    struct HighestBid {
        uint256 currentHighestBid;
        address bidder;
    }
    mapping(uint256 => Auction) public auctionItems;
    mapping(uint256 => HighestBid) biddings;
    mapping(address => uint256) availableToWithdraw;
    uint256 private auctionId = 0;
    event NewAuction(uint256 auctionId);
    event NewHighestBid(uint256 auctionId, address, uint256 price);
    modifier onlyActiveAuction(uint256 auId) {
        require(
            block.timestamp < auctionItems[auId].endTime,
            "Auction has ended"
        );
        _;
    }

    function createAuction(
        uint256 duration,
        string memory itemName,
        string memory itemDescription,
        uint256 startingPrice
    ) public {
        require(duration >= 1, "The minimum duration is 1 day");
        uint256 durationInMilliseconds = block.timestamp +
            duration *
            24 *
            60 *
            60;
        auctionItems[auctionId] = Auction(
            block.timestamp,
            durationInMilliseconds,
            itemName,
            itemDescription,
            startingPrice,
            payable(msg.sender),
            false
        );
        emit NewAuction(auctionId);
        auctionId++;
    }

    function placeBid(uint256 auId) public payable onlyActiveAuction(auId) {
        require(
            msg.value > biddings[auId].currentHighestBid,
            "Your bid is lower than the current highest bid"
        );
        require(msg.value > 0, "Price must be higher than 0");
        // this checks if there is currently an existing bid for the auction
        if (biddings[auId].currentHighestBid > 0) {
            availableToWithdraw[biddings[auId].bidder] = biddings[auId]
                .currentHighestBid;
        }
        biddings[auId] = HighestBid(msg.value, msg.sender);
        emit NewHighestBid(auId, msg.sender, msg.value);
    }

    function finalizeAuction(uint256 auId) public onlyActiveAuction(auId) {
        require(!auctionItems[auId].finalized, "Auction has been finalized");
        auctionItems[auId].creator.transfer(biddings[auId].currentHighestBid);
        auctionItems[auId].finalized = true;
    }

    function withdraw(uint256 auId) public onlyActiveAuction(auId) {
        payable(msg.sender).transfer(availableToWithdraw[msg.sender]);
        availableToWithdraw[msg.sender] = 0;
    }

    function getAuction(uint256 auId) external view returns (Auction memory) {
        return auctionItems[auId];
    }

    function getBids(uint256 auId) external view returns (HighestBid memory) {
        return biddings[auId];
    }
}
