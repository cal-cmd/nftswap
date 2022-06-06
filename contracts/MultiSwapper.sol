// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


// BIG THINGS TO THINK ABOUT
//
// - Add data param for safeTransferFrom() for erc721reciever etc
//
// - User should be able to openSwap that anyone can join, or that only a specific address can join/pay for
//
// - ADD PAUSE FUNCTION / MODIFIER TO PREVENT/STOP TRADES WHEN NEEDED
//

contract MultiSwapper is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private _swapIds;

    // emitted when new swap request is opened // uint indexed time <--- REMOVED FOR TESTING
    event Opened(address indexed walletOne, address indexed walletTwo, uint swapId);
    // emitted when second user approves funds? 
    event Cancelled(address indexed walletOne, address indexed walletTwo);
    // emitted when swap is closed // uint indexed time <--- REMOVED FOR TESTING
    event Closed(address indexed walletOne, address indexed walletTwo, uint swapId);
    // emitted when swap is closed successfully

    enum swapStatus { Opened, Closed, Cancelled }
    enum tokenType { None, Erc721, Erc1155, Erc20 }
    enum contractStatus { Unverified, Verified, Banned }

    struct Swap {
        uint valueOne;
        uint valueTwo;
        uint swapFee;
        address payable walletOne;
        address payable walletTwo;
        swapStatus status;
    }

    struct Item {
        address contractAddress;
        tokenType standard;
        uint tokenId;
        uint tokenAmount;
    }

    mapping(uint => Swap) public swaps;

    mapping(uint => Item[]) public nftsOne;
    mapping(uint => Item[]) public nftsTwo;

    mapping(address => contractStatus) public contractList;

    uint public swapFee = 5 ether; // 5 MATIC
    address payable public tradePassContract;
    address payable public devWallet;

    constructor(address _tradePassAddress) {
        tradePassContract = payable(_tradePassAddress);
        devWallet = payable(msg.sender);
    }

    function openSwap(Swap memory _swap, Item[] memory _nftsOne, Item[] memory _nftsTwo) public payable nonReentrant {
        // if(IERC721(tradePassContract).balanceOf(msg.sender) == 0) {
        //     require(msg.value >= swapFee, "Please check sent value matches the swap fee");
        //     swaps[_swapIds.current()].swapFee += swapFee;

        //     if(_swap.valueOne != 0) {
        //     require(_swap.valueOne == (msg.value - swapFee), "Not enough native currency");
        //     }

        // } else {
        //     require(_swap.valueOne == msg.value, "Not enough native currency");       
        // }

        require(msg.sender != _swap.walletTwo, "You cannot trade with yourself");
        require(_nftsOne.length <= 10 && _nftsTwo.length <= 10, "You can only list up to 10 NFTs/Tokens per party");

        uint currentId = _swapIds.current();
        _swap.walletOne = payable(msg.sender);
        _swap.status = swapStatus.Opened;

        swaps[currentId] = _swap;

        for(uint n; n < _nftsOne.length; n++) {
            nftsOne[currentId].push(_nftsOne[n]);
        }

        for(uint n; n < _nftsTwo.length; n++) {
            nftsTwo[currentId].push(_nftsTwo[n]);
        }

        emit Opened(msg.sender, swaps[currentId].walletTwo, currentId);
        _swapIds.increment();
    }

    function closeSwap(uint swapId) public payable nonReentrant {
        require(swaps[swapId].status == swapStatus.Opened, "Swap already closed");
        require(swaps[swapId].walletTwo == msg.sender, "Not intended trade counterparty");

        if(IERC721(tradePassContract).balanceOf(msg.sender) == 0) {
            require(msg.value >= swapFee, "Please check sent value matches the swap fee");
            swaps[swapId].swapFee += swapFee;

            if(swaps[swapId].valueTwo != 0) {
            require(swaps[swapId].valueTwo == (msg.value - swapFee), "Not enough native currency");
            }

            (bool success, ) = devWallet.call{value: swaps[swapId].swapFee}("");
            require(success, "Transfer failed.");

        } else {
            require(swaps[swapId].valueTwo == msg.value, "Not enough native currency");

            if(swaps[swapId].swapFee > 0) {
                (bool success, ) = devWallet.call{value: swaps[swapId].swapFee}("");
                require(success, "Transfer failed.");
            }
        }

        if(nftsOne[swapId].length != 0) {
            for(uint n; n < nftsOne[swapId].length; n++) {

                require(contractList[nftsOne[swapId][n].contractAddress] != contractStatus.Banned, "Contract is banned");

                if(nftsOne[swapId][n].standard == tokenType.None) {
                    continue;
                }

                if(nftsOne[swapId][n].standard == tokenType.Erc721) {
                    IERC721(nftsOne[swapId][n].contractAddress).safeTransferFrom(swaps[swapId].walletOne, swaps[swapId].walletTwo, nftsOne[swapId][n].tokenId);
                    continue;
                }

                if(nftsOne[swapId][n].standard == tokenType.Erc1155) {
                    IERC1155(nftsOne[swapId][n].contractAddress).safeTransferFrom(swaps[swapId].walletOne, swaps[swapId].walletTwo, nftsOne[swapId][n].tokenId, nftsOne[swapId][n].tokenAmount, "");
                    continue;
                }
                
                if(nftsOne[swapId][n].standard == tokenType.Erc20) {
                    IERC20(nftsOne[swapId][n].contractAddress).transferFrom(swaps[swapId].walletOne, swaps[swapId].walletTwo, nftsOne[swapId][n].tokenAmount);
                    continue;
                }
            }
        }

        if(swaps[swapId].valueOne > 0) {
            (bool success, ) = swaps[swapId].walletTwo.call{value: swaps[swapId].valueOne}("");
            require(success, "Transfer failed.");
        }

        if(nftsTwo[swapId].length != 0) {
            for(uint n; n < nftsTwo[swapId].length; n++) {

                require(contractList[nftsTwo[swapId][n].contractAddress] != contractStatus.Banned, "Contract is banned");

                if(nftsTwo[swapId][n].standard == tokenType.None) {
                    continue;
                }

                if(nftsTwo[swapId][n].standard == tokenType.Erc721) {
                    IERC721(nftsTwo[swapId][n].contractAddress).safeTransferFrom(swaps[swapId].walletTwo, swaps[swapId].walletOne, nftsTwo[swapId][n].tokenId);
                    continue;
                }

                if(nftsTwo[swapId][n].standard == tokenType.Erc1155) {
                    IERC1155(nftsTwo[swapId][n].contractAddress).safeTransferFrom(swaps[swapId].walletTwo, swaps[swapId].walletOne, nftsTwo[swapId][n].tokenId, nftsTwo[swapId][n].tokenAmount, "");
                    continue;
                }
                
                if(nftsTwo[swapId][n].standard == tokenType.Erc20) {
                    IERC20(nftsTwo[swapId][n].contractAddress).transferFrom(swaps[swapId].walletTwo, swaps[swapId].walletOne, nftsTwo[swapId][n].tokenAmount);
                    continue;
                }
            }
        }

        if(swaps[swapId].valueTwo > 0) {
            (bool success, ) = swaps[swapId].walletOne.call{value: swaps[swapId].valueTwo}("");
            require(success, "Transfer failed.");
        }

        swaps[swapId].status = swapStatus.Closed;

        emit Closed(swaps[swapId].walletOne, msg.sender, swapId);
    }

    function cancelSwap() public nonReentrant {}

    function changeFee(uint newFee) public onlyOwner {
        swapFee = newFee;
    }

    function setTradePassAddress(address _tradePassAddress) public onlyOwner {
        tradePassContract = payable(_tradePassAddress);
    }

    function verifyContract(address _contractAddress) public onlyOwner {
        contractList[_contractAddress] = contractStatus.Verified;
    }

    function banContract(address _contractAddress) public onlyOwner {
        contractList[_contractAddress] = contractStatus.Banned;
    }
}
