import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { Clipto, CliptoNft } from "../typechain";

describe("Clipto", function () {
  let clipto: Clipto;

  let deployer: SignerWithAddress,
    creator1: SignerWithAddress,
    user1: SignerWithAddress;

  this.beforeAll(async function () {
    [deployer, creator1, user1] = await ethers.getSigners();
    const Clipto = await ethers.getContractFactory("Clipto", deployer);
    clipto = await Clipto.deploy();
    await clipto.deployed();
  });

  it("creator should be able to create new cameo", async function () {
    await clipto
      .connect(creator1)
      .setCameo(
        ethers.utils.parseEther("1"),
        ethers.BigNumber.from(60 * 60 * 24 * 4),
        "https://clipto.io/user/0x...",
        "TestUser"
      );
    expect((await clipto._cameo(creator1.address)).profileUri).to.equal(
      "https://clipto.io/user/0x..."
    );
  });

  it("user should be able to buy cameo", async function () {
    await clipto
      .connect(user1)
      .buy(
        creator1.address,
        ethers.BigNumber.from(
          Math.floor(+new Date() / 1000) + 60 * 60 * 24 * 5
        ),
        "https://clipto.io/deal/0x...",
        { value: ethers.utils.parseEther("1") }
      );
    expect((await clipto._agreement(0)).buyer).to.equal(user1.address);
  });

  it("creator should be able to mint NFT", async function () {
    const CliptoNft = await ethers.getContractFactory("CliptoNft", creator1);
    const cliptoNft: CliptoNft = CliptoNft.attach(
      (await clipto._cameo(creator1.address)).collection
    );

    await cliptoNft.safeMint(user1.address, "0xipfshash");
    expect(await cliptoNft.balanceOf(user1.address)).to.be.equal(1);
  });
});
