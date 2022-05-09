import * as dotenv from "dotenv";
import { BigNumberish } from "ethers";
import { ethers } from "hardhat";
dotenv.config();

/*
 * this script updates the proxy implementation
 * of clipto exchange, the proxy address should remain
 * same.
 */
async function main() {
  const fees = await ethers.provider.getFeeData();
  const matic = ethers.utils.formatUnits(fees.maxFeePerGas as BigNumberish);
  console.log(`Gas price : ${matic} MATIC`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
