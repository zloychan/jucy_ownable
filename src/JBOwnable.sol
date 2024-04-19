// SPDX-License-Identifier: MIT
// Juicebox variation on OpenZeppelin Ownable
pragma solidity ^0.8.23;

import {IJBProjects} from "@bananapus/core/src/interfaces/IJBProjects.sol";
import {IJBPermissions} from "@bananapus/core/src/interfaces/IJBPermissions.sol";

import {JBOwnableOverrides} from "./JBOwnableOverrides.sol";

/// @notice A function restricted by `JBOwnable` can only be called by a Juicebox project's owner, a specified owner address (if set), or addresses with permission from the owner.
/// @dev A function with the `onlyOwner` modifier from `JBOwnable` can only be called by addresses with owner access based on a `JBOwner` struct:
/// 1. If `JBOwner.projectId` isn't zero, the address holding the `JBProjects` NFT with the `JBOwner.projectId` ID is the owner.
/// 2. If `JBOwner.projectId` is set to `0`, the `JBOwner.owner` address is the owner.
/// 3. The owner can give other addresses access with `JBPermissions.setPermissionsFor(...)`, using the `JBOwner.permissionId` permission.
/// @dev To use `onlyOwner`, inherit this contract and apply the modifier to a function.
contract JBOwnable is JBOwnableOverrides {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @dev To make a Juicebox project's owner this contract's owner, pass that project's ID as the `initialProjectIdOwner`.
    /// @dev To make a specific address the owner, pass that address as the `initialOwner` and `0` as the `initialProjectIdOwner`.
    /// @dev The owner can give other addresses owner access through the `permissions` contract.
    /// @param projects Mints ERC-721s that represent project ownership and transfers.
    /// @param permissions A contract storing permissions.
    /// @param initialOwner An address with owner access (until ownership is transferred).
    /// @param initialProjectIdOwner The ID of the Juicebox project whose owner has owner access (until ownership is transferred).
    constructor(
        IJBProjects projects,
        IJBPermissions permissions,
        address initialOwner,
        uint88 initialProjectIdOwner
    )
        JBOwnableOverrides(projects, permissions, initialOwner, initialProjectIdOwner)
    {}

    /// @notice Reverts if called by an address without owner access.
    modifier onlyOwner() virtual {
        _checkOwner();
        _;
    }

    function _emitTransferEvent(
        address previousOwner,
        address newOwner,
        uint88 newProjectId
    )
        internal
        virtual
        override
    {
        emit OwnershipTransferred(previousOwner, newProjectId == 0 ? newOwner : PROJECTS.ownerOf(newProjectId));
    }
}
