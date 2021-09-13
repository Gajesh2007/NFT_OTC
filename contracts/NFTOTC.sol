pragma solidity ^0.8.0;

import './@openzeppelin/contracts/token/ERC721/ERC721.sol';
import './@openzeppelin/contracts/access/Ownable.sol';

contract NFTOTC is Ownable {
    struct OTC {
        address nft1;
        address nft2;
        address counterParty1;
        address counterParty2;
        uint8 nftId1;
        uint8 nftId2;
        uint256 expires;
        bool executed;
    }

    OTC[] public otcInfo;
    bool paused;
    uint256 fee;

    constructor() {
        paused = false;
        fee = 0;
    }

    function createOTC(address nft1, address nft2, address counterParty1, address counterParty2, uint8 nftId1, uint8 nftId2, uint256 expires) external payable {
        require(paused == false, "Contract is Paused");
        require(msg.value >= fee, "less than the platform fee");
        otcInfo.push(OTC({nft1: nft1, nft2: nft2, counterParty1:counterParty1, counterParty2:counterParty2, nftId1: nftId1, nftId2: nftId2, expires: (expires+block.timestamp), executed: false}));
    }

    function execOTC(uint256 _otcId) external {
        OTC storage otc = otcInfo[_otcId];
        require(block.timestamp <= otc.expires, "OTC Expired");
        require(otc.executed == false, "OTC is already executed");
        require(msg.sender == otc.counterParty2, "you are not the counterParty");
        IERC721(otc.nft2).transferFrom(otc.counterParty2, otc.counterParty1, otc.nftId2);
        IERC721(otc.nft1).transferFrom(otc.counterParty1, otc.counterParty2, otc.nftId1);
        otc.executed = true;
    }

    function cancelOTC(uint256 _otcId) external {
        OTC storage otc = otcInfo[_otcId];
        require(msg.sender == otc.counterParty1, "you are not the counterParty");
        otc.executed = true;
    }

    function pause() external {
        paused = true;
    }

    function unpause() external {
        paused = false;
    }

    function changeFee(uint256 _fee) external {
        fee = _fee;
    }

    function withdrawTip(uint256 _tip, address payable receipt) external onlyOwner {
        receipt.transfer(_tip);
    }
}