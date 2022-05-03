import * as dotenv from "dotenv";
import { ethers, upgrades } from "hardhat";
dotenv.config();

async function main() {
  const feeDestination =
    process.env.FEE_DESTINATION_ADDRESS || "0x7c98C2DEc5038f00A2cbe8b7A64089f9c0b51991";

  const CliptoToken = await ethers.getContractFactory("CliptoToken");
  const CliptoExchange = await ethers.getContractFactory("CliptoExchange");

  let cliptoToken = await upgrades.deployBeacon(CliptoToken);
  cliptoToken = await cliptoToken.deployed();
  const cliptoTokenAddress = cliptoToken.address;

  const cliptoExchange = await upgrades.deployProxy(CliptoExchange, [
    feeDestination,
    cliptoTokenAddress,
  ]);
  const proxy = await cliptoExchange.deployed();
  const cliptoExchangeAddress = proxy.address;

  console.log("\n");
  console.log("Owner of the contracts                : ", feeDestination);
  console.log("CliptoToken beacon deployed to        : ", cliptoTokenAddress);
  console.log("CliptoExchange with proxy deployed to : ", cliptoExchangeAddress);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
