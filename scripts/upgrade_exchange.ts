import * as dotenv from "dotenv";
import { ethers, upgrades } from "hardhat";
dotenv.config();

/*
 * this script updates the proxy implementation
 * of clipto exchange, the proxy address should remain
 * same.
 */
async function main() {
  const proxyAddress = "";

  if (proxyAddress.length === 0) {
    throw new Error("Update the proxy address");
  }

  const CliptoExchange = await ethers.getContractFactory("CliptoExchange");

  const cliptoExchange = await upgrades.upgradeProxy(proxyAddress, CliptoExchange);
  const proxy = await cliptoExchange.deployed();
  const cliptoExchangeAddress = proxy.address;

  console.log("\n");
  console.log("Clipto exchange proxy old : ", proxyAddress);
  console.log("Clipto exchange proxy new : ", cliptoExchangeAddress);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
