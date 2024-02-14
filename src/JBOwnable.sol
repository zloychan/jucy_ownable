// SPDX-License-Identifier: MIT
// Juicebox variation on OpenZeppelin Ownable
pragma solidity ^0.8.23;

import {IJBProjects} from "@bananapus/core/src/interfaces/IJBProjects.sol";
import {IJBPermissions} from "@bananapus/core/src/interfaces/IJBPermissions.sol";

import {JBOwnableOverrides} from "./JBOwnableOverrides.sol";

contract JBOwnable is JBOwnableOverrides {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @param projects The `IJBProjects` to use for tracking project ownership.
    /// @param permissions The `IJBPermissions` to use for managing permissions.
    constructor(IJBProjects projects, IJBPermissions permissions) JBOwnableOverrides(projects, permissions) {}

    /// @notice Reverts if called by an address that is not the owner and does not have permission from the owner.
    modifier onlyOwner() virtual {
        _checkOwner();
        _;
    }

    function _emitTransferEvent(address previousOwner, address newOwner) internal virtual override {
        emit OwnershipTransferred(previousOwner, newOwner);
    }
}
