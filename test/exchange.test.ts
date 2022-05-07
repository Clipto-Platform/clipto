/* eslint-disable node/no-missing-import */
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { CliptoExchange, CliptoToken, MyERC20 } from "../typechain";
import * as constant from "./constant";

describe("CliptoExchange", () => {
  let account: SignerWithAddress;
  let dummy: SignerWithAddress;
  let cliptoToken: CliptoToken;
  let cliptoExchange: CliptoExchange;
  let erc20: MyERC20;

  const jsondata1 = JSON.stringify({
    username: "atul",
    data: "extra data",
  });
  const jsondata2 = JSON.stringify({
    username: "sample",
    data: "diff data",
  });

  beforeEach(async () => {
    const accounts = await ethers.getSigners();
    account = accounts[0];
    dummy = accounts[1];

    const CliptoToken = await ethers.getContractFactory("CliptoToken");
    cliptoToken = (await upgrades.deployBeacon(CliptoToken)) as CliptoToken;
    await cliptoToken.deployed();

    const CliptoExchange = await ethers.getContractFactory("CliptoExchange");
    cliptoExchange = (await upgrades.deployProxy(CliptoExchange, [
      account.address,
      cliptoToken.address,
    ])) as CliptoExchange;
    cliptoExchange = await cliptoExchange.deployed();

    const myErc = await ethers.getContractFactory("MyERC20");
    erc20 = await myErc.deploy("atul token", "ATUL");

    let tx = await erc20.mint(account.address, 100);
    await tx.wait();

    tx = await erc20.mint(dummy.address, 100);
    await tx.wait();
  });

  it("should pause when owner takes action", async () => {
    expect(await cliptoExchange.paused()).to.eql(false);

    const tx = await cliptoExchange.pause();
    await tx.wait();

    expect(await cliptoExchange.paused()).to.eql(true);
  });

  it("should return values for all readable functions", async () => {
    expect(await cliptoExchange.owner()).to.eql(account.address);

    const feeRate = await cliptoExchange.getFeeRate();
    expect(feeRate[0].toNumber()).to.eql(0);
    expect(feeRate[1].toNumber()).to.eql(1);
  });

  it("should register a new creator", async () => {
    const tx = await cliptoExchange
      .connect(account)
      .registerCreator("creator", jsondata1);
    await tx.wait();

    const nft = await cliptoExchange.getCreator(account.address);
    const token = await ethers.getContractAt("CliptoToken", nft);
    expect(await token.symbol()).to.eql("CTO");
    expect(await token.name()).to.eql("Clipto Creator - creator");
    expect(await token.owner()).to.eql(account.address);
    expect(await token.minter()).to.eql(cliptoExchange.address);
  });

  it("should create a new request", async () => {
    let tx = await cliptoExchange
      .connect(account)
      .registerCreator("sample creator", jsondata1);
    await tx.wait();

    tx = await cliptoExchange
      .connect(account)
      .nativeNewRequest(account.address, account.address, jsondata1, {
        value: 1,
      });
    await tx.wait();

    let request = await cliptoExchange.getRequest(account.address, 0);
    expect(request.requester).to.eql(account.address);
    expect(request.erc20).to.eql(constant.NULL_ADDR);
    expect(request.amount.toNumber()).to.eql(1);
    expect(request.fulfilled).to.eql(false);

    tx = await erc20.approve(cliptoExchange.address, 10);
    await tx.wait();

    tx = await cliptoExchange
      .connect(account)
      .newRequest(account.address, account.address, erc20.address, 10, jsondata1);
    await tx.wait();

    request = await cliptoExchange.getRequest(account.address, 1);
    expect(request.requester).to.eql(account.address);
    expect(request.erc20).to.eql(erc20.address);
    expect(request.amount.toNumber()).to.eql(10);
    expect(request.fulfilled).to.eql(false);
  });

  it("should create a new request for different requester", async () => {
    const creator = account;
    const requester = dummy;
    const nftReceiver = dummy;

    let tx = await cliptoExchange
      .connect(creator)
      .registerCreator("sample creator", jsondata1);
    await tx.wait();

    tx = await cliptoExchange
      .connect(requester)
      .nativeNewRequest(creator.address, nftReceiver.address, jsondata1, {
        value: 1,
      });
    await tx.wait();

    let request = await cliptoExchange.getRequest(creator.address, 0);
    expect(request.requester).to.eql(requester.address);
    expect(request.nftReceiver).to.eql(nftReceiver.address);
    expect(request.erc20).to.eql(constant.NULL_ADDR);
    expect(request.amount.toNumber()).to.eql(1);
    expect(request.fulfilled).to.eql(false);

    tx = await erc20.connect(requester).approve(cliptoExchange.address, 10);
    await tx.wait();

    tx = await cliptoExchange
      .connect(requester)
      .newRequest(creator.address, nftReceiver.address, erc20.address, 10, jsondata1);
    await tx.wait();

    request = await cliptoExchange.getRequest(creator.address, 1);
    expect(request.requester).to.eql(requester.address);
    expect(request.nftReceiver).to.eql(nftReceiver.address);
    expect(request.erc20).to.eql(erc20.address);
    expect(request.amount.toNumber()).to.eql(10);
    expect(request.fulfilled).to.eql(false);
  });

  it("should update creator", async () => {
    let tx = await cliptoExchange
      .connect(account)
      .registerCreator("sample creator", jsondata1);
    await tx.wait();

    let nft = await cliptoExchange.getCreator(account.address);
    expect(nft.length).not.eql(0);

    tx = await cliptoExchange.connect(account).updateCreator(jsondata2);
    await tx.wait();

    nft = await cliptoExchange.getCreator(account.address);
    expect(nft.length).not.eql(0);
  });

  it("should deliver a request and mint an nft", async () => {
    let tx = await cliptoExchange
      .connect(account)
      .registerCreator("sample creator", jsondata1);
    await tx.wait();

    const prevBalance = await erc20.balanceOf(cliptoExchange.address);

    tx = await erc20.approve(cliptoExchange.address, 10);
    await tx.wait();
    tx = await cliptoExchange
      .connect(account)
      .newRequest(account.address, account.address, erc20.address, 10, jsondata1);
    await tx.wait();

    let request = await cliptoExchange.getRequest(account.address, 0);
    expect(request.erc20).to.eql(erc20.address);
    expect(request.amount.toNumber()).to.eql(10);

    const currBalance = await erc20.balanceOf(cliptoExchange.address);
    expect(currBalance.toNumber() - prevBalance.toNumber()).to.eql(10);

    const creatorPrevBalance = await erc20.balanceOf(account.address);

    tx = await cliptoExchange.connect(account).deliverRequest(0, jsondata2);
    await tx.wait();

    const creatorNewBalance = await erc20.balanceOf(account.address);

    request = await cliptoExchange.getRequest(account.address, 0);
    expect(request.fulfilled).to.eql(true);
    expect(creatorNewBalance.toNumber() - creatorPrevBalance.toNumber()).to.eql(10);

    const nft = await cliptoExchange.getCreator(account.address);
    const token = await ethers.getContractAt("CliptoToken", nft);
    expect(await token.name()).to.eql("Clipto Creator - sample creator");
    expect((await token.balanceOf(account.address)).toNumber()).to.eql(1);
    expect(await token.tokenURI(1)).to.eql(jsondata2);
  });

  it("should refund a request", async () => {
    let tx = await cliptoExchange
      .connect(account)
      .registerCreator("sample creator", jsondata1);
    await tx.wait();

    const prevBalance = await erc20.balanceOf(cliptoExchange.address);

    tx = await erc20.connect(dummy).approve(cliptoExchange.address, 10);
    await tx.wait();
    tx = await cliptoExchange
      .connect(dummy)
      .newRequest(account.address, account.address, erc20.address, 10, jsondata1);
    await tx.wait();

    let request = await cliptoExchange.getRequest(account.address, 0);
    expect(request.erc20).to.eql(erc20.address);
    expect(request.amount.toNumber()).to.eql(10);

    const currBalance = await erc20.balanceOf(cliptoExchange.address);
    expect(currBalance.toNumber() - prevBalance.toNumber()).to.eql(10);

    const requesterPrevBalance = await erc20.balanceOf(dummy.address);

    tx = await cliptoExchange.connect(dummy).refundRequest(account.address, 0);
    await tx.wait();

    const requesterNewBalance = await erc20.balanceOf(dummy.address);

    request = await cliptoExchange.getRequest(account.address, 0);
    expect(request.fulfilled).to.eql(true);
    expect(requesterNewBalance.toNumber() - requesterPrevBalance.toNumber()).to.eql(10);
  });

  it("should transfer ownership of exchange contract", async () => {
    expect(await cliptoExchange.owner()).to.eql(account.address);

    const tx = await cliptoExchange.transferOwnership(dummy.address);
    await tx.wait();

    expect(await cliptoExchange.owner()).to.eql(dummy.address);
  });

  it("should update fees", async () => {
    const feeRate = await cliptoExchange.getFeeRate();
    expect(feeRate[0].toNumber()).to.eql(0);
    expect(feeRate[1].toNumber()).to.eql(1);

    let tx = await cliptoExchange
      .connect(dummy)
      .registerCreator("sample creator", jsondata1);
    await tx.wait();

    tx = await cliptoExchange.connect(account).setFeeRate(10, 100);
    await tx.wait();

    const creatorPrevBalance = await erc20.balanceOf(dummy.address);

    tx = await erc20.connect(account).approve(cliptoExchange.address, 10);
    await tx.wait();
    tx = await cliptoExchange
      .connect(account)
      .newRequest(dummy.address, dummy.address, erc20.address, 10, jsondata1);
    await tx.wait();

    const feeDestPrevBalance = await erc20.balanceOf(account.address);
    tx = await cliptoExchange.connect(dummy).deliverRequest(0, jsondata2);
    await tx.wait();

    const creatorNewBalance = await erc20.balanceOf(dummy.address);
    const feeDestNewBalance = await erc20.balanceOf(account.address);

    expect(creatorNewBalance.toNumber() - creatorPrevBalance.toNumber()).to.eql(9); // 10 - 10% of amount
    expect(feeDestNewBalance.toNumber() - feeDestPrevBalance.toNumber()).to.eql(1); // 10% of amount 10
  });

  it("should migrate creators", async () => {
    const tx = await cliptoExchange.migrateCreator([account.address], ["creator"]);
    await tx.wait();

    const nft = await cliptoExchange.getCreator(account.address);
    expect(nft.length).not.eql(0);

    const token = await ethers.getContractAt("CliptoToken", nft);
    expect(await token.symbol()).to.eql("CTO");
    expect(await token.name()).to.eql("Clipto Creator - creator");
  });

  it("should complete a request after proxy update", async () => {
    const creator = account;
    const requester = account;
    const nftReceiver = dummy;

    let tx = await cliptoExchange
      .connect(creator)
      .registerCreator("sample creator", jsondata1);
    await tx.wait();

    tx = await erc20.connect(requester).approve(cliptoExchange.address, 10);
    await tx.wait();
    tx = await cliptoExchange
      .connect(requester)
      .newRequest(creator.address, nftReceiver.address, erc20.address, 10, jsondata1);
    await tx.wait();

    let request = await cliptoExchange.getRequest(creator.address, 0);
    expect(request.erc20).to.eql(erc20.address);
    expect(request.amount.toNumber()).to.eql(10);

    const cliptoExchangeV2 = await ethers.getContractFactory("CliptoExchangeV2");
    cliptoExchange = (await upgrades.upgradeProxy(
      cliptoExchange,
      cliptoExchangeV2
    )) as CliptoExchange;
    tx = await cliptoExchange.connect(creator).deliverRequest(0, jsondata2);
    await tx.wait();

    request = await cliptoExchange.getRequest(creator.address, 0);
    expect(request.fulfilled).to.eql(true);

    const nft = await cliptoExchange.getCreator(creator.address);
    const token = await ethers.getContractAt("CliptoToken", nft);
    expect(await token.name()).to.eql("Clipto Creator - sample creator");
    expect((await token.balanceOf(nftReceiver.address)).toNumber()).to.eql(1);
    expect(await token.tokenURI(1)).to.eql(jsondata2);
  });

  it("should complete the request, and send nft to different receiver", async () => {
    const creator = account;
    const requester = account;
    const nftReceiver = dummy;

    let tx = await cliptoExchange
      .connect(account)
      .registerCreator("sample creator", jsondata1);
    await tx.wait();

    tx = await cliptoExchange
      .connect(requester)
      .nativeNewRequest(creator.address, nftReceiver.address, jsondata1, {
        value: 20,
      });
    await tx.wait();

    let request = await cliptoExchange.getRequest(creator.address, 0);
    expect(request.requester).to.eql(requester.address);
    expect(request.nftReceiver).to.eql(nftReceiver.address);
    expect(request.erc20).to.eql(constant.NULL_ADDR);
    expect(request.amount.toNumber()).to.eql(20);
    expect(request.fulfilled).to.eql(false);

    tx = await cliptoExchange.connect(creator).deliverRequest(0, jsondata2);
    await tx.wait();

    request = await cliptoExchange.getRequest(creator.address, 0);
    expect(request.fulfilled).to.eql(true);
    const nft = await cliptoExchange.getCreator(creator.address);
    const token = await ethers.getContractAt("CliptoToken", nft);
    expect((await token.balanceOf(nftReceiver.address)).toNumber()).to.eql(1);
    expect(await token.tokenURI(1)).to.eql(jsondata2);
  });

  it("should update implementation of beacon", async () => {
    const creator = account;

    const tx = await cliptoExchange
      .connect(creator)
      .registerCreator("sample creator", jsondata1);
    await tx.wait();

    const nft = await cliptoExchange.getCreator(account.address);
    expect(nft.length).not.eql(0);

    const token = await ethers.getContractAt("CliptoToken", nft);
    expect(await token.contractURI()).to.eql(constant.CONTRACT_URI);

    const cliptoTokenV2 = await ethers.getContractFactory("CliptoTokenV2");
    cliptoToken = (await upgrades.upgradeBeacon(
      cliptoToken,
      cliptoTokenV2
    )) as CliptoToken;
    expect(await token.contractURI()).to.eql(constant.CONTRACT_URI_V2);
  });
});
