// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import * as dotenv from "dotenv";
import { ethers } from "hardhat";
dotenv.config();

async function main() {
  const feeDestination =
    process.env.FEE_DESTINATION_ADDRESS ||
    "0x7c98C2DEc5038f00A2cbe8b7A64089f9c0b51991";

  const CliptoToken = await ethers.getContractFactory("CliptoToken");
  const CliptoExchange = await ethers.getContractFactory("CliptoExchange");

  const cliptoToken = await CliptoToken.deploy();
  await cliptoToken.deployed();
  const cliptoTokenAddress = cliptoToken.address;

  const cliptoExchange = await CliptoExchange.deploy(
    cliptoTokenAddress,
    feeDestination
  );
  await cliptoExchange.deployed();
  const cliptoExchangeAddresss = cliptoExchange.address;

  console.log("\n");
  console.log("Owner of the contracts     : ", feeDestination);
  console.log("CliptoToken deployed to    : ", cliptoTokenAddress);
  console.log("CliptoExchange deployed to : ", cliptoExchangeAddresss);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
