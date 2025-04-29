# ISignatureUtils
[Git Source](https://github.com/Level-Money/contracts/blob/0fa663cd541ef95fb08cd2849fd8cc2be3967548/src/v1/interfaces/eigenlayer/ISignatureUtils.sol)

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

