// SPDX-License-Identifier: MIT
// Juicebox variation on OpenZeppelin Ownable
pragma solidity ^0.8.23;

import {IJBProjects} from "@bananapus/core/src/interfaces/IJBProjects.sol";
import {IJBPermissions} from "@bananapus/core/src/interfaces/IJBPermissions.sol";

import {JBOwnableOverrides} from "./JBOwnableOverrides.sol";

contract JBOwnable is JBOwnableOverrides {
    //*********************************************************************//
    // -------------------------- constructor ---------------------------- //
    //*********************************************************************//

    /// @param permissions The `IJBPermissions` to use for managing permissions.
    /// @param projects The `IJBProjects` to use for tracking project ownership.
    /// @param initialOwner The initial owner of the contract.
    /// @param initialProjectIdOwner The initial project id that owns this contract.
    constructor(
        IJBPermissions permissions,
        IJBProjects projects,
        address initialOwner,
        uint88 initialProjectIdOwner
    )
        JBOwnableOverrides(permissions, projects, initialOwner, initialProjectIdOwner)
    {}

    //*********************************************************************//
    // --------------------------- modifiers ----------------------------- //
    //*********************************************************************//

    /// @notice Reverts if called by an address that is not the owner and does not have permission from the owner.
    modifier onlyOwner() virtual {
        _checkOwner();
        _;
    }

    //*********************************************************************//
    // ------------------------ internal functions ----------------------- //
    //*********************************************************************//

    /// @notice Either `newOwner` or `newProjectId` is non-zero or both are zero. But they can never both be non-zero.
    /// @dev This function exists because some contracts will try to deploy contracts for a project before
    function _emitTransferEvent(
        address previousOwner,
        address newOwner,
        uint88 newProjectId
    )
        internal
        virtual
        override
    {
        emit OwnershipTransferred({
            previousOwner: previousOwner,
            newOwner: newProjectId == 0 ? newOwner : PROJECTS.ownerOf(newProjectId),
            caller: msg.sender
        });
    }
}
