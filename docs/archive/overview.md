## Summary
The Level Protocol allows users to earn yield from restaking protocols and lending protocols by
staking a stablecoin called lvlUSD. Level will generate returns by lending out its reserves in Aave and Compound,
and further earn points restaking rewards for users by depositing liquid restaking tokens in Symbiotic, Eigenlayer, and Karak vaults.

LevelMinting is the contract for minting and redeeming lvlUSD. The redemption process has two steps and can take several
days due to a cooldown period. Collateral provided by users is routed to the LevelReserveManager. An admin multisig wallet
controls the funds in LevelReserveManager, and can initiate deposits and withdrawals into pools and vaults.

When funds are deposited into Symbiotic or Karak vaults, they are delegated to networks, for example, actively validated services (AVSes), or operators, who run node network infrastructure. The vaults may earn rewards, which are sent to a pre-specified rewards contract. The funds in the vault may also be slashed, depending on the vault implementation.

## Design Considerations and Potential Concerns
- To migrate the Level Reserve Manager contract, we plan to simply deploy a new contract, and transfer all funds from the previous contract to the new contract by first withdrawing from vaults (possibly waiting for a cooldown period to end), and then using `transferERC20` to transfer the funds to the new contract. We want to make sure that there aren't any edge cases that would prevent an upgrade or migration. We are also considering bricking the previous contract after a new reserve manager has been deployed, or using the OpenZeppelin upgradeable proxy pattern to ensure that an upgrade can go smoothly.
- The multisig admin is a centralization vector, we eventually might want to automate the deployment of capital to vaults, or do it via governance. Right now a multisig effectively controls all funds within the reserve manager. The allowlist manager role mitigates this by allowing funds to be sent to certain addresses, however the admin appoints the allowlist manager.

## Dependencies
Karak and Symbiotic vaults accept collateral and then delegate the collateral to operators, who are entrusted with the task of securing decentralized secure service (DSS). Usually, when funds are delegated, they generate yield but also risk being slashed if the operators do not behave properly when securing a DSS. Our interactions with these protocols is limited to depositing and withdrawing from vaults. In the future, we will also have to design a way to collect rewards and redistribute them to our users.

### Karak
- Karak is a restaking layer that provides security for chains by connecting stakers with operators and networks ([Docs](https://docs.karak.network/))
- Source code for [vaults](https://github.com/code-423n4/2024-07-karak/blob/main/src/interfaces/IVault.sol)

### Symbiotic
- Symbiotic is an accounting and coordination layer for networks, operators, and vaults to work together to provide economic security to networks ([Docs](https://docs.symbiotic.fi/))
- Source code for [vaults](https://github.com/symbioticfi/core/blob/main/src/contracts/vault/Vault.sol)
