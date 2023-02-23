import dotenv from "dotenv";

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import { MockDEX__factory } from "./typechain-types";

dotenv.config();

task("fund", "Funds an account with ETH")
  .addParam("account", "The account to fund")
  .setAction(async (taskArgs, hre) => {
    const [account] = await hre.ethers.getSigners();
    const tx = await account.sendTransaction({
      to: taskArgs.account,
      value: hre.ethers.utils.parseEther("1.0"),
    });
    await tx.wait();
  });

task("distribute-fee-turnstile", "Distribute fee to turnstile")
  .addParam("turnstile", "The turnstile address")
  .addParam("id", "The token id")
  .setAction(async (taskArgs, hre) => {
    const [account] = await hre.ethers.getSigners();
    const turnstile = await hre.ethers.getContractAt(
      "Turnstile",
      taskArgs.turnstile
    );
    const tx = await turnstile.connect(account).distributeFees(
      taskArgs.id, {value : hre.ethers.utils.parseEther("0.1")}
    );
    await tx.wait();
  });

task("mint-turnstile", "Mint turnstile NFT")
  .addParam("turnstile", "The turnstile address")
  .addParam("bond", "bond contract address")
  .addParam("to", "The address to mint to")
  .setAction(async (taskArgs, hre) => {
    const [account] = await hre.ethers.getSigners();
    const turnstile = await hre.ethers.getContractAt(
      "Turnstile",
      taskArgs.turnstile
    );
    console.log("nft Id : ", (await turnstile.currentCounterId()));
    await new MockDEX__factory(account).deploy(taskArgs.turnstile, taskArgs.bond);
  });

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.18",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000,
          },
        },
      },
    ],
  },
  networks: {
    "canto-testnet": {
      chainId: 740,
      url: "https://eth.plexnode.wtf/", // dosn't work...
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    localhost : {
      url : "http://localhost:8545"
    }
  },
};

export default config;
