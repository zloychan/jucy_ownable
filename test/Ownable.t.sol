// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {MockOwnable} from "./mocks/MockOwnable.sol";
import {JBOwnableOverrides} from "src/JBOwnableOverrides.sol";

import {JBPermissions} from "lib/juice-contracts-v4/src/JBPermissions.sol";
import {JBProjects} from "lib/juice-contracts-v4/src/JBProjects.sol";
import {IJBPermissions} from "lib/juice-contracts-v4/src/interfaces/IJBPermissions.sol";
import {JBPermissionsData} from "lib/juice-contracts-v4/src/structs/JBPermissionsData.sol";
import {IJBProjects} from "lib/juice-contracts-v4/src/interfaces/IJBProjects.sol";

contract OwnableTest is Test {
    IJBProjects PROJECTS;
    IJBPermissions PERMISSIONS;

    modifier isNotContract(address a) {
        uint256 size;
        assembly {
            size := extcodesize(a)
        }
        vm.assume(size == 0);
        _;
    }

    function setUp() public {
        // Deploy the permissions contract.
        PERMISSIONS = new JBPermissions();
        // Deploy the projects contract.
        PROJECTS = new JBProjects(address(123));
    }

    function testDeployerBecomesOwner(
        address projectOwner,
        address owner
    )
        public
        isNotContract(projectOwner)
        isNotContract(owner)
    {
        // `CreateFor` won't work if the address is a contract that doesn't support `ERC721Receiver`.
        vm.assume(projectOwner != address(0));

        vm.prank(owner);
        MockOwnable ownable = new MockOwnable(PROJECTS, PERMISSIONS);

        assertEq(owner, ownable.owner(), "Deployer did not become the owner.");
    }

    function testJBOwnableFollowsTheProjectOwner(
        address projectOwner,
        address newProjectOwner
    )
        public
        isNotContract(projectOwner)
        isNotContract(newProjectOwner)
    {
        // `CreateFor` won't work if the address is a contract that doesn't support `ERC721Receiver`.
        vm.assume(projectOwner != address(0));
        // Can't transfer ownership to the zero address.
        vm.assume(newProjectOwner != address(0));

        // Create a project for the owner.
        uint256 projectId = PROJECTS.createFor(projectOwner);

        // Create the `Ownable` contract.
        MockOwnable ownable = new MockOwnable(PROJECTS, PERMISSIONS);

        // Transfer ownership to the project's owner.
        ownable.transferOwnershipToProject(projectId);

        // Make sure the deployer owns it.
        assertEq(projectOwner, ownable.owner(), "Deployer is not the owner.");

        // Transfer the project's ownership.
        vm.prank(projectOwner);
        PROJECTS.transferFrom(projectOwner, newProjectOwner, projectId);

        // Make sure the `Ownable` contract has also been transferred to the new project owner.
        assertEq(newProjectOwner, ownable.owner(), "Ownable did not follow the Project owner.");
    }

    function testBasicOwnable(
        address projectOwner,
        address newOwnableOwner
    )
        public
        isNotContract(projectOwner)
        isNotContract(newOwnableOwner)
    {
        // Ownership can't be transferred to the 0 address. To transfer to the 0 address, ownership must be renounced.
        vm.assume(newOwnableOwner != address(0));
        // `CreateFor` won't work if the address is a contract that doesn't support `ERC721Receiver`.
        vm.assume(projectOwner != address(0));

        // Create a project for the owner.
        uint256 _projectId = PROJECTS.createFor(projectOwner);

        // Create the `Ownable` contract.
        MockOwnable ownable = new MockOwnable(PROJECTS, PERMISSIONS);

        // Transfer ownership to the project owner.
        ownable.transferOwnershipToProject(_projectId);
        // Make sure the project owner owns it.
        assertEq(projectOwner, ownable.owner(), "Deployer is not the owner.");

        // We now stop using it as a `JBOwnable` and start using it like a basic `Ownable`.
        vm.prank(projectOwner);
        ownable.transferOwnership(newOwnableOwner);
        // Make sure it was transferred to the new owner.
        assertEq(newOwnableOwner, ownable.owner());
        // Sanity check to make sure it only the `Ownable` changed, and that the project did not.
        assertEq(PROJECTS.ownerOf(_projectId), projectOwner);
    }

    function testCantTransferToProjectZero(address deployer) public {
        vm.startPrank(deployer);

        // Create the `Ownable` contract.
        MockOwnable ownable = new MockOwnable(PROJECTS, PERMISSIONS);

        vm.expectRevert(
            abi.encodeWithSelector(
                JBOwnableOverrides.INVALID_NEW_OWNER.selector,
                address(0), // Owner address.
                uint256(0) // Project ID.
            )
        );

        // Transfer ownership to project ID 0 (should revert).
        ownable.transferOwnershipToProject(0);
        vm.stopPrank();
    }

    function testCantTransferToAddressZero(address deployer) public {
        vm.startPrank(deployer);

        // Create the `Ownable` contract.
        MockOwnable ownable = new MockOwnable(PROJECTS, PERMISSIONS);

        vm.expectRevert(
            abi.encodeWithSelector(
                JBOwnableOverrides.INVALID_NEW_OWNER.selector,
                address(0), // Owner address.
                uint256(0) // Project ID.
            )
        );

        // Transfer ownership to the 0 address (should revert).
        ownable.transferOwnership(address(0));
        vm.stopPrank();
    }

    function testOwnableDoesNotFollowProject(
        address deployer,
        address projectOwner,
        address newProjectOwner
    )
        public
        isNotContract(deployer)
        isNotContract(projectOwner)
        isNotContract(newProjectOwner)
    {
        vm.assume(deployer != projectOwner && deployer != newProjectOwner);
        // `CreateFor` won't work if the address is a contract that doesn't support `ERC721Receiver`.
        vm.assume(projectOwner != address(0));
        vm.assume(newProjectOwner != address(0));

        // Create a project for the owner.
        uint256 _projectId = PROJECTS.createFor(projectOwner);

        // Create the `Ownable` contract.
        vm.prank(deployer);
        MockOwnable ownable = new MockOwnable(PROJECTS, PERMISSIONS);

        // Make sure the deployer owns it.
        assertEq(deployer, ownable.owner(), "Deployer is not the owner.");

        // Transfer ownership to the project owner.
        vm.prank(deployer);
        ownable.transferOwnershipToProject(_projectId);

        // Make sure the deployer owns it.
        assertEq(PROJECTS.ownerOf(_projectId), ownable.owner(), "Project owner is not the owner.");

        // Transfer the project ownership.
        vm.prank(projectOwner);
        PROJECTS.transferFrom(projectOwner, newProjectOwner, _projectId);
        assertEq(PROJECTS.ownerOf(_projectId), newProjectOwner);

        // Make sure the `Ownable` contract has also been transferred to the new project owner.
        assertEq(newProjectOwner, ownable.owner(), "Ownable followed the projectOwner but it's overriden.");
    }

    function testOwnableOwnerCanRennounce(address owner) public {
        vm.assume(owner != address(0));

        // Create the `Ownable` contract.
        MockOwnable ownable = new MockOwnable(PROJECTS, PERMISSIONS);

        // Transfer ownership to the project owner.
        ownable.transferOwnership(owner);
        assertEq(owner, ownable.owner(), "Deployer is not the owner.");

        // Renounce the ownership.
        vm.prank(owner);
        ownable.renounceOwnership();
        assertEq(address(0), ownable.owner(), "Owner was not renounced.");
    }

    function testJBOwnableOwnerCanRennounce(address projectOwner) public isNotContract(projectOwner) {
        // `CreateFor` won't work if the address is a contract that doesn't support `ERC721Receiver`.
        vm.assume(projectOwner != address(0));

        // Create a project for the owner.
        uint256 _projectId = PROJECTS.createFor(projectOwner);

        // Create the `Ownable` contract.
        MockOwnable ownable = new MockOwnable(PROJECTS, PERMISSIONS);

        // Transfer ownership to the project owner.
        ownable.transferOwnershipToProject(_projectId);
        assertEq(projectOwner, ownable.owner(), "Deployer is not the owner.");

        // Renounce the ownership.
        vm.prank(projectOwner);
        ownable.renounceOwnership();
        assertEq(address(0), ownable.owner(), "Owner was not renounced.");
    }

    function testJBOwnablePermissions(
        address projectOwner,
        address callerAddress,
        uint8 requiredPermissionId,
        uint8[] memory permissionIdsToGrant
    )
        public
        isNotContract(projectOwner)
    {
        // `CreateFor` won't work if the address is a contract that doesn't support `ERC721Receiver`.
        vm.assume(projectOwner != address(0) && callerAddress != projectOwner);

        vm.assume(permissionIdsToGrant.length < 5);

        // Create a project for the owner.
        uint256 _projectId = PROJECTS.createFor(projectOwner);

        // Create the `Ownable` contract.
        MockOwnable ownable = new MockOwnable(PROJECTS, PERMISSIONS);

        // Transfer ownership to the project owner.
        ownable.transferOwnershipToProject(_projectId);
        assertEq(projectOwner, ownable.owner(), "Project owner is not the owner.");

        // Set the required permission.
        vm.prank(projectOwner);
        ownable.setPermissionId(requiredPermissionId);

        // Attempt to call the protected method without permission.
        vm.expectRevert(abi.encodeWithSelector(JBOwnableOverrides.UNAUTHORIZED.selector));
        vm.prank(callerAddress);
        ownable.protectedMethod();

        // Give permission.
        bool _shouldHavePermission;
        uint256[] memory _permissionIds = new uint256[](permissionIdsToGrant.length);
        for (uint256 i; i < permissionIdsToGrant.length; i++) {
            // Check if the permission we need is in the permissions to grant.
            if (permissionIdsToGrant[i] == requiredPermissionId) _shouldHavePermission = true;
            _permissionIds[i] = permissionIdsToGrant[i];
        }

        // The owner gives permission to the caller.
        vm.prank(projectOwner);
        PERMISSIONS.setPermissionsFor(
            projectOwner,
            JBPermissionsData({operator: callerAddress, projectId: _projectId, permissionIds: _permissionIds})
        );

        if (!_shouldHavePermission) {
            vm.expectRevert(abi.encodeWithSelector(JBOwnableOverrides.UNAUTHORIZED.selector));
        }

        vm.prank(callerAddress);
        ownable.protectedMethod();
    }

    function testJBOwnablePermissionsRequiredModifier(
        address projectOwner,
        address callerAddress,
        uint8 requiredPermissionId,
        uint8[] memory permissionIdsToGrant
    )
        public
        isNotContract(projectOwner)
    {
        // `CreateFor` won't work if the address is a contract that doesn't support `ERC721Receiver`.
        vm.assume(projectOwner != address(0) && callerAddress != projectOwner);

        vm.assume(permissionIdsToGrant.length < 5);

        // Create a project for the owner.
        uint256 _projectId = PROJECTS.createFor(projectOwner);

        // Create the `Ownable` contract.
        MockOwnable ownable = new MockOwnable(PROJECTS, PERMISSIONS);

        // Transfer ownership to the project owner.
        ownable.transferOwnershipToProject(_projectId);
        assertEq(projectOwner, ownable.owner(), "Project owner is not the owner.");

        // Set the permission that is required.
        ownable.setPermission(requiredPermissionId);

        // Attempt to call the protected method without permission.
        vm.expectRevert(abi.encodeWithSelector(JBOwnableOverrides.UNAUTHORIZED.selector));
        vm.prank(callerAddress);
        ownable.protectedMethodWithRequirePermission();

        // Give permission.
        bool _shouldHavePermission;
        uint256[] memory _permissionIds = new uint256[](permissionIdsToGrant.length);
        for (uint256 i; i < permissionIdsToGrant.length; i++) {
            // Check if the permission we need is in the permissions to grant.
            if (permissionIdsToGrant[i] == requiredPermissionId) _shouldHavePermission = true;
            _permissionIds[i] = permissionIdsToGrant[i];
        }

        // The owner gives permission to the caller.
        vm.prank(projectOwner);
        PERMISSIONS.setPermissionsFor(
            projectOwner,
            JBPermissionsData({operator: callerAddress, projectId: _projectId, permissionIds: _permissionIds})
        );

        if (!_shouldHavePermission) {
            vm.expectRevert(abi.encodeWithSelector(JBOwnableOverrides.UNAUTHORIZED.selector));
        }

        vm.prank(callerAddress);
        ownable.protectedMethodWithRequirePermission();
    }
}
