// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BidNow {

    // Constant variable
    string constant private ENDED_AUCTION = "ENDED_AUCTION";
    string constant private ACTIVE_AUCTION = "ACTIVE_AUCTION";
    string constant private UPCOMING_AUCTION = "UPCOMING_AUCTION";



    // Default variables
    address private ownerBidNowContract;

    address private BQKContract;

    constructor(
        address _BQKContract
    ) {
        BQKContract = _BQKContract;
    }

    // Struct Auction
    struct Auction {
        address nftContract;
        uint256 tokenId;
        uint256 initialPrice;
        uint256 openBiddingTime;
        uint256 closeBiddingTime;
    }


    // Mapping

    // Owner of list auction 
    mapping(address => Auction[]) private ownerToListAuction;
    // a uuid to manage an Auction
    mapping(uint256 => Auction) private uuidToAuction;


    // List Auction
    Auction[] private listAuction;

    // Create a new auction
    function createNewAuction(
        address nftContract,
        uint256 tokenId,
        uint256 initialPrice,
        uint256 openBiddingTime,
        uint256 closeBiddingTime 
    ) 
    public
    isOwnerOfNFT(nftContract, tokenId, msg.sender)
    {
        // checking whether msg.sender is the owner of this NFT: isOwnerOfNFT
        // IERC721 nft = IERC721(nftContract);
        // address owner = nft.ownerOf(tokenId);
        
        // require(msg.sender == owner, "The spender is not owner of this NFT!!!");

        // create a new auction
        Auction memory auction = Auction(
                            nftContract,
                            tokenId,
                            initialPrice,
                            openBiddingTime,
                            closeBiddingTime
                        );

        // add new auction item to listAuction
        ownerToListAuction[msg.sender].push(auction);

        // Assign a new auction to uuid
        uint256 uuid = getUniqueNumber();
        uuidToAuction[uuid] = auction;

        // // send NFT from msg.sender (owner wallet) to smart contract
        // IERC721(nftContract).transferFrom(
        //     msg.sender,
        //     address(this),
        //     tokenId
        // );

        // // checking that send NFT is succeed?
        // require(
        //     IERC721(nftContract).ownerOf(tokenId) == address(this), 
        //     "Failed to transfer NFT from msg.sender to smart contract"
        // );

        // emit 
        emit AuctionInitialized(
            msg.sender,
            nftContract,
            tokenId,
            initialPrice,
            openBiddingTime,
            closeBiddingTime,
            uuid
        );
    }

    uint256 counter;
    mapping(uint256 => bool) usedValues;

    function getUniqueNumber() internal returns(uint256) {
        uint256 randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, counter)));
        uint256 uniqueNumber = randomValue % 1000000; // limit to 6 digits
        while (usedValues[uniqueNumber]) {
            counter++;
            randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, counter)));
            uniqueNumber = randomValue % 1000000;
        }
        usedValues[uniqueNumber] = true;
        counter++;
        return uniqueNumber;
    }


    // Cancel an auction


    // Join an auction to bid

    struct BidderInfor {
        address owner;
        uint256 offeredPrice;
    }

    // this mapping to manage a list contains address and offered price of bidder each bidding time.
    mapping(uint256 => BidderInfor[]) private uuidToOwnerAndOfferedPrice;

    function joinAuction(
        uint256 uuid,
        uint256 offeredPrice
    ) public payable
    isCorrectAuctionTime(uuid) 
    {
        // checking that offeredPrice is valid
        Auction memory auction = uuidToAuction[uuid];
        require(offeredPrice > auction.initialPrice, "Offered Price is invalid!!!");

        // transfer BQK token from bidder's wallet to smart contract.
        IERC20(BQKContract).transferFrom(
            msg.sender,
            address(this),
            offeredPrice * (10**18)
        );


        // create new BidderInfor and push it to list
        BidderInfor memory bi = BidderInfor(
            msg.sender,
            offeredPrice
        );

        uuidToOwnerAndOfferedPrice[uuid].push(bi);

    }

    // function to get the winner of the auction with its uuid
    function getTheWinnerOfAuction(uint256 uuid) internal view returns(address) {
        BidderInfor[] memory bidderInforList = uuidToOwnerAndOfferedPrice[uuid];

        uint256 len = bidderInforList.length;

        for (uint256 i = 0; i < len - 1; i++) {
            for (uint256 j = 0; j < len - 1 - i; j++) {
                if (bidderInforList[j].offeredPrice > bidderInforList[j+1].offeredPrice) {
                    uint256 temp = bidderInforList[j].offeredPrice;
                    bidderInforList[j].offeredPrice = bidderInforList[j+1].offeredPrice;
                    bidderInforList[j+1].offeredPrice = temp;
                }
            }
        }

        return bidderInforList[len-1].owner;
    }

    






    // Set up event to smart contract
    event AuctionInitialized(
        address ownerOfAuction,
        address nftContract,
        uint256 tokenId,
        uint256 initialPrice,
        uint256 openBiddingTime,
        uint256 closeBiddingTime,
        uint256 uuid
    );







    // Modifier
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
        Auction memory auc = uuidToAuction[uuid];

        uint256 openBiddingTime = auc.openBiddingTime;
        uint256 closeBiddingTime = auc.closeBiddingTime;

        // execute compare open and close time with current time 
        uint256 pointTimestamp = block.timestamp;

        require(
            (pointTimestamp > openBiddingTime) && (pointTimestamp < closeBiddingTime),
            "Time Over!!! Please checking Auction schedule again!"
        );
        _;
    }







    // Get function

    // get total Auction

    // get List ActiveAuction

    // get List EndedAuction

    //get List UpcomingAuction

    // get status Auction
    function getStatusAuction(uint256 uuid) public view returns(string memory) {
        Auction memory auc = uuidToAuction[uuid];

        uint256 openBiddingTime = auc.openBiddingTime;
        uint256 closeBiddingTime = auc.closeBiddingTime;

        // execute compare open and close time with current time 
        uint256 pointTimestamp = block.timestamp;

        if (pointTimestamp < openBiddingTime) {
            return UPCOMING_AUCTION;
        } else if (pointTimestamp > closeBiddingTime) {
            return ENDED_AUCTION;
        } else {
            return ACTIVE_AUCTION;
        }
    }

    // get list auction of spender
    function getListAuctionOfSpender(address spender) public view returns(Auction[] memory) {
        return ownerToListAuction[spender];
    }

    // get an auction from uuid
    function getAuctionFromUuid(uint256 uuid) public view returns(Auction memory) {
        return uuidToAuction[uuid];
    }




}