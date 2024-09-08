export const LevelReserveManagerABI = [
  {
    type: "constructor",
    inputs: [
      { name: "_lvlusd", type: "address", internalType: "contract IlvlUSD" },
      {
        name: "_aavePoolProxy",
        type: "address",
        internalType: "contract IPool",
      },
      {
        name: "_stakedlvlUSD",
        type: "address",
        internalType: "contract IStakedlvlUSD",
      },
      { name: "_admin", type: "address", internalType: "address" },
    ],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "DEFAULT_ADMIN_ROLE",
    inputs: [],
    outputs: [{ name: "", type: "bytes32", internalType: "bytes32" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "aaveNetAmountDeposited",
    inputs: [{ name: "", type: "address", internalType: "address" }],
    outputs: [{ name: "", type: "uint256", internalType: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "aavePoolProxy",
    inputs: [],
    outputs: [{ name: "", type: "address", internalType: "contract IPool" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "acceptAdmin",
    inputs: [],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "approveSpender",
    inputs: [
      { name: "token", type: "address", internalType: "address" },
      { name: "spender", type: "address", internalType: "address" },
      { name: "amount", type: "uint256", internalType: "uint256" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "claimFromSymbiotic",
    inputs: [
      { name: "vault", type: "address", internalType: "address" },
      { name: "epoch", type: "uint256", internalType: "uint256" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "convertATokensTolvlUSDAndDepositIntoStakedlvlUSD",
    inputs: [
      { name: "aToken", type: "address", internalType: "address" },
      { name: "amount", type: "uint256", internalType: "uint256" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "convertATokentolvlUSD",
    inputs: [
      { name: "underlying", type: "address", internalType: "address" },
      { name: "amount", type: "uint256", internalType: "uint256" },
    ],
    outputs: [{ name: "", type: "uint256", internalType: "uint256" }],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "depositToAave",
    inputs: [
      { name: "token", type: "address", internalType: "address" },
      { name: "amount", type: "uint256", internalType: "uint256" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "depositToKarak",
    inputs: [
      { name: "vault", type: "address", internalType: "address" },
      { name: "amount", type: "uint256", internalType: "uint256" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "depositToLevelMinting",
    inputs: [
      { name: "token", type: "address", internalType: "address" },
      { name: "amount", type: "uint256", internalType: "uint256" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "depositToStakedlvlUSD",
    inputs: [{ name: "amount", type: "uint256", internalType: "uint256" }],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "depositToSymbiotic",
    inputs: [
      { name: "vault", type: "address", internalType: "address" },
      { name: "amount", type: "uint256", internalType: "uint256" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "finishRedeemFromKarak",
    inputs: [
      { name: "vault", type: "address", internalType: "address" },
      { name: "withdrawalKey", type: "bytes32", internalType: "bytes32" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "getRoleAdmin",
    inputs: [{ name: "role", type: "bytes32", internalType: "bytes32" }],
    outputs: [{ name: "", type: "bytes32", internalType: "bytes32" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "grantRole",
    inputs: [
      { name: "role", type: "bytes32", internalType: "bytes32" },
      { name: "account", type: "address", internalType: "address" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "hasRole",
    inputs: [
      { name: "role", type: "bytes32", internalType: "bytes32" },
      { name: "account", type: "address", internalType: "address" },
    ],
    outputs: [{ name: "", type: "bool", internalType: "bool" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "lvlusd",
    inputs: [],
    outputs: [{ name: "", type: "address", internalType: "contract IlvlUSD" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "mintlvlUSD",
    inputs: [
      { name: "collateral", type: "address", internalType: "address" },
      { name: "amount", type: "uint256", internalType: "uint256" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "owner",
    inputs: [],
    outputs: [{ name: "", type: "address", internalType: "address" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "renounceRole",
    inputs: [
      { name: "role", type: "bytes32", internalType: "bytes32" },
      { name: "account", type: "address", internalType: "address" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "revokeRole",
    inputs: [
      { name: "role", type: "bytes32", internalType: "bytes32" },
      { name: "account", type: "address", internalType: "address" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "setAaveV3PoolAddress",
    inputs: [{ name: "newAddress", type: "address", internalType: "address" }],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "setRoute",
    inputs: [
      {
        name: "newRoute",
        type: "tuple",
        internalType: "struct ILevelMinting.Route",
        components: [
          { name: "addresses", type: "address[]", internalType: "address[]" },
          { name: "ratios", type: "uint256[]", internalType: "uint256[]" },
        ],
      },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "setStakedlvlUSDAddress",
    inputs: [{ name: "newAddress", type: "address", internalType: "address" }],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "setSymbioticVaultAddress",
    inputs: [{ name: "newAddress", type: "address", internalType: "address" }],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "stakedlvlUSD",
    inputs: [],
    outputs: [
      { name: "", type: "address", internalType: "contract IStakedlvlUSD" },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "startRedeemFromKarak",
    inputs: [
      { name: "vault", type: "address", internalType: "address" },
      { name: "shares", type: "uint256", internalType: "uint256" },
    ],
    outputs: [
      { name: "withdrawalKey", type: "bytes32", internalType: "bytes32" },
    ],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "supportsInterface",
    inputs: [{ name: "interfaceId", type: "bytes4", internalType: "bytes4" }],
    outputs: [{ name: "", type: "bool", internalType: "bool" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "symbioticVault",
    inputs: [],
    outputs: [{ name: "", type: "address", internalType: "contract IVault" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "transferAdmin",
    inputs: [{ name: "newAdmin", type: "address", internalType: "address" }],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "transferERC20",
    inputs: [
      { name: "tokenAddress", type: "address", internalType: "address" },
      { name: "tokenReceiver", type: "address", internalType: "address" },
      { name: "tokenAmount", type: "uint256", internalType: "uint256" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "transferEth",
    inputs: [
      { name: "_to", type: "address", internalType: "address payable" },
      { name: "_amount", type: "uint256", internalType: "uint256" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "withdrawFromAave",
    inputs: [
      { name: "token", type: "address", internalType: "address" },
      { name: "amount", type: "uint256", internalType: "uint256" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "withdrawFromSymbiotic",
    inputs: [
      { name: "vault", type: "address", internalType: "address" },
      { name: "amount", type: "uint256", internalType: "uint256" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "event",
    name: "AdminTransferRequested",
    inputs: [
      {
        name: "oldAdmin",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "newAdmin",
        type: "address",
        indexed: true,
        internalType: "address",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "AdminTransferred",
    inputs: [
      {
        name: "oldAdmin",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "newAdmin",
        type: "address",
        indexed: true,
        internalType: "address",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "ClaimedFromSymbiotic",
    inputs: [
      {
        name: "epoch",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
      {
        name: "amount",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
      {
        name: "symbioticVault",
        type: "address",
        indexed: false,
        internalType: "address",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "DepositedToAave",
    inputs: [
      {
        name: "amount",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
      {
        name: "token",
        type: "address",
        indexed: false,
        internalType: "address",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "DepositedToKarak",
    inputs: [
      {
        name: "amount",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
      {
        name: "karakVault",
        type: "address",
        indexed: false,
        internalType: "address",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "DepositedToLevelMinting",
    inputs: [
      {
        name: "amount",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "DepositedToStakedlvlUSD",
    inputs: [
      {
        name: "amount",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "DepositedToSymbiotic",
    inputs: [
      {
        name: "amount",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
      {
        name: "symbioticVault",
        type: "address",
        indexed: false,
        internalType: "address",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "RedeemFromKarakFinished",
    inputs: [
      {
        name: "karakVault",
        type: "address",
        indexed: false,
        internalType: "address",
      },
      {
        name: "withdrawalKey",
        type: "bytes32",
        indexed: false,
        internalType: "bytes32",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "RedeemFromKarakStarted",
    inputs: [
      {
        name: "shares",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
      {
        name: "karakVault",
        type: "address",
        indexed: false,
        internalType: "address",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "RoleAdminChanged",
    inputs: [
      { name: "role", type: "bytes32", indexed: true, internalType: "bytes32" },
      {
        name: "previousAdminRole",
        type: "bytes32",
        indexed: true,
        internalType: "bytes32",
      },
      {
        name: "newAdminRole",
        type: "bytes32",
        indexed: true,
        internalType: "bytes32",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "RoleGranted",
    inputs: [
      { name: "role", type: "bytes32", indexed: true, internalType: "bytes32" },
      {
        name: "account",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "sender",
        type: "address",
        indexed: true,
        internalType: "address",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "RoleRevoked",
    inputs: [
      { name: "role", type: "bytes32", indexed: true, internalType: "bytes32" },
      {
        name: "account",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "sender",
        type: "address",
        indexed: true,
        internalType: "address",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "WithdrawnFromAave",
    inputs: [
      {
        name: "amount",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
      {
        name: "token",
        type: "address",
        indexed: false,
        internalType: "address",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "WithdrawnFromSymbiotic",
    inputs: [
      {
        name: "amount",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
      {
        name: "symbioticVault",
        type: "address",
        indexed: false,
        internalType: "address",
      },
    ],
    anonymous: false,
  },
  { type: "error", name: "AlreadyClaimed", inputs: [] },
  { type: "error", name: "AlreadySet", inputs: [] },
  { type: "error", name: "DepositLimitReached", inputs: [] },
  { type: "error", name: "InsufficientClaim", inputs: [] },
  { type: "error", name: "InsufficientDeposit", inputs: [] },
  { type: "error", name: "InsufficientWithdrawal", inputs: [] },
  { type: "error", name: "InvalidAccount", inputs: [] },
  { type: "error", name: "InvalidCaptureEpoch", inputs: [] },
  { type: "error", name: "InvalidClaimer", inputs: [] },
  { type: "error", name: "InvalidCollateral", inputs: [] },
  { type: "error", name: "InvalidEpoch", inputs: [] },
  { type: "error", name: "InvalidEpochDuration", inputs: [] },
  { type: "error", name: "InvalidLengthEpochs", inputs: [] },
  { type: "error", name: "InvalidOnBehalfOf", inputs: [] },
  { type: "error", name: "InvalidRecipient", inputs: [] },
  { type: "error", name: "MissingRoles", inputs: [] },
  { type: "error", name: "NoDepositLimit", inputs: [] },
  { type: "error", name: "NoDepositWhitelist", inputs: [] },
  { type: "error", name: "NotDelegator", inputs: [] },
  { type: "error", name: "NotSlasher", inputs: [] },
  { type: "error", name: "NotWhitelistedDepositor", inputs: [] },
  { type: "error", name: "TooMuchWithdraw", inputs: [] },

  { type: "error", name: "InsufficientATokensInReserve", inputs: [] },
  { type: "error", name: "InvalidAdminChange", inputs: [] },
  { type: "error", name: "InvalidAmount", inputs: [] },
  { type: "error", name: "InvalidZeroAddress", inputs: [] },
  { type: "error", name: "InvalidlvlUSDAddress", inputs: [] },
  { type: "error", name: "NotPendingAdmin", inputs: [] },
  { type: "error", name: "ZeroExcessAToken", inputs: [] },
] as const;