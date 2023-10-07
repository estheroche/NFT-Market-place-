// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {NFTMarket} from "../src/NFTMarket.sol";
import "../src/ERC721Mock.sol";
import "./Helpers.sol";

contract NFTMarketTest is Helpers {
    NFTMarket mPlace;
    OurNFT nft;

    uint256 currentListingId;

    address addrA;
    address addrB;

    uint256 privKeyA;
    uint256 privKeyB;

    NFTMarket.ListingData l;

    function setUp() public {
        mPlace = new NFTMarket();
        nft = new OurNFT();

        (addrA, privKeyA) = mkaddr("ADDRA");
        (addrB, privKeyB) = mkaddr("ADDRB");

        l = NFTMarket.ListingData({
           tokenAddress: address(nft),
            tokenId: 1,
           priceInWei: 1e18,
            signature: bytes(""),
            expiryTime: 0,
           listerAddress: address(addrA),
           isActive: false
        });

        // mint NFT
        nft.mint(addrA, 1);
    }

    function testNotOwnerListing() public {
        l.listerAddress = addrB;
        switchSigner(addrB);

        vm.expectRevert(NFTMarket.NotOwner.selector);
        mPlace.createCustomListing(l);
    }

    function testNonApproved() public {
        switchSigner(addrA);
        vm.expectRevert(NFTMarket.NotApproved.selector);
        mPlace.createCustomListing(l);
    }

    function testMinPriceTooLow() public {
        switchSigner(addrA);
        nft.setApprovalForAll(address(mPlace), true);
        l.priceInWei = 0;
        vm.expectRevert(NFTMarket.MinPriceTooLow.selector);
        mPlace.createCustomListing(l);
    }

    function testMinDurationNotMet() public {
        switchSigner(addrA);
        l.expiryTime = uint88(block.timestamp);
        nft.setApprovalForAll(address(mPlace), true);
        vm.expectRevert(NFTMarket. MinDurationNotMet.selector);
        mPlace.createCustomListing(l);
    }

    function testInValidSignature() public {
        switchSigner(addrA);
        nft.setApprovalForAll(address(mPlace), true);
        l.expiryTime = uint88(block.timestamp + 120 minutes);
        l.signature = constructSig(
            l.tokenAddress,
            l.tokenId,
            l.priceInWei,
            l.expiryTime,
            l.listerAddress,
            privKeyB
        );
        vm.expectRevert(NFTMarket.InvalidSignature.selector);
        mPlace.createCustomListing(l);
    }
    

    // EDIT LISTING
    function testListingNotExistent() public {
        switchSigner(addrA);
        vm.expectRevert(NFTMarket.ListingNotExistent.selector);
        mPlace.executeCustomListing(l.tokenId);
    }

    function testListingNotActive() public {
        switchSigner(addrA);
        l.expiryTime = uint88(block.timestamp + 120 minutes);
        l.signature = constructSig(
            l.tokenAddress,
            l.tokenId,
            l.priceInWei,
            l.expiryTime,
            l.listerAddress,
            privKeyA
        );
    }
     
        function testListerNotOwner() public {
        switchSigner(addrA);
        nft.setApprovalForAll(address(mPlace), true);
       l.expiryTime = uint88(block.timestamp + 120 minutes);
        l.signature = constructSig(
            l.tokenAddress,
            l.tokenId,
            l.priceInWei,
            l.expiryTime,
            l.listerAddress,
            privKeyA
        );
        uint256 lId = mPlace.createCustomListing(l);;
        switchSigner(addrB);
        vm.expectRevert(NFTMarket.NotOwner.selector);
        mPlace.editCustomListing(lId, 0, false);
        
    }
    
    function testEditListing() public {
        switchSigner(addrA);
        nft.setApprovalForAll(address(mPlace), true);
       l.expiryTime = uint88(block.timestamp + 120 minutes);
        l.signature = constructSig(
            l.tokenAddress,
            l.tokenId,
            l.priceInWei,
            l.expiryTime,
            l.listerAddress,
            privKeyA
        );
        uint256 lId = mPlace.createCustomListing(l);
        mPlace.editCustomListing(lId, 0.01 ether, false);

       NFTMarket.ListingData memory t = mPlace.getCustomListing(lId);
        assertEq(t.priceInWei, 0.01 ether);
        assertEq(t.isActive, false);
    }

    // EXECUTE LISTING
    function testExecuteNonValidListing() public {
        switchSigner(addrA);
        vm.expectRevert(NFTMarket.ListingNotExistent.selector);
        mPlace.executeCustomListing(1);
    }

    function testExecuteExpiredListing() public {
        switchSigner(addrA);
        nft.setApprovalForAll(address(mPlace), true);
    }

    function testExecuteListingNotActive() public {
        switchSigner(addrA);
        nft.setApprovalForAll(address(mPlace), true);
         l.expiryTime = uint88(block.timestamp + 120 minutes);
        l.signature = constructSig(
            l.tokenAddress,
            l.tokenId,
            l.priceInWei,
            l.expiryTime,
            l.listerAddress,
            privKeyA
        );
        uint256 lId = mPlace.createCustomListing(l);
        mPlace.editCustomListing(lId, 0.01 ether, false);
        switchSigner(addrB);
        vm.expectRevert(NFTMarket.ListingNotActive.selector);
        mPlace.executeCustomListing(lId);
    }

    function testExecutePriceNotMet() public {
        switchSigner(addrA);
        nft.setApprovalForAll(address(mPlace), true);
        l.expiryTime = uint88(block.timestamp + 120 minutes);
        l.signature = constructSig(
            l.tokenAddress,
            l.tokenId,
            l.priceInWei,
            l.expiryTime,
            l.listerAddress,
            privKeyA
        );
        uint256 lId = mPlace.createCustomListing(l);
        switchSigner(addrB);
        vm.expectRevert(
            abi.encodeWithSelector(
                NFTMarket.PriceNotMet.selector,
                l.priceInWei - 0.7 ether
            )
        );
        mPlace.executeCustomListing{value: 0.7 ether}(lId);
    }

    function testExecute() public {
        switchSigner(addrA);
        nft.setApprovalForAll(address(mPlace), true);
       l.expiryTime = uint88(block.timestamp + 120 minutes);
        l.signature = constructSig(
            l.tokenAddress,
            l.tokenId,
            l.priceInWei,
            l.expiryTime,
            l.listerAddress,
            privKeyA
        );
        uint256 lId = mPlace.createCustomListing(l);
        switchSigner(addrB);
        uint256 addrABalanceBefore = addrA.balance;

        mPlace.executeCustomListing{value: l.priceInWei}(lId);

       NFTMarket.ListingData memory t = mPlace.getCustomListing(lId);
        assertEq(t.priceInWei, 1 ether);
        assertEq(t.isActive, false);
        assertEq(t.isActive, false);
        assertEq(ERC721(l.tokenAddress).ownerOf(l.tokenId), addrB);
    }

}

