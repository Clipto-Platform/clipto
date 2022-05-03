import * as dotenv from "dotenv";
import { ethers, upgrades } from "hardhat";
// eslint-disable-next-line node/no-missing-import
import { CliptoExchange } from "../typechain";

dotenv.config();

async function main() {
  const feeDestination =
    process.env.FEE_DESTINATION_ADDRESS || "0x7c98C2DEc5038f00A2cbe8b7A64089f9c0b51991";

  const CliptoToken = await ethers.getContractFactory("CliptoToken");
  const cliptoTokenBeacon = await upgrades.deployBeacon(CliptoToken);
  await cliptoTokenBeacon.deployed();

  const CliptoExchange = await ethers.getContractFactory("CliptoExchange");

  let cliptoToken = await upgrades.deployBeacon(CliptoToken);
  cliptoToken = await cliptoToken.deployed();
  const cliptoTokenAddress = cliptoToken.address;

  let cliptoExchangeProxy = (await upgrades.deployProxy(CliptoExchange, [
    feeDestination,
    cliptoTokenBeacon.address,
  ])) as CliptoExchange;
  cliptoExchangeProxy = await cliptoExchangeProxy.deployed();
  const cliptoExchangeAddress = cliptoExchangeProxy.address;

  console.log("\n");
  console.log("Owner of the contracts                : ", feeDestination);
  console.log("CliptoToken beacon deployed to        : ", cliptoTokenAddress);
  console.log("CliptoExchange with proxy deployed to : ", cliptoExchangeAddress);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
