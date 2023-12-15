// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/**
 * @notice Owner information for a given instance of `JBOwnableOverrides`.
 * @custom:member owner If `projectId` is 0 and this is set, this static address has owner access.
 * @custom:member projectId Unless this is 0, this project's owner has owner access.
 * @custom:member permissionId The ID of the permission required from the project's owner to have owner access. See
 * `JBPermissions` in `juice-contracts-v4`.
 */
struct JBOwner {
    address owner;
    uint88 projectId;
    uint8 permissionId;
}
