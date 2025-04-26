# ISignatureUtils
[Git Source](https://github.com/Level-Money/contracts/blob/2607489a5c9f8e78f7e44db8057f41dc3a8c07c9/src/v1/interfaces/eigenlayer/ISignatureUtils.sol)

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

