// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

/**
 * solhint-disable private-vars-leading-underscore
 */
import "forge-std/console2.sol";
import "forge-std/Vm.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {CREATE3} from "@solmate/src/utils/CREATE3.sol";

contract DeploymentUtils is StdUtils {
    error USER_NOT_OWNER();
    error USER_LACKS_ROLE();
    error ADDRESS_DERIVATION_ERROR();
    error MISSING_CHAIN_ID(string message);

    /**
     * @notice Emitted on `deployContract` calls.
     * @param name string name used to derive salt for deployment
     * @param contractAddress the newly deployed contract address
     * @param creationCodeHash keccak256 hash of the creation code
     *        - useful to determine creation code is the same across multiple chains
     */
    event ContractDeployed(string name, address contractAddress, bytes32 creationCodeHash);

    Vm private constant vm = Vm(address(bytes20(uint160(uint256(keccak256("hevm cheat code"))))));

    /**
     * @notice Deploy some contract to a deterministic address.
     * @param name string used to derive salt for deployment
     * @dev Should be of form:
     *      "ContractName Version 0.0"
     *      Where the numbers after version are VERSION . SUBVERSION
     * @param creationCode the contract creation code to deploy
     *        - can be obtained by calling type(contractName).creationCode
     * @param constructorArgs the contract constructor arguments if any
     *        - must be of form abi.encode(arg1, arg2, ...)
     * @param value non zero if constructor needs to be payable
     */
    function deployContract(
        string calldata name,
        bytes memory creationCode,
        bytes calldata constructorArgs,
        uint256 value
    ) public returns (address) {
        bytes32 creationCodeHash = keccak256(creationCode);

        if (constructorArgs.length > 0) {
            // Append constructor args to end of creation code.
            creationCode = abi.encodePacked(creationCode, constructorArgs);
        }

        bytes32 salt = convertNameToBytes32(name);

        address contractAddress = CREATE3.deploy(salt, creationCode, value);

        emit ContractDeployed(name, contractAddress, creationCodeHash);

        return contractAddress;
    }

    function convertNameToBytes32(string memory name) public pure returns (bytes32) {
        return keccak256(abi.encode(name));
    }

    // Deployment checks //

    // Ensures that the given user is the owner of the specified contract
    function _utilsIsOwner(address user, address contractAddr) internal view {
        address owner = Ownable(contractAddr).owner();

        if (owner != user) revert USER_NOT_OWNER();
    }

    // Ensures that given user has a certain role
    function _utilsHasRole(bytes32 role, address user, address contractAddr) internal view {
        bool userHasRole = IAccessControl(contractAddr).hasRole(role, user);

        if (!userHasRole) revert USER_LACKS_ROLE();
    }

    function _printDeployedContracts(uint256 chainId, string memory name, address contractAddress) public pure {
        string memory baseUrl = _getEtherscanBaseUrl(chainId);
        console2.log("%s                          : %s/address/%s", name, baseUrl, contractAddress);
    }

    function _getEtherscanBaseUrl(uint256 chainId) internal pure returns (string memory) {
        if (chainId == 1) {
            return "https://etherscan.io/";
        } else if (chainId == 17000) {
            return "https://holesky.etherscan.io/";
        } else if (chainId == 11155111) {
            return "https://sepolia.etherscan.io";
        } else {
            revert MISSING_CHAIN_ID("Set CHAIN_ID in .env");
        }
    }

    // add this to be excluded from coverage report
    function test() public virtual {}
}
