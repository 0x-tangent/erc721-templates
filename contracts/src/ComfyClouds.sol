// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ComfyClouds is ERC721, Ownable {

  //---------------------------------------------------------------
  //  CONSTANTS
  //---------------------------------------------------------------
  uint256 public constant MAX_SUPPLY = 100;
  uint256 public constant MAX_PER_WALLET = 2;
  bool    public isRevealed;

  //---------------------------------------------------------------
  //  METADATA
  //---------------------------------------------------------------
  string public baseURI;
  string public coverURI;

  mapping (address => uint) public minters;

  function tokenURI(uint256 id) public view virtual override returns (string memory) {
    require(_exists(id), "ERC721Metadata: URI query for nonexistent token");
    if(!isRevealed) {
      return coverURI;
    }

    return string(abi.encodePacked(baseURI, Strings.toString(id), ".json"));
  }

  //---------------------------------------------------------------
  //  CONSTRUCTOR
  //---------------------------------------------------------------

  constructor(string memory _coverURI) ERC721("ComfyClouds", "MINE") {
    coverURI = _coverURI;
  }

  function mint(uint amount) public payable {
    require(owners.length < MAX_SUPPLY, "MAX_SUPPLY");

    minters[msg.sender] += amount;
    require(minters[msg.sender] <= MAX_PER_WALLET, "MAX_TWO_PER_WALLET");
    for(uint i=0; i < amount; ++i) {
      _safeMint(msg.sender, owners.length);
    }
  }

  function burn(uint256 id) public {
    _burn(id);
  }

  //----------------------------------------------------------------
  //  ADMIN FUNCTIONS
  //----------------------------------------------------------------

  function setCoverURI(string memory uri) public onlyOwner {
    coverURI = uri;
  }
  function setBaseURI(string memory uri) public onlyOwner {
    baseURI = uri;
  }
  function setIsRevealed(bool _isRevealed) public onlyOwner {
    isRevealed = _isRevealed;
  }

  //---------------------------------------------------------------
  // WITHDRAWAL
  //---------------------------------------------------------------

  function withdraw(address to, uint256 amount) public onlyOwner {
    (bool success,) = payable(to).call{ value: amount }("");
    require(success, "WITHDRAWAL_FAILED");
  }
}
