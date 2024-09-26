# The Life DAO Smart Contracts 

- [The Life DAO Smart Contracts](#the-life-dao-smart-contracts)
  - [Summary](#summary)
  - [Deployed Contracts](#deployed-contracts)
  - [Dapp](#dapp)
  - [Requirements](#requirements)
  - [Quickstart](#quickstart)
    - [env](#env)
  - [Usage](#usage)
    - [Compile](#compile)
    - [Testing](#testing)
    - [Deploy](#deploy)
  - [Disclaimer](#disclaimer)
  - [Contribute](#contribute)
     
## Summary
This repository contains the smart contracts for The Life Dao first testnet launch. The LifeDAO is a shariah-compliant alternative for life insurance, built for the community, and where all the members share the risk and rewards while protecting each other. Our mission is to provide a decentralized, transparent, and fair alternative to traditional life insurance.

## Deployed Contracts
Arbitrum Testnet: 0xb135f67A8D5AEE21B1F48E4906933924b51E13C7

## Dapp
The dapp is available at [The Life DAO](https://testnet.thelifedao.io/)
  
## Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`
- [foundry](https://getfoundry.sh/)
  - Run
  ```
  curl -L https://foundry.paradigm.xyz | bash
  ```
  - You'll know you did it right if you can run `forge --version` and you see a response like `forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)`

## Quickstart

1. Clone the repo and install the dependencies

```bash
git clone https://github.com/TakafulDAO/lifeDao.testnet
cd lifeDao.testnet
yarn install
make all
```

2. Create a .env file with the variables explained on the next section. You can also check the `.env.example` file

### env
1. Private keys. For development purposes, this is used only in the script to check the chainlink functions script
    + TESTNET_DEPLOYER_PK
2. Deployers addresses
    + TESTNET_DEPLOYER_ADDRESS
3. Testnet RPC_URL
    + ARBITRUM_TESTNET_SEPOLIA_RPC_URL
4. Scans api keys. [here](https://docs.arbiscan.io/getting-started/viewing-api-usage-statistics)
    + ARBISCAN_API_KEY
5. Accounts. This are the names of the accounts encripted with `cast wallet import`
    + TESTNET_ACCOUNT=

> [!CAUTION]
> Never expose private keys with real funds

## Usage

### Compile

Use `forge build` or `make build`

### Testing

Use `forge test` or `make test`
Use `make coverage` to get the coverage report

> [!TIP]
> To run a specific test use `forge test --mt <TEST_NAME>`

>[!NOTE]
> Some formal verification is made in this repo. Follow the instructions in the README file in the `certora` folder

### Deploy
```bash
make deploy-all
```

## Disclaimer
This is a WIP project. Current contracts are not audited, and the code does not apply all the use cases of the project.

## Contribute 
Contribute by creating a gas optimization or no risk issue through github issues. 
Contribute by sending critical issues/ vulnerabilities to info@takadao.io. 

[top](#the-life-dao-smart-contracts)


