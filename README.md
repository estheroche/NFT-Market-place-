NFTMarket
Introduction
NFTMarket is a smart contract repository that facilitates the listing and selling of NFTs by sellers. Sellers can bring in their NFTs for listing, and buyers can execute purchases through this platform.

Functions
createListing
Allows a seller to create a listing for their NFT.

Parameters
tokenAddress: Address of the NFT contract.
tokenId: ID of the NFT to be listed.
price: Price set by the seller for the NFT.
sign: Placeholder for the signature.
deadline: Deadline for the listing.
isActive: Flag indicating if the listing is active.
Preconditions
Owner

Check that the owner is the true owner of the specified tokenId using ownerOf().
Verify that the owner has approved the smart contract to spend tokens from tokenAddress using isApprovedForAll().
Token Address

Ensure that the token address is valid (not address(0)).
Verify that the token address has associated code.
Price

Confirm that the price set by the seller is greater than 0.
Logic
Store the listing data in storage.
Increment the listing ID counter.
Emit an event indicating the successful creation of the listing.
executeListing (payable)
Allows a buyer to execute the purchase of a listed NFT.

Parameters
listingId: ID of the listing to be executed.
Preconditions
Verify that the listingId is less than the public counter.
Ensure that the sent Ether value (msg.value) matches the listing price.
Confirm that the current block timestamp is before the listing's deadline.
Validate the provided signature, ensuring it is signed by the listing owner.
Logic
Retrieve the listing data from storage.
Transfer Ether from the buyer to the seller.
Transfer the NFT from the seller to the buyer.
Emit an event indicating the successful execution of the purchase.
Onchain Signature
Utilizes user address and smart contract address for security checks, leveraging the OpenZeppelin ECDSA.sol library for cryptographic operations.
