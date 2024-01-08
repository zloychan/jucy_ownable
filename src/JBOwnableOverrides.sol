// SPDX-License-Identifier: MIT
// Juicebox variation on OpenZeppelin Ownable
pragma solidity ^0.8.23;

import {Context} from "lib/openzeppelin-contracts/contracts/utils/Context.sol";
import {IJBPermissioned} from "lib/juice-contracts-v4/src/interfaces/IJBPermissioned.sol";
import {IJBPermissions} from "lib/juice-contracts-v4/src/interfaces/IJBPermissions.sol";
import {IJBProjects} from "lib/juice-contracts-v4/src/interfaces/IJBProjects.sol";

import {JBOwner} from "./struct/JBOwner.sol";
import {IJBOwnable} from "./interfaces/IJBOwnable.sol";

/// @notice Access control module to grant exclusive access to a specified address (the owner) for specific functions. The owner can also grant access permissions to other addresses via `JBPermissions`.
/// @dev Inherit this contract to make the `onlyOwner` modifier available. When applied to a function, this modifier restricts use to the owner and addresses with the appropriate permission from the owner.
/// @dev Supports meta-transactions.
abstract contract JBOwnableOverrides is Context, IJBOwnable, IJBPermissioned {
    //*********************************************************************//
    // --------------------------- custom errors --------------------------//
    //*********************************************************************//

    error UNAUTHORIZED();
    error INVALID_NEW_OWNER();

    //*********************************************************************//
    // ---------------- public immutable stored properties --------------- //
    //*********************************************************************//

    /// @notice A contract storing permissions.
    IJBPermissions public immutable PERMISSIONS;

    /// @notice Mints ERC-721s that represent project ownership and transfers.
    IJBProjects public immutable PROJECTS;

    //*********************************************************************//
    // --------------------- public stored properties -------------------- //
    //*********************************************************************//

    /// @notice This contract's owner information.
    JBOwner public override jbOwner;

    //*********************************************************************//
    // -------------------------- constructor ---------------------------- //
    //*********************************************************************//

    /// @param projects The `IJBProjects` to use for tracking project ownership.
    /// @param permissions The `IJBPermissions` to use for managing permissions.
    constructor(IJBProjects projects, IJBPermissions permissions) {
        PERMISSIONS = permissions;
        PROJECTS = projects;

        _transferOwnership(msg.sender);
    }

    //*********************************************************************//
    // --------------------------- public methods ------------------------ //
    //*********************************************************************//

    /// @notice Returns the owner's address based on this contract's `JBOwner` owner information.
    function owner() public view virtual returns (address) {
        JBOwner memory ownerInfo = jbOwner;

        if (ownerInfo.projectId == 0) {
            return ownerInfo.owner;
        }

        return PROJECTS.ownerOf(ownerInfo.projectId);
    }

    /// @notice Gives up ownership of this contract, making it impossible to call `onlyOwner`/`_checkOwner` functions.
    /// Can only be called by the current owner.
    function renounceOwnership() public virtual {
        _checkOwner();
        _transferOwnership(address(0), 0);
    }

    /// @notice Transfers ownership of this contract to a new account (the `newOwner`). Can only be called by the current owner.
    /// @param newOwner The address that should receive ownership of this contract.
    function transferOwnership(address newOwner) public virtual {
        _checkOwner();
        if (newOwner == address(0)) {
            revert INVALID_NEW_OWNER();
        }

        _transferOwnership(newOwner, 0);
    }

    /// @notice Transfer ownership of this contract to a new Juicebox project.
    /// @dev The `projectId` must fit within a `uint88`.
    /// @param projectId The ID of the project that should receive ownership of this contract.
    function transferOwnershipToProject(uint256 projectId) public virtual {
        _checkOwner();
        if (projectId == 0 || projectId > type(uint88).max) {
            revert INVALID_NEW_OWNER();
        }

        _transferOwnership(address(0), uint88(projectId));
    }

    /// @notice Sets the permission ID which, when granted from the owner, allows other addresses to perform operations on their behalf.
    /// @param permissionId The ID of the permission to use for `onlyOwner`.
    function setPermissionId(uint8 permissionId) public virtual {
        _checkOwner();
        _setPermissionId(permissionId);
    }

    //*********************************************************************//
    // -------------------------- internal methods ----------------------- //
    //*********************************************************************//

    /// @notice Sets the permission ID which, when granted from the owner, allows other addresses to perform operations on their behalf.
    /// @dev Internal function without access restriction.
    /// @param permissionId The ID of the permission to use for `onlyOwner`.
    function _setPermissionId(uint8 permissionId) internal virtual {
        jbOwner.permissionId = permissionId;
        emit PermissionIdChanged(permissionId);
    }

    /// @notice Helper to allow for drop-in replacement of OpenZeppelin.
    /// @param newOwner The address that should receive ownership of this contract.
    function _transferOwnership(address newOwner) internal virtual {
        _transferOwnership(newOwner, 0);
    }

    /// @notice Transfers this contract's ownership to an address (`newOwner`) OR a Juicebox project (`projectId`).
    /// @dev Updates this contract's `JBOwner` owner information.
    /// @dev If both `newOwner` and `projectId` are set, this will revert.
    /// @dev Internal function without access restriction.
    /// @param newOwner The address that should receive ownership of this contract.
    /// @param projectId The ID of the project that this contract should respect the ownership of.
    function _transferOwnership(address newOwner, uint88 projectId) internal virtual {
        // Can't set both a new owner and a new project ID.
        if (projectId != 0 && newOwner != address(0)) {
            revert INVALID_NEW_OWNER();
        }
        // Load the owner information from storage.
        JBOwner memory ownerInfo = jbOwner;
        // Get the address of the old owner.
        address oldOwner = ownerInfo.projectId == 0 ? ownerInfo.owner : PROJECTS.ownerOf(ownerInfo.projectId);
        // Update the stored owner information to the new owner and reset the `permissionId`.
        // This is to prevent permissions clashes for the new user/owner.
        jbOwner = JBOwner({owner: newOwner, projectId: projectId, permissionId: 0});
        // Emit a transfer event with the new owner's address.
        _emitTransferEvent(oldOwner, projectId == 0 ? newOwner : PROJECTS.ownerOf(projectId));
    }

    //*********************************************************************//
    // -------------------------- internal views ------------------------- //
    //*********************************************************************//

    /// @notice Reverts if the sender is not the owner.
    function _checkOwner() internal view virtual {
        JBOwner memory ownerInfo = jbOwner;

        _requirePermissionFrom({
            account: ownerInfo.projectId == 0 ? ownerInfo.owner : PROJECTS.ownerOf(ownerInfo.projectId),
            projectId: ownerInfo.projectId,
            permissionId: ownerInfo.permissionId
        });
    }

    /// @notice Only allows the specified account or an operator with the specified permission ID from that account to proceed.
    /// @param account The account to allow.
    /// @param projectId The ID of the project to look for an operator within.
    /// @param permissionId The ID of the permission to check for.
    function _requirePermissionFrom(address account, uint256 projectId, uint256 permissionId) internal view virtual {
        address sender = _msgSender();
        if (
            sender != account && !PERMISSIONS.hasPermission(sender, account, projectId, permissionId)
                && !PERMISSIONS.hasPermission(sender, account, 0, permissionId)
        ) revert UNAUTHORIZED();
    }

    /// @notice If the `override` flag is true, proceed. Otherwise, only allows the specified account or an operator with the specified permission ID from that account to proceed.
    /// @param account The account to allow.
    /// @param projectId The ID of the pproject to look for an operator within. TODO: remove
    /// @param permissionId The ID of the permission to check for.
    /// @param alsoGrantAccessIf An override condition which will allow access regardless of permissions.     */
    function _requirePermissionAllowingOverrideFrom(
        address account,
        uint256 projectId,
        uint256 permissionId,
        bool alsoGrantAccessIf
    )
        internal
        view
        virtual
    {
        // Return early if the override flag is true.
        if (alsoGrantAccessIf) return;
        // Otherwise, perform a standard check.
        _requirePermissionFrom(account, projectId, permissionId);
    }

    function _emitTransferEvent(address previousOwner, address newOwner) internal virtual;
}
