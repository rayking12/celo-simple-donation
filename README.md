# Simple Donation dApp

[Demo dApp](https://celo-simple-donation.vercel.app/)

This project is a simple decentralized application (DApp) that allows users to request donations  and  withdraw donations in ERC-20 standart tokens. NFTs follow the ERC1155 standart. The project uses the Celo blockchain (compatible with the Ethereum Virtual Machine).

## Getting Started

To use this DApp, you will need a EVM-compatible wallet such as Metamask and some test Celo coins to interact with the smart contract.

To set up the project, follow these steps:

1. Clone the repository to your local machine.
2. Install the required dependencies by running `yarn install`.
3. Start the DApp by running `yarn start`.

## Usage

Once you have the DApp running, you can stake your NFTs by following these steps:

1. Connect your wallet to the DApp.
2. Fill the request donation form.
3. Withdraw donations made to you.
3. Close donations whenever.



## Smart Contract Details

The smart contracts are written in Solidity and are based on OpenZeppelin contracts for increased security and reliability. The contract `Donations` supports the following functions:

- `createCause(string memory name, address payable beneficiary, string memory description, uint256 goalAmount, string memory imageUrl)` - create donation request.
- `donate(uint256 causeId)` - Donate a certain amount.
- `requestDonation(uint256 causeId, uint256 amount)` - Withdraw available donations.
- `closeCause(uint256 causeId)` - Close donations.
- `getAllCauses()` -get all donation requests

## Contributing

Contributions to this project are welcome. To contribute, please fork the repository, make your changes, and submit a pull request.