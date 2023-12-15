// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {OwnableHandler} from "./handlers/OwnableHandler.sol";

import {MockOwnable} from "./mocks/MockOwnable.sol";
import {JBOwnableOverrides} from "src/JBOwnableOverrides.sol";
import {JBPermissions} from "lib/juice-contracts-v4/src/JBPermissions.sol";
import {IJBPermissions} from "lib/juice-contracts-v4/src/interfaces/IJBPermissions.sol";
import {JBPermissionsData} from "lib/juice-contracts-v4/src/structs/JBPermissionsData.sol";
import {JBProjects} from "lib/juice-contracts-v4/src/JBProjects.sol";
import {IJBProjects} from "lib/juice-contracts-v4/src/interfaces/IJBProjects.sol";

contract OwnableInvariantTests is Test {
    OwnableHandler handler;

    function setUp() public {
        handler = new OwnableHandler();
        targetContract(address(handler));
    }

    function invariant_cantBelongToUserAndProject() public {
        (, uint88 projectId,) = handler.OWNABLE().jbOwner();
        assertTrue(
            ///owner == address(0) ||
            projectId == uint256(0)
        );
    }
}
