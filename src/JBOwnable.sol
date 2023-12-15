// SPDX-License-Identifier: MIT
// Juicebox variation on OpenZeppelin Ownable
pragma solidity ^0.8.0;

import {JBOwnableOverrides, IJBProjects, IJBPermissions} from "./JBOwnableOverrides.sol";

contract JBOwnable is JBOwnableOverrides {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @param projects the JBProjects to use to get the owner of the project
     *   @param permissions the permissions to use for the permissions
     */
    constructor(IJBProjects projects, IJBPermissions permissions) JBOwnableOverrides(projects, permissions) {}

    /**
     * @dev Throws if called by an account that is not the owner and does not have permission to act as the owner
     */
    modifier onlyOwner() virtual {
        _checkOwner();
        _;
    }

    function _emitTransferEvent(address previousOwner, address newOwner) internal virtual override {
        emit OwnershipTransferred(previousOwner, newOwner);
    }
}
