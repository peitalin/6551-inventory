// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Pal721} from "../src/Pal721.sol";
import {PalInventory} from "../src/PalInventory.sol";

import {ERC6551Registry} from "@6551/ERC6551Registry.sol";
import {ERC6551AccountUpgradeable} from "@6551/examples/upgradeable/ERC6551AccountUpgradeable.sol";
import {ERC6551AccountProxy} from "../src/ERC6551AccountProxy.sol";

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";


contract PalTest is Test {

    ERC6551Registry public registry;
    ERC6551AccountUpgradeable public implementation;
    ERC6551AccountProxy public accountProxy;
    Pal721 pal;

    function setUp() public {

        registry = new ERC6551Registry();
        implementation = new ERC6551AccountUpgradeable();
        accountProxy = new ERC6551AccountProxy(address(implementation));

        ProxyAdmin proxyAdmin = new ProxyAdmin(msg.sender);
        pal = deployPalNFT(proxyAdmin, "Pal", "PAL");

    }

    function test_DeployPal() public {
        vm.startBroadcast();
        pal.mint(msg.sender);
        uint256 balance = pal.balanceOf(msg.sender);
        console.log("Pal balancer: ", balance);
        vm.stopBroadcast();
    }

    function testDeploy() public {

        address owner = vm.addr(1);
        bytes32 salt = bytes32(uint256(200));

        vm.startBroadcast();
        uint256 tokenId = pal.mint(owner);
        vm.stopBroadcast();

        address predictedAccount =
            registry.account(address(accountProxy), salt, block.chainid, address(pal), tokenId);

        vm.prank(owner, owner);

        address deployedAccount =
            registry.createAccount(address(accountProxy), salt, block.chainid, address(pal), tokenId);

        assertTrue(deployedAccount != address(0));

        assertEq(predictedAccount, deployedAccount);

        // Create account is idempotent
        deployedAccount =
            registry.createAccount(address(accountProxy), salt, block.chainid, address(pal), tokenId);
        assertEq(predictedAccount, deployedAccount);
    }

    function deployPalNFT(ProxyAdmin proxyAdmin, string memory name, string memory symbol) public returns (Pal721) {
        vm.startBroadcast();

        Pal721 palImplementation = new Pal721();

        Pal721 palProxy = Pal721(
            address(new TransparentUpgradeableProxy(
                address(palImplementation),
                address(proxyAdmin),
                abi.encodeWithSelector(
                    palImplementation.initialize.selector,
                    name,
                    symbol
                )
            ))
        );

        vm.stopBroadcast();
        return palProxy;
    }

}
