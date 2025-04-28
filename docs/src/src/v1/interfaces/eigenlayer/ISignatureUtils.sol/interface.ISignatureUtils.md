# ISignatureUtils
[Git Source](https://github.com/Level-Money/contracts/blob/8e1575e7e26fdc58ac15be6578d36ba7aa02390c/src/v1/interfaces/eigenlayer/ISignatureUtils.sol)

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

