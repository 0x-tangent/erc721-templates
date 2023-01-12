// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { DSTest } from "ds-test/test.sol";

import "../MyNft.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

abstract contract Hevm {
  function warp(uint256) public virtual;
  function roll(uint256) public virtual;
}

contract User is ERC721Holder {

  MyNft myNft;
  constructor(MyNft _myNft) {
    myNft = _myNft;
  }

  function mint() public {
    _mint();
  }
  function badMintPrice() public {
    _mint();
  }
  // OPTION:MAX_PER_WALLET=2+
  // function mint(uint256 amount) public {
  //   _mint(amount);
  // }
  // function badMintPrice(uint256 amount) public {
  //   _mint(amount);
  // }
  function premint(bytes32[] calldata proof) public {
    myNft.premint(proof);
  }
  function _mint() internal {
    myNft.mint();
  }
  // OPTION:MAX_PER_WALLET=2+
  // function premint(uint256 amount, bytes32[] calldata proof) public {
  //   myNft.premint(amount, proof);
  // }
  // OPTION:MAX_PER_WALLET=2+
  // function _mint(uint256 amount) internal {
  //   myNft.mint(amount);
  // }
  function transfer(address to, uint256 tokenId) public {
    transferFor(address(this), to, tokenId);
  }
  function transferFor(address from, address to, uint256 tokenId) public {
    myNft.transferFrom(from, to, tokenId);
  }
  function approve(address to, uint256 tokenId) public {
    myNft.approve(to, tokenId);
  }
  function approveAll(address to, bool isApproved) public {
    myNft.setApprovalForAll(to, isApproved);
  }
  function burn(uint256 tokenId) public {
    myNft.burn(tokenId);
  }

  function setBaseURI(string memory uri) public {
    myNft.setBaseURI(uri);
  }
  function setMintStartTime(uint256 _startTime) public {
    myNft.setMintStartTime(_startTime);
  }
  function setIsRevealed(bool isRevealed) public {
    myNft.setIsRevealed(isRevealed);
  }


  function withdraw(address to, uint amount) public {
    myNft.withdraw(to, amount);
  }

  function receivePayment() public payable {}

  function deposit() payable public returns (bool success) {
    return true;
  }
}

contract MyNftTest is DSTest {
  MyNft myNft;
  User userA;
  User userB;
  User userC;
  User userNoFunds;
  Hevm hevm;

  address constant user      = address(0xFdeAA01bbac12C37d2F90Fe8B988b76719089E47);
  string  constant BASE_URI  = "ipfs://BASE_URI/";
  string  constant COVER_URI = "ipfs://COVER_URI";

  function setUp() public {
    myNft = new MyNft(COVER_URI);
    userA = new User(myNft);
    userB = new User(myNft);
    userC = new User(myNft);
    userNoFunds = new User(myNft);
    hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    hevm.warp(1673481797);
    uint256 eth = 100 ether;
    userA.deposit{value: eth}();
    userB.deposit{value: eth}();
    userC.deposit{value: eth}();
  }

  function testMintOne() public {
    userA.mint();
    uint256 balance = myNft.balanceOf(address(userA));
    assertEq(1, balance);
  }
  // IGNORE:MAX_PER_WALLET=1
  // function testMintTwoAtOnce() public {
  //   userA.mint();
  //   uint256 balance = myNft.balanceOf(address(userA));
  //   assertEq(2, balance);
  // }
  // IGNORE:MAX_PER_WALLET=1
  // function testMintTwoSequentially() public {
  //   userA.mint();
  //   uint256 balance1 = myNft.balanceOf(address(userA));
  //   assertEq(1, balance1);
  //   userA.mint();
  //   uint256 balance2 = myNft.balanceOf(address(userA));
  //   assertEq(2, balance2);
  // }
  function testFailMintTwo() public {
    userA.mint();
    userA.mint();
  }
  function testBurnAdjustsUserBalance() public {
    userA.mint();

    uint256 balance1 = myNft.balanceOf(address(userA));
    assertEq(balance1, 1);
    userA.burn(0);

    uint256 balance2 = myNft.balanceOf(address(userA));
    assertEq(balance2, 0);
  }

  function testBurnAdjustsTotalSupply() public {
    userA.mint();
    userB.mint();
    userC.mint();
    uint256 postMintSupply = myNft.totalSupply();
    assertEq(postMintSupply, 3);

    userA.burn(0);
    userC.burn(2);

    uint256 postBurnSupply = myNft.totalSupply();
    assertEq(postBurnSupply, 1);
  }

  function testBurnedTokensAreZeroWithNoBurns() public {
    assertEq(myNft.burnedTokens(), 0);
    userA.mint();
    assertEq(myNft.burnedTokens(), 0);
    userA.burn(0);
    assertEq(myNft.burnedTokens(), 1);
  }

  function testFailBurnWithZeroOwned() public {
    userA.burn(0);
  }
  function testFailBurnWithUnownedToken() public {
    userA.mint();
    userB.mint();
    userC.mint();
    userA.burn(2);
  }
  function testBurnPreservesOwnership() public {
    userA.mint();
    userB.mint();
    userC.mint();
    userC.transfer(address(userA), 2);
    assertEq(myNft.balanceOf(address(userA)), 2);
    assertEq(myNft.owners(0), address(userA));
    assertEq(myNft.owners(1), address(userB));
    assertEq(myNft.owners(2), address(userA));

    userA.burn(0);

    assertEq(myNft.balanceOf(address(userA)), 1);
    assertEq(myNft.owners(0), address(0));
    assertEq(myNft.owners(1), address(userB));
    assertEq(myNft.owners(2), address(userA));
  }

  // IGNORE:MAX_PER_WALLET=1
  // function testTokenOfOwnerByIndex() public {
  //   userA.mint();
  //   userB.mint();
  //
  //   assertEq(myNft.tokenOfOwnerByIndex(address(userA), 0), 0);
  //   assertEq(myNft.tokenOfOwnerByIndex(address(userA), 1), 1);
  //   assertEq(myNft.tokenOfOwnerByIndex(address(userB), 0), 2);
  // }
  function testBurnAndTokenOfOwnerByIndexPreservesOwnership() public {
    userA.mint();
    userB.mint();
    userB.transfer(address(userA), 1);
    assertEq(myNft.tokenOfOwnerByIndex(address(userA), 0), 0);
    assertEq(myNft.tokenOfOwnerByIndex(address(userA), 1), 1);
    assertEq(myNft.balanceOf(address(userA)), 2);

    userA.burn(1);
    assertEq(myNft.balanceOf(address(userA)), 1);
    assertEq(myNft.tokenOfOwnerByIndex(address(userA), 0), 0);
  }

  function testFailTokenOfOwnerByIndex() public {
    userA.mint();
    myNft.tokenOfOwnerByIndex(address(userA), 2);
  }

  // IGNORE:FREE_MINT
  // function testFailMintWrongAmount() public {
  //   userA.badMintPrice(1);
  // }
  // IGNORE:FREE_MINT
  // function testFailMintNotEnoughFunds() public {
  //   userNoFunds.mint();
  // }

  function testTransferToUserB() public {
    userA.mint();
    assertEq(myNft.owners(0), address(userA));
    assertEq(myNft.balanceOf(address(userA)), 1);
    assertEq(myNft.balanceOf(address(userB)), 0);
    userA.transfer(address(userB), 0);
    assertEq(myNft.owners(0), address(userB));
    assertEq(myNft.balanceOf(address(userA)), 0);
    assertEq(myNft.balanceOf(address(userB)), 1);
  }

  function testFailTransferWithoutApproval() public {
    userA.mint();
    userB.transferFor(address(userA), address(userC), 0);
  }

  function testTransferForWithApprove1() public {
    userA.mint();
    userA.approve(address(userB), 0);
    userB.transferFor(address(userA), address(userC), 0);
    assertEq(myNft.balanceOf(address(userA)), 0);
    assertEq(myNft.balanceOf(address(userC)), 1);
  }
  function testFailApproveForUnownedToken() public {
    userA.mint();
    userB.approve(address(userA), 0);
  }
  function testFailApproveForNonexistentToken() public {
    userA.mint();
    userA.approve(address(userA), 1);
  }
  function testTransferForWithApproveAll() public {
    userA.mint();
    userA.approveAll(address(userB), true);
    userB.transferFor(address(userA), address(userC), 0);
  }
  function testFailTransferForWithRevokedApproval() public {
    userA.mint();
    userA.approveAll(address(userB), true);
    userB.transferFor(address(userA), address(userC), 0);
    userA.approveAll(address(userB), false);
    userB.transferFor(address(userA), address(userC), 1);
  }
  function testFailTransferForUnownedTokens() public {
    userA.mint();
    userC.mint();
    userA.approveAll(address(userB), true);
    userB.transferFor(address(userA), address(userC), 4);
  }

  // IGNORE:MAX_PER_WALLET=1
  // function testTokenByIndex() public {
  //   userA.mint();
  //   uint256 tokenIndex = myNft.tokenByIndex(1);
  //   assertEq(tokenIndex, 1);
  // }

  function testBaseUriNotSetAtDeploy() public {
    string memory contractUri = myNft.baseURI();
    assertEq(contractUri, "");
  }
  function testTokenUriReturnsValueAfterReveal() public {
    userA.mint();

    myNft.setBaseURI("ipfs://BASE/");
    myNft.setIsRevealed(true);
    string memory tokenURI = myNft.tokenURI(0);
    assertEq(tokenURI, "ipfs://BASE/0.json");
  }
  function testTokenUriReturnsCoverUriBeforeReveal() public {
    userA.mint();

    string memory tokenURI = myNft.tokenURI(0);
    assertEq(tokenURI,COVER_URI);
  }
  function testTokenUriReturnBaseUriAfterReveal() public {
    userA.mint();
    myNft.setBaseURI(BASE_URI);
    myNft.setIsRevealed(true);
    string memory tokenURI = myNft.tokenURI(0);
    assertEq(tokenURI, "ipfs://BASE_URI/0.json");
  }
  function testOwnerCanSetBaseUri() public {
    string memory uri = "ipfs://BASE/";
    myNft.setBaseURI(uri);

    string memory contractUri = myNft.baseURI();
    assertEq(contractUri, uri);
  }
  function testFailSetBaseUri_NotOwner() public {
    userA.setBaseURI("ipfs://FAIL/");
  }
  function testOwnerCanSetIsMintStartTime() public {
    myNft.setMintStartTime(1);
    uint256 startBlock = myNft.mintStartTime();
    assertTrue(startBlock == 1);
  }
  function testFailSetIsMintStartTime_NotOwner() public {
    userA.setMintStartTime(1);
  }
  function testOwnerCanSetIsRevealed() public {
    myNft.setIsRevealed(true);
    bool isRevealed = myNft.isRevealed();
    assertTrue(isRevealed);
  }
  function testFailSetIsRevealed_NotOwner() public {
    userA.setIsRevealed(true);
  }
  function testFailMint_GivenStartTimeIsInFuture() public {
    // Mon Jan  1 00:00:00 EST 2024
    myNft.setMintStartTime(1704085200);
    userA.mint();
  }
  function testFailMint_GivenHEVMIsWarpedToThePast() public {
    hevm.warp(160000000);
    userA.mint();
  }

  // IGNORE:FREE_MINT
  // function testWithdrawFromOwnerSucceeds() public {
  //   userA.mint();
  //   address receiver = address(0x123);
  //   uint receiverInitial = receiver.balance;
  //   assertEq(0.1 ether, address(myNft).balance);
  //   myNft.withdraw(address(receiver), 0.1 ether);
  //   assertEq(0 ether, address(myNft).balance);
  //   uint receiverFinal = receiver.balance;
  //   assertEq(0.1 ether, receiverFinal - receiverInitial);
  // }

  function testFailWithdrawFrom_NotOwner() public {
    userA.mint();
    address receiver = address(0x123);
    userA.withdraw(address(receiver), 0.1 ether);
  }
}

