// SPDX-License-Identifier: MIT
// Juicebox variation on OpenZeppelin Ownable

pragma solidity ^0.8.23;

import {JBOwner} from "./struct/JBOwner.sol";
import {IJBOwnable} from "./interfaces/IJBOwnable.sol";

import {IJBPermissioned} from "lib/juice-contracts-v4/src/interfaces/IJBPermissioned.sol";
import {IJBPermissions} from "lib/juice-contracts-v4/src/interfaces/IJBPermissions.sol";
import {IJBProjects} from "lib/juice-contracts-v4/src/interfaces/IJBProjects.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/**
 * @notice Access control module to grant exclusive access to a specified address (the owner) for specific functions. The
 * owner can also grant access permissions to other addresses via `JBPermissions`.
 * @dev Inherit this contract to make the `onlyOwner` modifier available. When applied to a function, this modifier
 * restricts
 * use to the owner and addresses with the appropriate permission from the owner.
 * @dev Supports meta-transactions.
 */
abstract contract JBOwnableOverrides is Context, IJBOwnable, IJBPermissioned {
    //*********************************************************************//
    // --------------------------- custom errors --------------------------//
    //*********************************************************************//

    error UNAUTHORIZED();
    error INVALID_NEW_OWNER(address ownerAddress, uint256 projectId);

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

    /**
     * @param projects The `IJBProjects` to use for tracking project ownership.
     * @param permissions The `IJBPermissions` to use for managing permissions.
     */
    constructor(IJBProjects projects, IJBPermissions permissions) {
        PERMISSIONS = permissions;
        PROJECTS = projects;

        _transferOwnership(msg.sender);
    }

    //*********************************************************************//
    // ---------------------------- modifiers ---------------------------- //
    //*********************************************************************//

    /**
     * @notice Only allows the specified account or an operator with the specified permission ID from that account to
     * proceed.
     * @param account The account to allow.
     * @param domain The domain namespace to look for an operator within. TODO: remove
     * @param permissionId The ID of the permission to check for.
     */
    modifier requirePermission(address account, uint256 domain, uint256 permissionId) {
        _requirePermission(account, domain, permissionId);
        _;
    }

    /**
     * @notice Only allows a project's owner or accounts that have received the specified permission ID from the
     * project's owner to proceed.
     * @dev If this contract's `JBOwner` is not a project (i.e. if its `projectId` is 0), this modifier will always
     * revert.
     * @param permissionId The ID of the permission to check for.
     */
    modifier requirePermissionFromProject(uint256 permissionId) {
        JBOwner memory ownerInfo = jbOwner;

        // If the owner is not a project then this should always revert
        if (ownerInfo.projectId == 0) {
            revert UNAUTHORIZED();
        }

        _requirePermission({
            account: ownerInfo.projectId == 0 ? ownerInfo.owner : PROJECTS.ownerOf(ownerInfo.projectId),
            projectId: ownerInfo.projectId,
            permissionId: permissionId
        });
        _;
    }

    /**
     * @notice If the `override` flag is true, proceed. Otherwise, only allows the specified account or an operator with
     * the specified permission ID from that account to proceed.
     * @param account The account to allow.
     * @param domain The domain namespace to look for an operator within. TODO: remove
     * @param permissionId The ID of the permission to check for.
     * @param overrideFlag If this is true, override the check and proceed.
     */
    modifier requirePermissionAllowingOverride(
        address account,
        uint256 domain,
        uint256 permissionId,
        bool overrideFlag
    ) {
        _requirePermissionAllowingOverride(account, domain, permissionId, overrideFlag);
        _;
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

    /**
     * @notice Transfers ownership of this contract to a new account (the `newOwner`). Can only be called by the current
     * owner.
     * @param newOwner The address that should receive ownership of this contract.
     */
    function transferOwnership(address newOwner) public virtual {
        _checkOwner();
        if (newOwner == address(0)) {
            revert INVALID_NEW_OWNER(newOwner, 0);
        }

        _transferOwnership(newOwner, 0);
    }

    /**
     * @notice Transfer ownership of this contract to a new Juicebox project.
     * @dev The `projectId` must fit within a `uint88`.
     * @param projectId The ID of the project that should receive ownership of this contract.
     */
    function transferOwnershipToProject(uint256 projectId) public virtual {
        _checkOwner();
        if (projectId == 0 || projectId > type(uint88).max) {
            revert INVALID_NEW_OWNER(address(0), projectId);
        }

        _transferOwnership(address(0), uint88(projectId));
    }

    /**
     * @notice Sets the permission ID which, when granted from the owner, allows other addresses to perform operations
     * on their behalf.
     * @param permissionId The ID of the permission to use for `onlyOwner`.
     */
    function setPermissionId(uint8 permissionId) public virtual {
        _checkOwner();
        _setPermissionId(permissionId);
    }

    //*********************************************************************//
    // -------------------------- internal methods ----------------------- //
    //*********************************************************************//

    /**
     * @notice Sets the permission ID which, when granted from the owner, allows other addresses to perform operations
     * on their behalf.
     * @dev Internal function without access restriction.
     * @param permissionId The ID of the permission to use for `onlyOwner`.
     */
    function _setPermissionId(uint8 permissionId) internal virtual {
        jbOwner.permissionId = permissionId;
        emit PermissionIdChanged(permissionId);
    }

    /**
     * @notice Helper to allow for drop-in replacement of OpenZeppelin.
     * @param newOwner The address that should receive ownership of this contract.
     */
    function _transferOwnership(address newOwner) internal virtual {
        _transferOwnership(newOwner, 0);
    }

    /**
     * @notice Transfers this contract's ownership to an address (`newOwner`) OR a Juicebox project (`projectId`).
     * @dev Updates this contract's `JBOwner` owner information.
     * @dev If both `newOwner` and `projectId` are set, this will revert.
     * @dev Internal function without access restriction.
     * @param newOwner The address that should receive ownership of this contract.
     * @param projectId The ID of the project that this contract should respect the ownership of.
     */
    function _transferOwnership(address newOwner, uint88 projectId) internal virtual {
        // Can't set both a new owner and a new project ID.
        if (projectId != 0 && newOwner != address(0)) {
            revert INVALID_NEW_OWNER(newOwner, projectId);
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

        _requirePermission({
            account: ownerInfo.projectId == 0 ? ownerInfo.owner : PROJECTS.ownerOf(ownerInfo.projectId),
            projectId: ownerInfo.projectId,
            permissionId: ownerInfo.permissionId
        });
    }

    /**
     * @notice Only allows the specified account or an operator with the specified permission ID from that account to
     * proceed.
     * @param account The account to allow.
     * @param projectId The ID of the project to look for an operator within.
     * @param permissionId The ID of the permission to check for.
     */
    function _requirePermission(address account, uint256 projectId, uint256 permissionId) internal view virtual {
        address sender = _msgSender();
        if (
            sender != account && !PERMISSIONS.hasPermission(sender, account, projectId, permissionId)
                && !PERMISSIONS.hasPermission(sender, account, 0, permissionId)
        ) revert UNAUTHORIZED();
    }

    /**
     * @notice If the `override` flag is true, proceed. Otherwise, only allows the specified account or an operator with
     * the specified permission ID from that account to proceed.
     * @param account The account to allow.
     * @param projectId The ID of the pproject to look for an operator within. TODO: remove
     * @param permissionId The ID of the permission to check for.
     * @param overrideFlag If this is true, override the check and proceed.
     */
    function _requirePermissionAllowingOverride(
        address account,
        uint256 projectId,
        uint256 permissionId,
        bool overrideFlag
    )
        internal
        view
        virtual
    {
        // Return early if the override flag is true.
        if (overrideFlag) return;
        // Otherwise, perform a standard check.
        _requirePermission(account, projectId, permissionId);
    }

    function _emitTransferEvent(address previousOwner, address newOwner) internal virtual;
}
