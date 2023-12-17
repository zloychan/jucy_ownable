// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {JBOwnable, JBOwnableOverrides} from "../../src/JBOwnable.sol";
import {IJBProjects} from "lib/juice-contracts-v4/src/interfaces/IJBProjects.sol";
import {IJBPermissions} from "lib/juice-contracts-v4/src/interfaces/IJBPermissions.sol";

contract MockOwnable is JBOwnable {
    event ProtectedMethodCalled();

    uint256 permissionId;

    function setPermission(uint256 newPermissionId) external {
        permissionId = newPermissionId;
    }

    constructor(IJBProjects projects, IJBPermissions permissions) JBOwnable(projects, permissions) {}

    function protectedMethod() external onlyOwner {
        emit ProtectedMethodCalled();
    }

    function protectedMethodWithRequirePermission() external {
        uint256 projectId = jbOwner.projectId;

        _requirePermissionFrom({
            account: PROJECTS.ownerOf(projectId),
            projectId: projectId,
            permissionId: permissionId
        });

        emit ProtectedMethodCalled();
    }
}
