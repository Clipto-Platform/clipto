import * as dotenv from "dotenv";
import { ethers, upgrades } from "hardhat";
dotenv.config();

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
  console.log("CliptoExchange with proxy deployed to : ", cliptoExchangeAddress);
  console.log("CliptoExchange with proxy deployed to : ", proxy.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
