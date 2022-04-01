import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import * as chai from "chai";
import { sign } from "crypto";
import { solidity } from "ethereum-waffle";
import hre, { ethers } from "hardhat";
import { wyvernABI } from "./wyvernAbi.json";

chai.use(solidity);
const { expect } = chai;

const price = "10000000000000000";
const updatedPrice = "10000000000000001";

describe("Rugten", function () {
  let signer: SignerWithAddress;
  let rugtenNFT: any;
  let wyvernProxy: any;
  let registerdProxy: string;
  const wyvernProxyAddress = "0xa5409ec958C83C3f309868babACA7c86DCB077c1";
  this.beforeEach(async function () {
    [signer] = await ethers.getSigners();
    const RugtenNFT = await ethers.getContractFactory("RugtenNFT");
    rugtenNFT = await RugtenNFT.deploy();
    await rugtenNFT.initialize(signer.address);
    wyvernProxy = new ethers.Contract(wyvernProxyAddress, wyvernABI);
    registerdProxy = await wyvernProxy.connect(signer).proxies(signer.address);
    if (registerdProxy == "0x0000000000000000000000000000000000000000") {
      await wyvernProxy.connect(signer).registerProxy();
      registerdProxy = await wyvernProxy.connect(signer).proxies(signer.address);
    }
  });
  it("setApprovalForAll", async function () {
    await rugtenNFT.setAcceptApprovalAddress(wyvernProxyAddress);
    await expect(rugtenNFT.setApprovalForAll(signer.address, true)).to.revertedWith(
      "RugtenNFT: RugtenNFT can only be listed to OpenSea :("
    );
    await expect(rugtenNFT.setApprovalForAll(registerdProxy, true)).to.emit(rugtenNFT, "ApprovalForAll");
  });
  it("approve", async function () {
    await rugtenNFT.setAcceptApprovalAddress(wyvernProxyAddress);
    await rugtenNFT.mint(1, { value: price });
    await expect(rugtenNFT.approve(signer.address, 1)).to.revertedWith(
      "RugtenNFT: RugtenNFT can only be listed to OpenSea :("
    );
    await expect(rugtenNFT.approve(registerdProxy, 1)).to.emit(rugtenNFT, "Approval");
  });
  it("setBaseURI", async function () {
    await rugtenNFT.setBaseURI("aaaa/");
    await rugtenNFT.mint(1, { value: price });
    const tokenURI = await rugtenNFT.tokenURI(1);
    expect(tokenURI).to.equal("aaaa/1");
  });
  it("updateMaxMint", async function () {
    await rugtenNFT.updateMaxMint(1);
    await rugtenNFT.mint(1, { value: price });
    await expect(rugtenNFT.mint(2, { value: price })).to.revertedWith("RugtenNFT: already sold out");
  });
  it("updatePrice", async function () {
    await rugtenNFT.mint(1, { value: price });
    await rugtenNFT.updatePrice(updatedPrice);
    await expect(rugtenNFT.mint(2, { value: price })).to.revertedWith(
      "RugtenNFT: msg.value must be higher than the price"
    );
    await rugtenNFT.mint(2, { value: updatedPrice });
  });
});
