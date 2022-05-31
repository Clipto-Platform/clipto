import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { CliptoExchange, CliptoToken, MyERC20 } from "../typechain";
import * as constant from "./constant";

describe("Bounty", () =>{

    let account: SignerWithAddress;
    let account2: SignerWithAddress;
    let cliptoToken: CliptoToken;
    let cliptoExchange: CliptoExchange;
    let erc20: MyERC20;

    const jsondata1 = JSON.stringify({
        username: "rushi",
        data: "extra data",
      });

    beforeEach(async ()=>{
        const accounts = await ethers.getSigners();
        account = accounts[0];
        account2 = accounts[1];

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
        erc20 = await myErc.deploy("rushi token", "RUSHI");

        let tx = await erc20.mint(account.address, 100);
        await tx.wait();

    });

    it("should create bounty request",async ()=>{

        const hash = ethers.utils.keccak256(ethers.utils.defaultAbiCoder.encode(["string"],["hello world"]));
        let tx = await cliptoExchange.connect(account).nativeBountyNewRequest(hash, account.address, jsondata1, {
            value: 10
        });

        let request = await cliptoExchange.getBountyRequest(hash);
        expect(request.requester).to.eql(account.address);
        expect(request.erc20).to.eql(constant.NULL_ADDR);
        expect(request.amount.toNumber()).to.eql(10);
        expect(request.fulfilled).to.eql(false);

        tx = await erc20.approve(cliptoExchange.address, 10);
        await tx.wait();

        tx = await cliptoExchange.connect(account).newBountyRequest(hash, account.address, erc20.address, 10, jsondata1);
        request = await cliptoExchange.getBountyRequest(hash);
        expect(request.requester).to.eql(account.address);
        expect(request.erc20).to.eql(erc20.address);
        expect(request.amount.toNumber()).to.eql(10);
        expect(request.fulfilled).to.eql(false);
    });

    it("should able to deliver bounty request",async ()=>{

        const hash = ethers.utils.keccak256(ethers.utils.defaultAbiCoder.encode(["string"],["hello world"]));
        let tx = await cliptoExchange.connect(account).nativeBountyNewRequest(hash, account.address, jsondata1, {
            value: 10
        });

        let request = await cliptoExchange.getBountyRequest(hash);
        expect(request.requester).to.eql(account.address);
        expect(request.erc20).to.eql(constant.NULL_ADDR);
        expect(request.amount.toNumber()).to.eql(10);
        expect(request.fulfilled).to.eql(false);

        tx = await cliptoExchange
        .connect(account2)
        .registerCreator("creator", jsondata1);
        await tx.wait();

        let nft = await cliptoExchange.getCreator(account2.address);
        let token = await ethers.getContractAt("CliptoToken", nft);
        expect(await token.symbol()).to.eql("CTO");
        expect(await token.name()).to.eql("Clipto Creator - creator");
        expect(await token.owner()).to.eql(account2.address);
        expect(await token.minter()).to.eql(cliptoExchange.address);

        tx = await cliptoExchange.connect(account2).deliverBountyRequest("hello world" , jsondata1);
        
        expect((await token.balanceOf(account.address)).toNumber()).to.eql(1);
        expect(await token.tokenURI(1)).to.eql(jsondata1);
    });

});