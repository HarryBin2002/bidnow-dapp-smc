// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

contract Bidnow {

    /**
    ====================================================================================================================================================
        Default variables
    ====================================================================================================================================================
     */
    
    address private ownerBidNowContract;

    address private tokenContract;

    uint256 private constant LISTING_FREE = 100000000000000000000; // 100 BQR token

    uint256 private constant NOT_TRANSFER_ASSET = 0;

    uint256 private constant ALREADY_TRANSFER_ASSET = 1;

    string private constant UPCOMING_AUCTION_STATUS = "UPCOMING_AUCTION";

    string private constant ACTIVE_AUCTION_STATUS = "ACTIVE_AUCTION";

    string private constant ENDED_AUCTION_STATUS = "ENDED_AUCTION";

    /**
    ====================================================================================================================================================
        Constructor
    ====================================================================================================================================================
     */

    constructor(
        address _tokenContract
    ) {
        tokenContract = _tokenContract;
    }


    /**
    ====================================================================================================================================================
        Auction struct and list Auction
    ====================================================================================================================================================
     */
     
    // Auction struct
    struct Auction {
        address ownerAuction;
        address nftContract;
        uint256 tokenId;
        uint256 initialPrice;
        uint256 openBiddingTime;
        uint256 closeBiddingTime;
        uint256 transferAssetStatus;
        string statusAuction;
    }

    /**
    ====================================================================================================================================================
        Mapping 
    ====================================================================================================================================================
     */

    // a uuid to manage an Auction
    mapping(uint256 => Auction) private uuidToAuction;

    // this mapping to manage a list contains address and offered price of bidder each bidding time.
    mapping(uint256 => BidderInfor[]) private uuidToListBidderInfo;

    /**
    ====================================================================================================================================================
        CreateNewAuction function
    ====================================================================================================================================================
     */

    // Any bidder has NFT can call this function to list an auction on BidNow Dapp
    function createNewAuction(
        address nftContract,
        uint256 tokenId,
        uint256 initialPrice,
        uint256 openBiddingTime,
        uint256 closeBiddingTime 
    ) 
    public payable
    isOwnerOfNFT(nftContract, tokenId, msg.sender)
    {
        // checking openBiddingTime and closeBiddingTime are valid
        require((block.timestamp < openBiddingTime) && (openBiddingTime < closeBiddingTime), "Setting time is invalid!");

        // create a new auction
        Auction memory auction = Auction(
                            msg.sender,
                            nftContract,
                            tokenId,
                            initialPrice,
                            openBiddingTime,
                            closeBiddingTime,
                            NOT_TRANSFER_ASSET,
                            UPCOMING_AUCTION_STATUS
                        );

        // call assignDataToBlockchain function
        uint256 uuid = assignDataToBlockchain(auction);

        // execute transfer asset
        executeTransfer(nftContract, tokenId);   

        // checking that send NFT is succeed?
        require(
            IERC721(nftContract).ownerOf(tokenId) == address(this), 
            "Failed to transfer NFT from msg.sender to smart contract"
        );

        // emit 
        emit CreatingAuctionEvent(
            msg.sender,
            nftContract,
            tokenId,
            initialPrice,
            openBiddingTime,
            closeBiddingTime,
            UPCOMING_AUCTION_STATUS,
            NOT_TRANSFER_ASSET,
            uuid
        );
    }


    // execute transfer function
    function executeTransfer(address nftContract, uint256 tokenId) internal {
        // nft owner purchase LISTING_FEE
        IERC20(tokenContract).transferFrom(
            msg.sender,
            address(this),
            LISTING_FREE
        );

        // send NFT from msg.sender (owner wallet) to smart contract
        IERC721(nftContract).transferFrom(
            msg.sender,
            address(this),
            tokenId
        );
    }

    // assign data function
    function assignDataToBlockchain(Auction memory auction) internal returns(uint256) {
        // Assign a new auction to uuid
        uint256 uuid = getUniqueNumber();
        uuidToAuction[uuid] = auction;

        return uuid;
    }

    // this function to get a number as uuid 
    uint256 counter;
    mapping(uint256 => bool) usedValues;

    function getUniqueNumber() internal returns(uint256 uuid) {
        uint256 randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1), msg.sender, counter)));
        uint256 uniqueNumber = randomValue % 1000000; // limit to 6 digits

        while (usedValues[uniqueNumber]) {
            counter++;
            randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1), msg.sender, counter)));
            uniqueNumber = randomValue % 1000000;
        }

        usedValues[uniqueNumber] = true;
        counter++;
        return uniqueNumber;
    }


    /**
    ====================================================================================================================================================
        CancelAuction function
    ====================================================================================================================================================
     */
    // this function to calcel an auction
    function CancelAuction(
        uint256 uuid
    ) 
    public
    {
        Auction memory auction = uuidToAuction[uuid];
        // checking msg.sender is owner of the auction which is canceled
        require(auction.ownerAuction == IERC721(auction.nftContract).ownerOf(auction.tokenId), "Owner of Auction id invalid!");

        // checking time valid to calcel. Must calceling before 1 hour = 3600 second
        require(block.timestamp < auction.closeBiddingTime - 3600, "Can not calcel auction. Because time is over!");

        /**
        execute logic code: re-send nft to owner, re-send BQK token to bidders is only for active auction
         */

        if(keccak256(abi.encodePacked(auction.statusAuction)) == keccak256(abi.encodePacked(ACTIVE_AUCTION_STATUS))) {
            // re-send nft to owner of auction
            IERC721(auction.nftContract).transferFrom(
                address(this),
                auction.ownerAuction,
                auction.tokenId
            );

            // get list bidder and re-send token to all 
            BidderInfor[] memory bidderInforList = uuidToListBidderInfo[uuid];

            // return BQK token to other bidder
            if (bidderInforList.length > 0) {
                // return BQK token to other bidder
                for(uint256 i = 0; i < bidderInforList.length; i++) {
                    withdraw(bidderInforList[i].bidderAddress, bidderInforList[i].offeredPrice * (10**18));
                }            
            }        
        }

        // delete auction

        // update data
        auction.openBiddingTime = 0;
        auction.closeBiddingTime = 1; // ensure that closeBiddingTime is bigger than openBiddingTime
        auction.statusAuction = ENDED_AUCTION_STATUS;
        auction.transferAssetStatus = ALREADY_TRANSFER_ASSET;

        emit CancelingAuctionEvent(
            auction.ownerAuction,
            auction.nftContract,
            auction.tokenId,
            auction.initialPrice,
            auction.openBiddingTime,
            auction.closeBiddingTime,
            auction.statusAuction,
            auction.transferAssetStatus,
            uuid
        );
    }

    /**
    ====================================================================================================================================================
        joinAuction function
    ====================================================================================================================================================
     */

    // Bidder struct
    struct BidderInfor {
        address bidderAddress;
        uint256 offeredPrice;
    }

    // this function is used for Bidder can join auction
    function bidAuction(
        uint256 uuid,
        uint256 offeredPrice
    ) public payable
    isCorrectAuctionTime(uuid) 
    {
        // checking that offeredPrice is valid
        Auction memory auction = uuidToAuction[uuid];
        require(offeredPrice > auction.initialPrice, "Offered Price is invalid!!!");

        // checking that msg.sender is enough token to bid
        uint256 balanceToken = IERC20(tokenContract).balanceOf(msg.sender);
        require(balanceToken >= offeredPrice, "Wallet address is not enough BQK token to bid!");

        // transfer BQK token from bidder's wallet to smart contract.
        IERC20(tokenContract).transferFrom(
            msg.sender,
            address(this),
            offeredPrice * (10**18)
        );

        // create new BidderInfor and push it to list
        BidderInfor memory bidderInfor = BidderInfor(
            msg.sender,
            offeredPrice
        );

        uuidToListBidderInfo[uuid].push(bidderInfor);

        emit BiddingAuctionEvent(
            uuid,
            msg.sender,
            offeredPrice
        );
    }

    /**
    ====================================================================================================================================================
        transferAssetAfterAuctionEnd function
    ====================================================================================================================================================
     */

    // function to execute logic that: transfer NFT to the winner and trnasfer BQK token to old owner of NFT after auction ends
    function transferAssetAfterAuctionEnd(uint256 uuid) external {
        // get list bidder of auction has uuid
        BidderInfor[] memory bidderInforList = uuidToListBidderInfo[uuid];

        // get winner of this auction
        BidderInfor memory winner = getTheWinnerOfAuction(uuid);

        // transfer NFT from SMC to winner
        IERC721(uuidToAuction[uuid].nftContract).transferFrom(
            address(this),
            winner.bidderAddress,
            uuidToAuction[uuid].tokenId
        );

        // transfer BQK token from SMC to old owne
        withdraw(uuidToAuction[uuid].ownerAuction, winner.offeredPrice * (10**18));

        if (bidderInforList.length > 0) {
            // return BQK token to other bidder
            for(uint256 i = 0; i < bidderInforList.length; i++) {
                if (bidderInforList[i].bidderAddress != winner.bidderAddress) {
                    withdraw(bidderInforList[i].bidderAddress, bidderInforList[i].offeredPrice * (10**18));
                }
            }            
        }

        uuidToAuction[uuid].statusAuction = ENDED_AUCTION_STATUS;
        uuidToAuction[uuid].transferAssetStatus = ALREADY_TRANSFER_ASSET;

        emit TransferingAssetEvent(
            uuid,
            uuidToAuction[uuid].transferAssetStatus
        );
    }

    // function to get the winner of the auction with its uuid
    function getTheWinnerOfAuction(uint256 uuid) internal view returns(BidderInfor memory) {

        BidderInfor[] memory bidderInforList = uuidToListBidderInfo[uuid];

        uint256 len = bidderInforList.length;

        for (uint256 i = 0; i < len-1; i++) {
            for (uint256 j = 0; j < len-1 - i; j++) {
                if (bidderInforList[j].offeredPrice > bidderInforList[j+1].offeredPrice) {
                    BidderInfor memory temp = bidderInforList[j];
                    bidderInforList[j] = bidderInforList[j+1];
                    bidderInforList[j+1] = temp;
                }
            }
        }

        return bidderInforList[len-1];
    }


    // Withdraw function
    function withdraw(address _to, uint256 amount) private {
        IERC20(tokenContract).transfer(_to, amount);
    }

    /**
    ====================================================================================================================================================
        Events
    ====================================================================================================================================================
     */

    
    event CreatingAuctionEvent(
        address ownerOfAuction,
        address nftContract,
        uint256 tokenId,
        uint256 initialPrice,
        uint256 openBiddingTime,
        uint256 closeBiddingTime,
        string statusAuction,
        uint256 transferAssetStatus,
        uint256 uuid
    );

    event CancelingAuctionEvent(
        address ownerOfAuction,
        address nftContract,
        uint256 tokenId,
        uint256 initialPrice,
        uint256 openBiddingTime,
        uint256 closeBiddingTime,
        string statusAuction,
        uint256 transferAssetStatus,
        uint256 uuid
    );

    event BiddingAuctionEvent(
        uint256 uuid,
        address spender,
        uint256 offeredPrice
    );

    event TransferingAssetEvent(
        uint256 uuid,
        uint256 transferAssetStatus
    );

    event updatingStatusAuctionEvent(
        uint256 uuid,
        string statusAuction
    );


    /**
    ====================================================================================================================================================
        Modifiers
    ====================================================================================================================================================
     */
     
    modifier isOwnerOfNFT(
        address nftContract,
        uint256 tokenId,
        address spender
    ) {
        IERC721 nft = IERC721(nftContract);
        address owner = nft.ownerOf(tokenId);
        if (spender != owner) {
            revert("The spender is not owner of this NFT!!!");
        }
        _;
    }

    modifier isCorrectAuctionTime(
        uint256 uuid
    ) {
        require(uuidToAuction[uuid].ownerAuction != address(0), "Auction with this UUID does not exist");

        Auction memory auction = uuidToAuction[uuid];

        uint256 openBiddingTime = auction.openBiddingTime;
        uint256 closeBiddingTime = auction.closeBiddingTime;

        // execute compare open and close time with current time 
        uint256 pointTimestamp = block.timestamp;

        require(
            (pointTimestamp > openBiddingTime) && (pointTimestamp < closeBiddingTime),
            "Time Over!!! Please checking Auction schedule again!"
        );
        _;
    }

    /**
    ====================================================================================================================================================
        Set function
    ====================================================================================================================================================
     */

    function setOpenBiddingTime(
        uint256 uuid, 
        uint256 openBiddingTime,
        uint256 closeBiddingTime
    ) public view {

        require(openBiddingTime < closeBiddingTime, "invalid time!");

        Auction memory auction = uuidToAuction[uuid];

        // checking that auction must upcoming status
        uint256 pointTimestamp = block.timestamp;
        require(auction.openBiddingTime > pointTimestamp, "invalid time to setOpenbiddingTime!");

        // update
        auction.openBiddingTime = openBiddingTime;
        auction.closeBiddingTime = closeBiddingTime;
    }
}