//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract IWyvernRegistry {
  mapping(address => address) public proxies;
}

contract RugtenNFT is Initializable, ERC721Upgradeable, OwnableUpgradeable {
  using StringsUpgradeable for uint256;
  string private customBaseURI;
  address public acceptApprovalAddress;
  uint256 public maxMint = 100;
  uint256 public price = 10000000000000000;
  uint256 private _totalSupply;

  function initialize(address _owner) public initializer {
    __Ownable_init_unchained();
    transferOwnership(_owner);
    __ERC721_init_unchained("RugtenNFT", "RTN");
  }

  function setAcceptApprovalAddress(address _acceptApprovalAddress) public onlyOwner {
    acceptApprovalAddress = _acceptApprovalAddress;
  }

  function setApprovalForAll(address operator, bool approved) public virtual override {
    require(
      operator == IWyvernRegistry(acceptApprovalAddress).proxies(msg.sender),
      "RugtenNFT: RugtenNFT can only be listed to OpenSea :("
    );
    super.setApprovalForAll(operator, approved);
  }

  function approve(address to, uint256 tokenId) public virtual override {
    require(
      to == IWyvernRegistry(acceptApprovalAddress).proxies(msg.sender),
      "RugtenNFT: RugtenNFT can only be listed to OpenSea :("
    );
    super.approve(to, tokenId);
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _setBaseURI(baseURI);
  }

  function _setBaseURI(string memory baseURI_) internal virtual {
    customBaseURI = baseURI_;
  }

  function baseURI() public view virtual returns (string memory) {
    return customBaseURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    string memory base = baseURI();
    return string(abi.encodePacked(base, tokenId.toString()));
  }

  function mint(uint256 tokenId) public payable {
    require(msg.value >= price, "RugtenNFT: msg.value must be higher than the price");
    require(_totalSupply < maxMint, "RugtenNFT: already sold out");
    _safeMint(msg.sender, tokenId);
    _totalSupply++;
  }

  function updatePrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  function updateMaxMint(uint256 _maxmint) public onlyOwner {
    maxMint = _maxmint;
  }

  function burn(uint256 tokenId) public virtual {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
    _burn(tokenId);
    _totalSupply--;
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function withdraw() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }
}
