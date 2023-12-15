// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {JBOwnable, JBOwnableOverrides} from "../../src/JBOwnable.sol";
import {IJBProjects} from "lib/juice-contracts-v4/src/interfaces/IJBProjects.sol";
import {IJBPermissions} from "lib/juice-contracts-v4/src/interfaces/IJBPermissions.sol";

contract MockOwnable is JBOwnable {
    event ProtectedMethodCalled();

    uint256 permission;

    function setPermission(uint256 newPermission) external {
        permission = newPermission;
    }

    constructor(IJBProjects projects, IJBPermissions permissions) JBOwnable(projects, permissions) {}

    function protectedMethod() external onlyOwner {
        emit ProtectedMethodCalled();
    }

    function protectedMethodWithRequirePermission() external requirePermissionFromProject(permission) {
        emit ProtectedMethodCalled();
    }
}
