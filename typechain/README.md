# TurnstileBond

## Configuration

**Notice: Use ethereum local network instead of Canto Testnet, since there is no working testnet rpc url**

1. Install dependencies with `yarn`
2. Compile contracts with `yarn compile`
3. Run local network node with `npx hardhat node`
4. Deploy contracts to local network with `npx hardhat run --network localhost scripts/deploy.ts`
   1. Deploy Turnstile contract
   2. Deploy TurnstileBond contract
   3. Deploy MockDEX contract and register to Turnstile
      1. CSR NFT of MockDEX will be minted to contract deployer
   4. Start bonding with CSR NFT of MockDEX
   5. Distribute CSR revenue to MockDEX tokenId in Turnstile contract
5. Connect your wallet(e.g Metamask) or dapp to `http://127.0.0.1:8545`
6. Now you're ready to use TurntileBond!

## User Flow
