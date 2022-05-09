import * as dotenv from "dotenv";
import { ethers, upgrades } from "hardhat";
// eslint-disable-next-line node/no-missing-import
import { CliptoExchange } from "../typechain";

dotenv.config();

/*
 * this script deploys the exchange and token contracts
 * along with their beacon and proxy.
 */
async function main() {
  const feeDestination = "0xaDb10b8112Fac755e8ab1DfFaab116523844DD18";

  const cliptoToken = await ethers.getContractFactory("CliptoToken");
  const cliptoTokenBeacon = await upgrades.deployBeacon(cliptoToken);
  await cliptoTokenBeacon.deployed();
  const cliptoTokenAddress = cliptoTokenBeacon.address;

  const cliptoExchange = await ethers.getContractFactory("CliptoExchange");
  const cliptoExchangeProxy = (await upgrades.deployProxy(cliptoExchange, [
    feeDestination,
    cliptoTokenAddress,
  ])) as CliptoExchange;
  await cliptoExchangeProxy.deployed();
  const cliptoExchangeAddress = cliptoExchangeProxy.address;

  const tx = await cliptoExchangeProxy.setFeeRate(5, 100);
  await tx.wait();

  console.log("\n");
  console.log("Owner of the contracts                : ", feeDestination);
  console.log("CliptoToken beacon deployed to        : ", cliptoTokenAddress);
  console.log("CliptoExchange with proxy deployed to : ", cliptoExchangeAddress);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
