//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Chainlink Imports
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// This import includes functions from both ./KeeperBase.sol and
// ./interfaces/KeeperCompatibleInterface.sol
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

// Dev imports. This only works on a local dev network
// and will not work on any test or main livenets.
import "hardhat/console.sol";

contract BullBear is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counter.Counter private _tokenIdCounter;

    //ipfs URI for the dynamic nft graphics/metadata, they connect to your local ipfs companion node 
    //upload the contents of your ipfs folder to your local node for development purposes 
    string[] bullUrisIpfs = [
          "https://ipfs.io/ipfs/QmRJVFeMrtYS2CUVUM2cHJpBV5aX2xurpnsfZxLTTQbiD3?filename=party_bull.json",
      "https://ipfs.io/ipfs/QmRXyfi3oNZCubDxiVFre3kLZ8XeGt6pQsnAQRZ7akhSNs?filename=gamer_bull.json",
    ];
    string[] bearUriIpfs = [ 
         "https://ipfs.io/ipfs/Qmdx9Hx7FCDZGExyjLR6vYcnutUR8KhBZBnZfAPHiUommN?filename=beanie_bear.json",
        "https://ipfs.io/ipfs/QmTVLyTSuiKGUEmb88BgXG3qNC8YgpHZiFbjHrXKH3QHEu?filename=coolio_bear.json",
        "https://ipfs.io/ipfs/QmbKhBXVWmwrYsTPFYfroR2N7NAekAMxHUVg2CWks7i9qj?filename=simple_bear.json"
    ];

//initializing the contract and passing it the name and the sysmbol 
constructor() ERC721("BullandBear", "BBTK") {}

function safeMint(address to) public {
//Our Current counter will be the minted token's token ID 
uint256 tokenID = _tokenIdCounter.current();//assigning token id to the current tokenID counter that increases the current one 
//incrementing it so that next time we call the current method, it is accurate
_tokenIdCounter.increment();//calling increment method to increase the tokenID counter 

//lets now call the safemint method to mint the token to  particular wallet and with the allocated id 
_safeMint(to, tokenID);

//set default to always a bull nft 
string memory defaultUri = bullUrisIpfs[0];
_setTokenURI(tokenID, defaultUri);

console.log("Done!!! minted token ", tokenId, "and assigned token url:", defaultUri);
}

//the following functions are simply overrides required by solidity 
function _beforeTokenTransfer(
    address from, 
    address to, 
    uint256 tokenId
) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
}

//mechanisms of burning tokens
function burn(uint256 token) internal override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
 return super.tokenURI(tokenId);
}

function supportsInterface(bytes64 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
}

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Chainlink Imports
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// This import includes functions from both ./KeeperBase.sol and
// ./interfaces/KeeperCompatibleInterface.sol
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

// Dev imports. This only works on a local dev network
// and will not work on any test or main livenets.
import "hardhat/console.sol";

contract BullBear is ERC721, ERC721Enumerable, ERC721URIStorage,KeeperCompatibleInterface, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    AggregatorV3Interface public pricefeed;

    /** Use an interval in seconds and a timestamp to slow execution of upkeep 
    */
    uint public /* immutable */ interval;
    uint public lastTimeStamp;

    uint256 public currentPrice;

    // IPFS URIs for the dynamic nft graphics/metadata.
    // NOTE: These connect to my IPFS Companion node.
    // You should upload the contents of the /ipfs folder to your own node for development.
    string[] bullUrisIpfs = [
      "https://ipfs.io/ipfs/QmRJVFeMrtYS2CUVUM2cHJpBV5aX2xurpnsfZxLTTQbiD3?filename=party_bull.json",
      "https://ipfs.io/ipfs/QmRXyfi3oNZCubDxiVFre3kLZ8XeGt6pQsnAQRZ7akhSNs?filename=gamer_bull.json"

    ];
    string[] bearUrisIpfs = [
        "https://ipfs.io/ipfs/Qmdx9Hx7FCDZGExyjLR6vYcnutUR8KhBZBnZfAPHiUommN?filename=beanie_bear.json",
        "https://ipfs.io/ipfs/QmTVLyTSuiKGUEmb88BgXG3qNC8YgpHZiFbjHrXKH3QHEu?filename=coolio_bear.json",
        "https://ipfs.io/ipfs/QmbKhBXVWmwrYsTPFYfroR2N7NAekAMxHUVg2CWks7i9qj?filename=simple_bear.json"
    ];
     
     event TokensUpdated(string marketTrend);


    constructor(uint updateInterval, address _pricefeed) ERC721("Bull&Bear", "BBTK") {
        //set the keeper update interval 
        interval = updateInterval; 
        lastTimeStamp = block.timestamp; //seconds since unix epoch 

        //set the pricefeed address to BTC/USD pricefeed contract address on the rinkeby network 
        pricefeed = AggregatorV3Interface(_pricefeed);//to pass in the mock 

        //set price for the chosen currency pair 
        currentPrice = getLatestPrice();

    }

    function safeMint(address to) public {
        // Current counter value will be the minted token's token ID.
        uint256 tokenId = _tokenIdCounter.current();

        // Increment it so next time it's correct when we call .current()
        _tokenIdCounter.increment();

        // Mint the token
        _safeMint(to, tokenId);

        // Default to a bull NFT
        string memory defaultUri = bullUrisIpfs[0];
        _setTokenURI(tokenId, defaultUri);

        console.log(
            "DONE!!! minted token ",
            tokenId,
            " and assigned token url: ",
            defaultUri
        );
    }

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */ ){
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval; 
    }

    function performUpkeep(bytes calldata) external override {
        //It is highly recomended to revalidate upkeep in the perform upkeep functions 
        if ((block.timestamp - lastTimeStamp) > interval ) {
            lastTimeStamp = block.timestamp;
            int latestPrice = getLatestPrice();

            if (latestPrice == currentPrice) {
                console.log("NO CHANGE -> returning!");
                return;
            }

            if (latestPrice < currentPrice) {
                //bear 
                console.log("ITS BEAR TIME");
                updateAllTokenUris("bear");
            } else {
                //bull 
                console.log("ITS BULL TIME");
                updateAllTokenUris("bull");
            }

            //update currentPrice
            currentPrice = latestPrice;
        } else {
            console.log("INTERVAL NOT UP!");
            return; 
        }
    }

    //helpers 
    function getLatestPrice() public view returns (int256) {
        (
        /*uint80 roundID */
        int price, 
        /* uint startedAt */
        /* uint timeStamp */
        /* uint80 answeredInRound */
        )
        = pricefeed.latestRoundData();

        return price; //example price returned 3034715771688
    }

    //updating all the token uris 
    function updateAllTokenUris(string memory trend) internal 
    {
        if (compareString("bear", trend)) {
            console.log("UPDATING TOKEN URIS WITH ", "bear", trend); 
            for (uint i = 0; i < _tokenIdCounter.current(); i++) {
                _setTokenURI(i, bearUrisIpfs[0]);
            }

        } else {
            console.log("UPDATING PRICE WITH", "bull", trend);

            for (uint i = 0; i < _tokenIdCounter.current(); i++) {
                _setTokenURI(i, bearUrisIpfs[0]);
            }

        } 

        emit TokensUpdated(trend);
        } 
    
    function setPriceFeed(address newFeed) public onlyOwner {
        pricefeed = AggregatorV3Interface(newFeed);
    }

    function setInterval(uint256 newInterval) public onlyOwner {
        interval = newInterval;
    }
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}































