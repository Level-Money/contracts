# ISignatureUtils
[Git Source](https://github.com/Level-Money/contracts/blob/596e7d17f2f0a509e7a447183bc335cd46833918/src/interfaces/eigenlayer/ISignatureUtils.sol)

**Author:**
Layr Labs, Inc.

Terms of Service: https://docs.eigenlayer.xyz/overview/terms-of-service


## Structs
### SignatureWithExpiry

```solidity
struct SignatureWithExpiry {
    bytes signature;
    uint256 expiry;
}
```

### SignatureWithSaltAndExpiry

```solidity
struct SignatureWithSaltAndExpiry {
    bytes signature;
    bytes32 salt;
    uint256 expiry;
}
```

