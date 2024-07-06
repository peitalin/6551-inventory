// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";

import {Pal721} from "../src/Pal721.sol";
import {PalInventory} from "../src/PalInventory.sol";

import {ERC6551Registry} from "@6551/ERC6551Registry.sol";
// import {ERC6551AccountUpgradeable} from "@6551/examples/upgradeable/ERC6551AccountUpgradeable.sol";
// import {ERC6551AccountProxy} from "../src/ERC6551AccountProxy.sol";

import {IERC6551Account} from "@6551/interfaces/IERC6551Account.sol";
import {IERC6551Executable} from "@6551/interfaces/IERC6551Executable.sol";

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";


contract PalTest is Test {

    ERC6551Registry public registry;
    PalInventory public palInventory; // ERC6551Accountupgradeable
    PalInventory public palInventoryImpl; // ERC6551Accountupgradeable
    Pal721 pal;

    function setUp() public {

        ProxyAdmin proxyAdmin = new ProxyAdmin(msg.sender);

        registry = new ERC6551Registry();
        pal = deployPalNFT(proxyAdmin, "Pal", "PAL");
        PalInventory palInventory = deployPalInventory(proxyAdmin);

    }

    function mintPal(address user) public returns (uint256) {
        vm.startBroadcast();
        uint256 tokenId = pal.mint(user);
        vm.stopBroadcast();
        return tokenId;
    }

    function deployPalNFT(
        ProxyAdmin proxyAdmin,
        string memory name,
        string memory symbol
    ) public returns (Pal721) {
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

    function deployPalInventory(ProxyAdmin proxyAdmin) public returns (PalInventory) {
        vm.startBroadcast();
        palInventoryImpl = new PalInventory();
        PalInventory palInventoryProxy = PalInventory(
            payable(address(
                new TransparentUpgradeableProxy(
                    address(palInventoryImpl),
                    address(proxyAdmin),
                    abi.encodeWithSelector(
                        palInventoryImpl.initialize.selector
                    )
                )
            ))
        );
        vm.stopBroadcast();
        return palInventoryProxy;
    }

    ///////////////////////////////////////////////////
    /// Tests
    ///////////////////////////////////////////////////

    function test_DeployPal() public {
        vm.startBroadcast();
        pal.mint(msg.sender);
        uint256 balance = pal.balanceOf(msg.sender);
        vm.stopBroadcast();
    }

    function testDeploy() public {

        address owner = vm.addr(1);
        bytes32 salt = bytes32(uint256(200));

        uint256 tokenId = mintPal(owner);

        address predictedAccount =
            registry.account(address(palInventory), salt, block.chainid, address(pal), tokenId);

        vm.prank(owner, owner);

        address deployedAccount =
            registry.createAccount(address(palInventory), salt, block.chainid, address(pal), tokenId);

        assertTrue(deployedAccount != address(0));

        assertEq(predictedAccount, deployedAccount);

        // Create account is idempotent
        deployedAccount =
            registry.createAccount(address(palInventory), salt, block.chainid, address(pal), tokenId);
        assertEq(predictedAccount, deployedAccount);
    }

    function test_TokenAndOwnership() public {
        address owner = vm.addr(1);
        bytes32 salt = bytes32(uint256(200));

        uint256 tokenId = mintPal(owner);

        vm.prank(owner, owner);
        address account =
            registry.createAccount(address(palInventoryImpl), salt, block.chainid, address(pal), tokenId);

        IERC6551Account accountInstance = IERC6551Account(payable(account));

        ////// Check token and owner functions
        (uint256 chainId_, address tokenAddress_, uint256 tokenId_) = accountInstance.token();
        assertEq(chainId_, block.chainid);
        assertEq(tokenAddress_, address(pal));
        assertEq(tokenId_, tokenId);
        assertEq(accountInstance.isValidSigner(owner, ""), IERC6551Account.isValidSigner.selector);

        // Transfer token to new owner and make sure account owner changes
        address newOwner = vm.addr(2);
        vm.prank(owner);
        pal.safeTransferFrom(owner, newOwner, tokenId);
        assertEq(
            accountInstance.isValidSigner(newOwner, ""), IERC6551Account.isValidSigner.selector
        );
    }

    function testPermissionControl() public {
        address owner = vm.addr(1);
        bytes32 salt = bytes32(uint256(200));

        uint256 tokenId = mintPal(owner);

        vm.prank(owner, owner);
        address account = registry.createAccount(
            address(palInventoryImpl), salt, block.chainid, address(pal), tokenId
        );

        vm.deal(account, 1 ether);

        IERC6551Account accountInstance = IERC6551Account(payable(account));
        IERC6551Executable executableAccountInstance = IERC6551Executable(account);

        vm.prank(vm.addr(3));
        vm.expectRevert("Caller is not owner");
        executableAccountInstance.execute(payable(vm.addr(2)), 0.5 ether, "", 0);

        vm.prank(owner);
        executableAccountInstance.execute(payable(vm.addr(2)), 0.5 ether, "", 0);

        assertEq(account.balance, 0.5 ether);
        assertEq(vm.addr(2).balance, 0.5 ether);
        assertEq(accountInstance.state(), 1);
    }

    function testCannotOwnSelf() public {
        address owner = vm.addr(1);
        bytes32 salt = bytes32(uint256(200));

        uint256 tokenId = mintPal(owner);

        vm.prank(owner, owner);
        address account = registry.createAccount(
            address(palInventoryImpl), salt, block.chainid, address(pal), tokenId
        );

        vm.prank(owner);
        vm.expectRevert("Cannot own yourself");
        pal.safeTransferFrom(owner, account, tokenId);
    }
}
