// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IJBOwnable {
    event PermissionIdChanged(uint8 newIndex);

    function jbOwner() external view returns (address owner, uint88 projectOwner, uint8 permissionId);

    function transferOwnershipToProject(uint256 projectId) external;

    function setPermissionId(uint8 permissionId) external;
}
