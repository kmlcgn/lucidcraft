// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts@4.4.1/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.4.1/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@4.4.1/access/Ownable.sol";
import "@openzeppelin/contracts@4.4.1/utils/Counters.sol";

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract InitialToken is ChainlinkClient, ERC721, ERC721URIStorage, Ownable {
    using Chainlink for Chainlink.Request;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    uint256 internal ORACLE_PAYMENT = 0.1 * 10**18; // 0.1 LINK  

    // below strings are harcoded for testing purposes only. 
    string internal tshirt_uri = "https://ipfs.io/ipfs/QmZFzA1767ZWSRRrW8ny2j6MiBb5J1SvyBc4NZa2x4cLoe/2740";
    string internal other_nft_uri = "https://ipfs.io/ipfs/QmZFzA1767ZWSRRrW8ny2j6MiBb5J1SvyBc4NZa2x4cLoe/2740"; 

    // Contract address and token id of the NFT which will be printed to the t-shirt
    struct NFTData { 
      address contractAddress;
      uint256 tokenId;
    }

    // Attributes of the request which we will use
    struct RequestData {  // Not "Request", could be confused with Chainlink.Request
        address requester;
        uint256 tshirtId;
        NFTData nftData;
    }

    // owner of the NFT
    mapping(address => NFTData) public addressToNFTData;

    // is the tokenURI changed for this ID
    mapping(uint256 => bool) public hasChanged;

    mapping(uint256 => string) public newURIs;

    // each nft can be printed only once.
    mapping(bytes32 => bool) public isNftUsed;

    // map each request to its attributes to be used later
    mapping(bytes32 => RequestData) reqToRequestData;

    // _link = the LINK token address on this networkh
    
    constructor() ERC721("LucidCraft", "LUCID") 
    {   
        //Operator.sol instead of Oracle.sol here
        setChainlinkOracle(0x5502162EA889695E3c82c81b150502269A634a0D);
        setPublicChainlinkToken();
    }

    // mint the tshirt
    function safeMint(address to, string memory uri) external {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        //_setTokenURI(tokenId, uri);
        newURIs[tokenId] = uri;
    }

    //helper function
    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }
    //helper function
    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    //helper function
    function stringToBytes32(string memory source) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly { // solhint-disable-line no-inline-assembly
            result := mload(add(source, 32))
        }
    }

    // merge button: print the nft to the tshirt
    function mergeButton(string memory _jobId, uint256 tshirtId, address nftContractAddress, uint256 nftId)
        external
    {
        require(ownerOf(tshirtId) == msg.sender, "You do not own the tshirt");
        require(_isTheAddressOwner(nftContractAddress, nftId), "You do not own the NFT!");
        require(!_isNftAlreadyUsed(nftContractAddress,nftId), "NFT is already used");

        NFTData memory nftData = NFTData(nftContractAddress, nftId);
        addressToNFTData[msg.sender] = nftData;

        require(hasChanged[tshirtId] == false, "You have already printed");
                
        Chainlink.Request memory req = buildChainlinkRequest(stringToBytes32(_jobId), address(this), this.fulfill.selector);
        //req.add("nftContractAddress", toAsciiString(nftContractAddress));
        //req.addUint("nftId", nftId);        
        //req.add("tshirtContractAddress", toAsciiString(address(this))); 
        //req.addUint("tshirtId", tshirtId);  
        req.add("tshirt_uri", tshirt_uri);
        req.add("other_nft_uri", other_nft_uri);      

        // Send request to the oracle
        bytes32 requestId = sendOperatorRequest(req, ORACLE_PAYMENT);

        reqToRequestData[requestId] = RequestData(msg.sender, tshirtId, nftData);
    }

    // Fulfill the Chainlink request by returning the new URI
    function fulfill(bytes32 _requestId, string memory newURI)
        external 
        recordChainlinkFulfillment(_requestId)
    {
        RequestData memory requestData = reqToRequestData[_requestId];
        delete reqToRequestData[_requestId];

        NFTData memory nftData = requestData.nftData;
        bytes32 hashOfNftData = keccak256(abi.encode(nftData));

        //these requires are for preventing double calling
        require(hasChanged[requestData.tshirtId] == false, "Tshirt is already used");

        require(isNftUsed[hashOfNftData] == false, "NFT is already used");

        // Check if request sender is equal to the owner of tshirt
        require(requestData.requester == ownerOf(requestData.tshirtId), "Request sender is different from owner of the Tshirt"); 

        // Check if request sender is equal to the owner of NFT
        require(requestData.requester == _getTheAddressOwner(nftData.contractAddress, nftData.tokenId), "Request sender is different from owner of the NFT");

        hasChanged[requestData.tshirtId] = true;
        isNftUsed[hashOfNftData] = true;

        newURIs[requestData.tshirtId] = newURI;    

    }
    //helper function
    function bytesToString(bytes memory _bytes) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 256 && _bytes[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 256 && _bytes[i] != 0; i++) {
            bytesArray[i] = _bytes[i];
        }
        return string(bytesArray);
    }

    address private constant cryptopunkAddress = 0x693487a7641944AA96Fc2741724BB6a66923bf3f;
    // On main chain: 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB

    function _isTheAddressOwner(address nftContractAddress, uint256 nftId) internal returns(bool) {
        if(nftContractAddress == cryptopunkAddress)
            return _isTheAddressOwner_Cryptopunk(nftContractAddress, nftId);
        
        (bool success, bytes memory data) =  nftContractAddress.call(abi.encodeWithSignature("ownerOf(uint256)", nftId));
        require(success, "External function call failed."); // cannot check
        return abi.decode(data, (address)) == msg.sender;
    }

    // getTheAddressOwner_CryptoPunk
    function _getTheAddressOwner_Cryptopunk(address nftContractAddress, uint256 nftId) 
        internal 
        returns(address) 
    {
        require(nftContractAddress == cryptopunkAddress, "Address is not Cryptopunk but judged as one");
        return Cryptopunk(nftContractAddress).punkIndexToAddress(nftId);
    }

    function _getTheAddressOwner(address nftContractAddress, uint256 nftId) internal returns(address) {
        if(nftContractAddress == cryptopunkAddress)
            return _getTheAddressOwner_Cryptopunk(nftContractAddress, nftId);
        (bool success, bytes memory data) =  nftContractAddress.call(abi.encodeWithSignature("ownerOf(uint256)", nftId));
        require(success, "External function call failed."); // cannot check
        return abi.decode(data, (address));
    }

    function _isTheAddressOwner_Cryptopunk(address nftContractAddress, uint256 nftId) 
        internal 
        returns(bool) 
    {
        require(nftContractAddress == cryptopunkAddress, "Address is not Cryptopunk but judged as one"); 
        return Cryptopunk(nftContractAddress).punkIndexToAddress(nftId) == msg.sender;
    }

    function _isNftAlreadyUsed(address nftContractAddress, uint256 nftId)
        internal
        view
        returns(bool)
    {
        NFTData memory nftdata = NFTData(nftContractAddress, nftId);
        return isNftUsed[keccak256(abi.encode(nftdata))];
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return newURIs[tokenId];
    }

}

interface Cryptopunk {
    function punkIndexToAddress(uint _index) external returns(address); // a mapping in cryptopunk
}
