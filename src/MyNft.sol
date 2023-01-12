// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MyNft is ERC721, Ownable {

  //---------------------------------------------------------------
  //  CONSTANTS
  //---------------------------------------------------------------
  uint256 public constant MAX_SUPPLY = 500;
  uint256 public constant MAX_PER_WALLET = 1;
  uint256 public mintStartTime;
  bool    public isRevealed;

  //---------------------------------------------------------------
  //  METADATA
  //---------------------------------------------------------------
  string public baseURI;
  string public coverURI;

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

  constructor(string memory _coverURI) ERC721("MyNft", "MINE") {
    coverURI = _coverURI;
    // Wed Jan 11 19:03:16 EST 2023
    mintStartTime = 1673481796;
  }

  function mint() public payable {
    require(owners.length < MAX_SUPPLY, "MAX_SUPPLY");
    require(block.timestamp >= mintStartTime, "NOT_LIVE");

    require(!minters[msg.sender], "MAX_ONE_PER_WALLET");
    minters[msg.sender] = true;
    _safeMint(msg.sender, owners.length);
  }

  // OPTION:MAX_PER_MINT=2+
  // function mint() public payable {
  //   require(owners.length + amount <= MAX_SUPPLY, "MAX_SUPPLY");
  //   require(block.timestamp >= mintStartTime, "NOT_LIVE");

  //   minters[msg.sender] += amount;
  //   require(minters[msg.sender] <= MAX_PER_WALLET, "ADDRESS_MAX_REACHED");
  //   for(uint256 i = 0; i < amount; i++) {
  //     _safeMint(msg.sender, owners.length);
  //   }
  // }

  // OPTION:MAX_PER_MINT=2+
  // mapping (address => uint256) public minters;
  mapping (address => bool) public minters;

  function burn(uint256 id) public {
    _burn(id);
  }

  //----------------------------------------------------------------
  //  WHITELISTS
  //----------------------------------------------------------------

  /// @dev - Merkle Tree root hash
  bytes32 public root;

  function setMerkleRoot(bytes32 merkleroot) public onlyOwner {
    root = merkleroot;
  }


  function premint(bytes32[] calldata proof)
  external
  payable
  {
    address account = msg.sender;
    require(_verify(_leaf(account), proof), "INVALID_MERKLE_PROOF");
    require(owners.length < MAX_SUPPLY, "MAX_SUPPLY");

    require(!minters[account], "MAX_ONE_PER_WALLET");
    minters[msg.sender] = true;

    _safeMint(account, owners.length);
  }

  // OPTION:MAX_PER_MINT=2+
  // function premint(uint256 amount, bytes32[] calldata proof)
  // external
  // payable
  // {
  //   address account = msg.sender;
  //   require(_verify(_leaf(account), proof), "INVALID_MERKLE_PROOF");
  //   require(owners.length + amount <= MAX_SUPPLY, "MAX_SUPPLY");
  //
  //   minters[msg.sender] += amount;
  //   require(minters[account] <= MAX_PER_WALLET, "ADDRESS_MAX_REACHED");
  //
  //   for(uint256 i = 0; i < amount; i++) {
  //     _safeMint(account, owners.length);
  //   }
  // }

  function _leaf(address account)
  internal pure returns (bytes32)
  {
    return keccak256(abi.encodePacked(account));
  }

  function _verify(bytes32 leaf, bytes32[] memory proof)
  internal view returns (bool)
  {
    return MerkleProof.verify(proof, root, leaf);
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
  function setMintStartTime(uint256 _startTime) public onlyOwner {
    mintStartTime = _startTime;
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
