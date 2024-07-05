// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Pal721} from "../src/Pal721.sol";
import {PalInventory} from "../src/PalInventory.sol";

import {ERC6551Registry} from "@6551/ERC6551Registry.sol";
import {ERC6551AccountUpgradeable} from "@6551/examples/upgradeable/ERC6551AccountUpgradeable.sol";
import {ERC6551AccountProxy} from "@6551/examples/upgradeable/ERC6551AccountProxy.sol";

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";


contract PalTest is Test {

    ERC6551Registry public registry;
    ERC6551AccountUpgradeable public implementation;
    ERC6551AccountProxy public proxy;
    Pal721 pal;

    function setUp() public {

        registry = new ERC6551Registry();
        implementation = new ERC6551AccountUpgradeable();
        proxy = new ERC6551AccountProxy(address(implementation));

        ProxyAdmin proxyAdmin = new ProxyAdmin();
        pal = deployPalNFT(proxyAdmin);

    }

    function deployPalNFT(ProxyAdmin proxyAdmin) public returns (Pal721) {
        vm.startBroadcast();

        palImplementation = new Pal721();

        palProxy = Pal721(
            address(new TransparentUpgradeableProxy(
                address(palImplementation),
                address(proxyAdmin),
                abi.encodeWithSelector(
                    palImplementation.initialize.selector,
                    "Pal",
                    "PAL"
                )
            ))
        );

        vm.stopBroadcast();
        return palProxy;
    }

}
