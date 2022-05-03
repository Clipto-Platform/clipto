import * as dotenv from "dotenv";
import { ethers, upgrades } from "hardhat";

dotenv.config();

/*
 * this script deploys the exchange and token contracts
 * along with their beacon and proxy.
 */
async function main() {
  const feeDestination =
    process.env.FEE_DESTINATION_ADDRESS || "0x7c98C2DEc5038f00A2cbe8b7A64089f9c0b51991";

  const cliptoToken = await ethers.getContractFactory("CliptoToken");
  const cliptoTokenBeacon = await upgrades.deployBeacon(cliptoToken);
  await cliptoTokenBeacon.deployed();
  const cliptoTokenAddress = cliptoTokenBeacon.address;

  const cliptoExchange = await ethers.getContractFactory("CliptoExchange");
  const cliptoExchangeProxy = await upgrades.deployProxy(cliptoExchange, [
    feeDestination,
    cliptoTokenBeacon.address,
  ]);
  await cliptoExchangeProxy.deployed();
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
