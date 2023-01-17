// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { DSTest } from "ds-test/test.sol";

import "../ComfyClouds.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

abstract contract Hevm {
  function warp(uint256) public virtual;
  function roll(uint256) public virtual;
}

contract User is ERC721Holder {

  ComfyClouds comfyClouds;
  constructor(ComfyClouds _comfyClouds) {
    comfyClouds = _comfyClouds;
  }

  function mint(uint amount) public {
    uint value = amount * 0.02 ether;
    _mint(amount, value);
  }
  function badMint(uint amount, uint eth) public {
    _mint(amount, eth);
  }
  function _mint(uint amount, uint eth) internal {
    comfyClouds.mint{ value: eth }(amount);
  }
  function transfer(address to, uint256 tokenId) public {
    transferFor(address(this), to, tokenId);
  }
  function transferFor(address from, address to, uint256 tokenId) public {
    comfyClouds.transferFrom(from, to, tokenId);
  }
  function approve(address to, uint256 tokenId) public {
    comfyClouds.approve(to, tokenId);
  }
  function approveAll(address to, bool isApproved) public {
    comfyClouds.setApprovalForAll(to, isApproved);
  }
  function burn(uint256 tokenId) public {
    comfyClouds.burn(tokenId);
  }

  function setBaseURI(string memory uri) public {
    comfyClouds.setBaseURI(uri);
  }
  function setIsRevealed(bool isRevealed) public {
    comfyClouds.setIsRevealed(isRevealed);
  }

  function withdraw(address to, uint amount) public {
    comfyClouds.withdraw(to, amount);
  }

  function receivePayment() public payable {}

  function deposit() payable public returns (bool success) {
    return true;
  }
}

contract ComfyCloudsTest is DSTest {
  ComfyClouds comfyClouds;
  User userA;
  User userB;
  User userC;
  User userNoFunds;

  address constant user      = address(0xFdeAA01bbac12C37d2F90Fe8B988b76719089E47);
  string  constant BASE_URI  = "ipfs://BASE_URI/";
  string  constant COVER_URI = "ipfs://COVER_URI";

  function setUp() public {
    comfyClouds = new ComfyClouds(COVER_URI);
    userA = new User(comfyClouds);
    userB = new User(comfyClouds);
    userC = new User(comfyClouds);
    userNoFunds = new User(comfyClouds);
    uint256 eth = 100 ether;
    userA.deposit{value: eth}();
    userB.deposit{value: eth}();
    userC.deposit{value: eth}();
  }

  function testMintOne() public {
    userA.mint(1);
    uint256 balance = comfyClouds.balanceOf(address(userA));
    assertEq(1, balance);
  }
  function testFailMintOne_NoEth() public {
    userA.badMint(1, 0);
  }
  function testFailMintOne_TooMuchEth() public {
    userA.badMint(1, 0.2 ether);
  }
  function testMintTwo() public {
    userA.mint(2);
    uint256 balance = comfyClouds.balanceOf(address(userA));
    assertEq(2, balance);
  }
  function testMintTwoSequentially() public {
    userA.mint(1);
    userA.mint(1);
    uint256 balance = comfyClouds.balanceOf(address(userA));
    assertEq(2, balance);
  }
  function testFailMintThree() public {
    userA.mint(3);
  }
  function testBurnAdjustsUserBalance() public {
    userA.mint(2);

    uint256 balance1 = comfyClouds.balanceOf(address(userA));
    assertEq(balance1, 2);
    userA.burn(1);

    uint256 balance2 = comfyClouds.balanceOf(address(userA));
    assertEq(balance2, 1);
  }

  function testBurnAdjustsTotalSupply() public {
    userA.mint(2);
    userB.mint(1);
    userC.mint(1);
    uint256 postMintSupply = comfyClouds.totalSupply();
    assertEq(postMintSupply, 4);

    userA.burn(1);
    userC.burn(4);

    uint256 postBurnSupply = comfyClouds.totalSupply();
    assertEq(postBurnSupply, 2);
  }

  function testBurnedTokensAreOneWithNoBurns() public {
    assertEq(comfyClouds.burnedTokens(), 1);
    userA.mint(1);
    assertEq(comfyClouds.burnedTokens(), 1);
    userA.burn(1);
    assertEq(comfyClouds.burnedTokens(), 2);
  }

  function testFailBurnWithZeroOwned() public {
    userA.burn(0);
  }
  function testFailBurnWithUnownedToken() public {
    userA.mint(2);
    userB.mint(1);
    userC.mint(1);
    userA.burn(3);
  }
  function testBurnPreservesOwnership() public {
    userA.mint(1);
    userB.mint(1);
    userC.mint(1);
    userC.transfer(address(userA), 3);
    assertEq(comfyClouds.balanceOf(address(userA)), 2);
    assertEq(comfyClouds.owners(1), address(userA));
    assertEq(comfyClouds.owners(2), address(userB));
    assertEq(comfyClouds.owners(3), address(userA));

    userA.burn(1);

    assertEq(comfyClouds.balanceOf(address(userA)), 1);
    assertEq(comfyClouds.owners(1), address(0));
    assertEq(comfyClouds.owners(2), address(userB));
    assertEq(comfyClouds.owners(3), address(userA));
  }

  function testBurnAndTokenOfOwnerByIndexPreservesOwnership() public {
    userA.mint(1);
    userB.mint(1);
    userB.transfer(address(userA), 2);
    assertEq(comfyClouds.tokenOfOwnerByIndex(address(userA), 0), 1);
    assertEq(comfyClouds.tokenOfOwnerByIndex(address(userA), 1), 2);
    assertEq(comfyClouds.balanceOf(address(userA)), 2);

    userA.burn(2);
    assertEq(comfyClouds.balanceOf(address(userA)), 1);
    assertEq(comfyClouds.tokenOfOwnerByIndex(address(userA), 0), 1);
  }

  function testFailTokenOfOwnerByIndex() public {
    userA.mint(1);
    comfyClouds.tokenOfOwnerByIndex(address(userA), 2);
  }

  function testTransferToUserB() public {
    userA.mint(1);
    assertEq(comfyClouds.ownerOf(1), address(userA));
    assertEq(comfyClouds.balanceOf(address(userA)), 1);
    assertEq(comfyClouds.balanceOf(address(userB)), 0);
    userA.transfer(address(userB), 1);
    assertEq(comfyClouds.ownerOf(1), address(userB));
    assertEq(comfyClouds.balanceOf(address(userA)), 0);
    assertEq(comfyClouds.balanceOf(address(userB)), 1);
  }

  function testFailTransferWithoutApproval() public {
    userA.mint(1);
    userB.transferFor(address(userA), address(userC), 0);
  }

  function testTransferForWithApprove1() public {
    userA.mint(1);
    userA.approve(address(userB), 1);
    userB.transferFor(address(userA), address(userC), 1);
    assertEq(comfyClouds.balanceOf(address(userA)), 0);
    assertEq(comfyClouds.balanceOf(address(userC)), 1);
  }
  function testFailApproveForUnownedToken() public {
    userA.mint(1);
    userB.approve(address(userA), 0);
  }
  function testFailApproveForNonexistentToken() public {
    userA.mint(1);
    userA.approve(address(userA), 1);
  }
  function testTransferForWithApproveAll() public {
    userA.mint(1);
    userA.approveAll(address(userB), true);
    userB.transferFor(address(userA), address(userC), 1);
  }
  function testFailTransferForWithRevokedApproval() public {
    userA.mint(1);
    userA.approveAll(address(userB), true);
    userB.transferFor(address(userA), address(userC), 0);
    userA.approveAll(address(userB), false);
    userB.transferFor(address(userA), address(userC), 1);
  }
  function testFailTransferForUnownedTokens() public {
    userA.mint(1);
    userC.mint(1);
    userA.approveAll(address(userB), true);
    userB.transferFor(address(userA), address(userC), 4);
  }

  function testBaseUriNotSetAtDeploy() public {
    string memory contractUri = comfyClouds.baseURI();
    assertEq(contractUri, "");
  }
  function testTokenUriReturnsValueAfterReveal() public {
    userA.mint(1);

    comfyClouds.setBaseURI("ipfs://BASE/");
    comfyClouds.setIsRevealed(true);
    string memory tokenURI = comfyClouds.tokenURI(1);
    assertEq(tokenURI, "ipfs://BASE/1.json");
  }
  function testTokenUriReturnsCoverUriBeforeReveal() public {
    userA.mint(1);

    string memory tokenURI = comfyClouds.tokenURI(1);
    assertEq(tokenURI,COVER_URI);
  }
  function testTokenUriReturnBaseUriAfterReveal() public {
    userA.mint(1);
    comfyClouds.setBaseURI(BASE_URI);
    comfyClouds.setIsRevealed(true);
    string memory tokenURI = comfyClouds.tokenURI(1);
    assertEq(tokenURI, "ipfs://BASE_URI/1.json");
  }
  function testOwnerCanSetBaseUri() public {
    string memory uri = "ipfs://BASE/";
    comfyClouds.setBaseURI(uri);

    string memory contractUri = comfyClouds.baseURI();
    assertEq(contractUri, uri);
  }
  function testFailSetBaseUri_NotOwner() public {
    userA.setBaseURI("ipfs://FAIL/");
  }
  function testOwnerCanSetIsRevealed() public {
    comfyClouds.setIsRevealed(true);
    bool isRevealed = comfyClouds.isRevealed();
    assertTrue(isRevealed);
  }
  function testFailSetIsRevealed_NotOwner() public {
    userA.setIsRevealed(true);
  }
  function testFailWithdrawFrom_NotOwner() public {
    userA.mint(1);
    address receiver = address(0x123);
    userA.withdraw(address(receiver), 0.1 ether);
  }

  function mintFullSupply() internal {
    for (uint i = 0; i < 50; ++i) {
      User minter = new User(comfyClouds);
      minter.deposit{value: 1 ether}();
      minter.mint(2);
    }
  }
  function testMintFullSupply() public {
    mintFullSupply();
    assertEq(comfyClouds.totalSupply(), 100);
  }
  function testMintFullSupply_ReturnsURIforToken100() public {
    mintFullSupply();
    comfyClouds.setBaseURI(BASE_URI);
    comfyClouds.setIsRevealed(true);
    string memory expectedUri = "ipfs://BASE_URI/100.json";
    string memory tokenUri = comfyClouds.tokenURI(100);
    assertEq(tokenUri, expectedUri);
  }
  function testFailMintFullSupply_Plus1() public {
    mintFullSupply();
    userA.mint(1);
  }

  event OwnerAddy(address);
  function testWithdrawSucceeds() public {
    uint contractStartingBalance = address(comfyClouds).balance;
    mintFullSupply();
    uint contractEndingBalance = address(comfyClouds).balance;

    uint contractExpectedBalance = contractStartingBalance + 2 ether;
    assertEq(contractEndingBalance, contractExpectedBalance);

    address receiverAddress = address(0x123);
    uint receiverStartingBalance = receiverAddress.balance;
    comfyClouds.withdraw(receiverAddress, 2 ether);
    uint receiverEndingBalance = receiverAddress.balance;
    uint receiverExpectedBalance = receiverStartingBalance + 2 ether;
    assertEq(receiverEndingBalance, receiverExpectedBalance);

    uint finalContractBalance = address(comfyClouds).balance;
    assertEq(contractStartingBalance, finalContractBalance);
  }
}

