// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

// import { Test } from "forge-std/Test.sol";
import {CommonBase} from "forge-std/Base.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {console} from "forge-std/console.sol";

import {MockOwnable, JBOwnableOverrides} from "../mocks/MockOwnable.sol";
import {IJBPermissions} from "@bananapus/core/src/interfaces/IJBPermissions.sol";
import {JBPermissions} from "@bananapus/core/src/JBPermissions.sol";
import {JBPermissionsData} from "@bananapus/core/src/structs/JBPermissionsData.sol";
import {IJBProjects} from "@bananapus/core/src/interfaces/IJBProjects.sol";
import {JBProjects} from "@bananapus/core/src/JBProjects.sol";

contract OwnableHandler is CommonBase, StdCheats, StdUtils {
    IJBProjects public immutable PROJECTS;
    IJBPermissions public immutable PERMISSIONS;
    MockOwnable public immutable OWNABLE;

    address[] public actors;
    address internal currentActor;

    modifier useActor(uint256 actorIndexSeed) {
        currentActor = actors[bound(actorIndexSeed, 0, actors.length - 1)];
        vm.startPrank(currentActor);
        _;
        vm.stopPrank();
    }

    constructor() {
        address deployer = vm.addr(1);
        address initialOwner = vm.addr(2);
        // Deploy the permissions contract.j
        PERMISSIONS = new JBPermissions();
        // Deploy the `JBProjects` contract.
        PROJECTS = new JBProjects(address(123));
        // Deploy the `JBOwnable` contract.
        vm.prank(deployer);
        OWNABLE = new MockOwnable(PROJECTS, PERMISSIONS, initialOwner, uint88(0));

        actors.push(deployer);
        actors.push(initialOwner);
        actors.push(address(420));
    }

    function transferOwnershipToAddress(uint256 actorIndexSeed, address _newOwner) public useActor(actorIndexSeed) {
        OWNABLE.transferOwnership(_newOwner);
    }
}
