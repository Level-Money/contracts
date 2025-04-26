# EigenlayerReserveManager
[Git Source](https://github.com/Level-Money/contracts/blob/2607489a5c9f8e78f7e44db8057f41dc3a8c07c9/src/v1/reserve/LevelEigenlayerReserveManager.sol)

**Inherits:**
[LevelBaseReserveManager](/src/v1/reserve/LevelBaseReserveManager.sol/abstract.LevelBaseReserveManager.md)


## State Variables
### delegationManager

```solidity
address public delegationManager;
```


### strategyManager

```solidity
address public strategyManager;
```


### rewardsCoordinator

```solidity
address public rewardsCoordinator;
```


### operatorName

```solidity
string public operatorName;
```


## Functions
### constructor


```solidity
constructor(
    IlvlUSD _lvlusd,
    address _delegationManager,
    address _strategyManager,
    address _rewardsCoordinator,
    IStakedlvlUSD _stakedlvlUSD,
    address _admin,
    address _allowlister,
    string memory _operatorName
) LevelBaseReserveManager(_lvlusd, _stakedlvlUSD, _admin, _allowlister);
```

### delegateTo


```solidity
function delegateTo(address operator, bytes memory signature, uint256 expiry, bytes32 approverSalt)
    external
    onlyRole(MANAGER_AGENT_ROLE)
    whenNotPaused;
```

### undelegate


```solidity
function undelegate() external onlyRole(MANAGER_AGENT_ROLE) whenNotPaused;
```

### depositIntoStrategy


```solidity
function depositIntoStrategy(address strategy, address token, uint256 amount)
    external
    onlyRole(MANAGER_AGENT_ROLE)
    whenNotPaused;
```

### depositAllTokensIntoStrategy


```solidity
function depositAllTokensIntoStrategy(address[] calldata tokens, IStrategy[] calldata strategies)
    external
    onlyRole(MANAGER_AGENT_ROLE)
    whenNotPaused;
```

### queueWithdrawals


```solidity
function queueWithdrawals(IStrategy[] memory strategies, uint256[] memory shares)
    external
    onlyRole(MANAGER_AGENT_ROLE)
    whenNotPaused
    returns (bytes32[] memory);
```

### completeQueuedWithdrawal


```solidity
function completeQueuedWithdrawal(
    uint256 nonce,
    address operator,
    uint32 startBlock,
    IERC20[] calldata tokens,
    IStrategy[] memory strategies,
    uint256[] memory shares
) external onlyRole(MANAGER_AGENT_ROLE) whenNotPaused;
```

### setRewardsClaimer


```solidity
function setRewardsClaimer(address claimer) external onlyRole(MANAGER_AGENT_ROLE) whenNotPaused;
```

### setDelegationManager


```solidity
function setDelegationManager(address _delegationManager) external onlyRole(DEFAULT_ADMIN_ROLE);
```

### setStrategyManager


```solidity
function setStrategyManager(address _strategyManager) external onlyRole(DEFAULT_ADMIN_ROLE);
```

### setRewardsCoordinator


```solidity
function setRewardsCoordinator(address _rewardsCoordinator) external onlyRole(DEFAULT_ADMIN_ROLE);
```

### setOperatorName


```solidity
function setOperatorName(string calldata _operatorName) external onlyRole(DEFAULT_ADMIN_ROLE);
```

## Events
### Undelegated

```solidity
event Undelegated();
```

### DelegatedToOperator

```solidity
event DelegatedToOperator(address operator);
```

## Errors
### StrategiesAndSharesMustBeSameLength

```solidity
error StrategiesAndSharesMustBeSameLength();
```

### StrategiesAndTokensMustBeSameLength

```solidity
error StrategiesAndTokensMustBeSameLength();
```

### StrategiesSharesAndTokensMustBeSameLength

```solidity
error StrategiesSharesAndTokensMustBeSameLength();
```

