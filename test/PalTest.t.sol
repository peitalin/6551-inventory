// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";

import {Pal721} from "../src/Pal721.sol";
import {PalInventory} from "../src/PalInventory.sol";
import {IEquipRules} from "../src/EquipRules/IEquipRules.sol";
import {PotionEquipRules} from "../src/EquipRules/PotionEquipRules.sol";

import {Potion721} from "../src/Potion721.sol";

import {ERC6551Registry} from "@6551/ERC6551Registry.sol";
import {ERC6551AccountUpgradeable} from "@6551/examples/upgradeable/ERC6551AccountUpgradeable.sol";

import {IERC6551Account} from "@6551/interfaces/IERC6551Account.sol";
import {IERC6551Executable} from "@6551/interfaces/IERC6551Executable.sol";
import {IPalInventory} from "../src/IPalInventory.sol";

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";


contract PalTest is Test {

    ERC6551Registry public registry;
    PalInventory public palInventoryProxy; // ERC6551Accountupgradeable
    PalInventory public palInventoryImpl; // ERC6551Accountupgradeable
    ProxyAdmin proxyAdmin;

    Pal721 public pal;
    PalInventory public inventory; // instance of palInventory
    Potion721 public potion;
    PotionEquipRules public potionEquipRules;


    function setUp() public {

        proxyAdmin = new ProxyAdmin(msg.sender);

        potion = deployPotionsNFT("Potion", "POT");

        potionEquipRules = new PotionEquipRules(3);

        PalInventory.EquipConfig[] memory equipConfigs = new PalInventory.EquipConfig[](1);

        PalInventory.EquipConfig memory potionEquipConfig = PalInventory.EquipConfig({
            nft: address(potion),
            tokenId: 0,
            supportedInterface: PalInventory.Interfaces.ERC721,
            equipRules: IEquipRules(potionEquipRules)
        });

        equipConfigs[0] = potionEquipConfig;

        registry = new ERC6551Registry();
        pal = deployPalNFT("Pal", "PAL");
        address owner = vm.addr(1);
        uint256 tokenId = mintPal(owner);
        (palInventoryProxy, inventory) = deployPalInventory(tokenId, equipConfigs);

    }

    function mintPal(address user) public returns (uint256) {
        vm.startBroadcast();
        uint256 tokenId = pal.mint(user);
        vm.stopBroadcast();
        return tokenId;
    }

    function mintPotion(address user) public returns (uint256) {
        vm.startBroadcast();
        uint256 tokenId = potion.mint(user);
        vm.stopBroadcast();
        return tokenId;
    }

    function deployPalNFT(
        string memory name,
        string memory symbol
    ) public returns (Pal721) {
        vm.startBroadcast();
        Pal721 impl = new Pal721();
        Pal721 proxy = Pal721(
            address(new TransparentUpgradeableProxy(
                address(impl),
                address(proxyAdmin),
                abi.encodeWithSelector(
                    impl.initialize.selector,
                    name,
                    symbol
                )
            ))
        );
        vm.stopBroadcast();
        return proxy;
    }

    function deployPotionsNFT(
        string memory name,
        string memory symbol
    ) public returns (Potion721) {
        vm.startBroadcast();
        Potion721 impl = new Potion721();
        Potion721 proxy = Potion721(
            address(new TransparentUpgradeableProxy(
                address(impl),
                address(proxyAdmin),
                abi.encodeWithSelector(
                    impl.initialize.selector,
                    name,
                    symbol
                )
            ))
        );
        vm.stopBroadcast();
        return proxy;
    }

    function deployPalInventory(
        uint256 tokenId, // PalTokenId
        PalInventory.EquipConfig[] memory _equipConfigs
    ) public returns (PalInventory, PalInventory) {
        vm.startBroadcast();

        palInventoryImpl = new PalInventory();

        // PalInventory palInventoryProxy = PalInventory(
        //     payable(address(
        //         new TransparentUpgradeableProxy(
        //             address(palInventoryImpl),
        //             address(proxyAdmin),
        //             abi.encodeWithSelector(
        //                 palInventoryImpl.initialize.selector,
        //                 _equipConfigs
        //             )
        //         )
        //     ))
        // );

        bytes32 salt = bytes32(uint256(200));
        PalInventory inventory = PalInventory(payable(
            registry.createAccount(
                address(palInventoryImpl), salt, block.chainid, address(pal), tokenId
            )
        ));
        // initialized the proxy
        inventory.initialize(_equipConfigs);

        vm.deal(address(inventory), 1 ether);

        vm.stopBroadcast();
        return (palInventoryProxy, inventory);
    }

    ///////////////////////////////////////////////////
    /// Tests
    ///////////////////////////////////////////////////

    // function test_DeployPal() public {
    //     vm.startBroadcast();
    //     pal.mint(msg.sender);
    //     uint256 balance = pal.balanceOf(msg.sender);
    //     vm.stopBroadcast();
    // }

    // function testDeploy() public {

    //     address owner = vm.addr(1);
    //     bytes32 salt = bytes32(uint256(200));

    //     uint256 tokenId = mintPal(owner);

    //     address predictedAccount =
    //         registry.account(address(palInventory), salt, block.chainid, address(pal), tokenId);

    //     vm.prank(owner, owner);

    //     address deployedAccount =
    //         registry.createAccount(address(palInventory), salt, block.chainid, address(pal), tokenId);

    //     assertTrue(deployedAccount != address(0));

    //     assertEq(predictedAccount, deployedAccount);

    //     // Create account is idempotent
    //     deployedAccount =
    //         registry.createAccount(address(palInventory), salt, block.chainid, address(pal), tokenId);
    //     assertEq(predictedAccount, deployedAccount);
    // }

    // function test_TokenAndOwnership() public {
    //     address owner = vm.addr(1);
    //     bytes32 salt = bytes32(uint256(200));

    //     uint256 tokenId = mintPal(owner);

    //     vm.prank(owner, owner);
    //     address account =
    //         registry.createAccount(address(palInventoryImpl), salt, block.chainid, address(pal), tokenId);

    //     IERC6551Account accountInstance = IERC6551Account(payable(account));

    //     ////// Check token and owner functions
    //     (uint256 chainId_, address tokenAddress_, uint256 tokenId_) = accountInstance.token();
    //     assertEq(chainId_, block.chainid);
    //     assertEq(tokenAddress_, address(pal));
    //     assertEq(tokenId_, tokenId);
    //     assertEq(accountInstance.isValidSigner(owner, ""), IERC6551Account.isValidSigner.selector);

    //     // Transfer token to new owner and make sure account owner changes
    //     address newOwner = vm.addr(2);
    //     vm.prank(owner);
    //     pal.safeTransferFrom(owner, newOwner, tokenId);
    //     assertEq(
    //         accountInstance.isValidSigner(newOwner, ""), IERC6551Account.isValidSigner.selector
    //     );
    // }

    // // write a test to send an NFT via execute() from the inventory
    // // then add a hook to the execute() function
    // function test_RestrictExecution() public {

    //     address owner = vm.addr(1);
    //     bytes32 salt = bytes32(uint256(200));
    //     uint256 tokenId = mintPal(owner);

    //     vm.startBroadcast(owner);
    //     IPalInventory inventory = IPalInventory(payable(
    //         registry.createAccount(
    //             address(palInventoryImpl), salt, block.chainid, address(pal), tokenId
    //         )
    //     ));

    //     vm.deal(address(inventory), 1 ether);


    //     vm.expectRevert(PalInventory.RestrictMint.selector);
    //     inventory.execute(
    //         address(potion),
    //         0 ether,
    //         abi.encodeWithSelector(potion.mint.selector, address(owner)),
    //         0
    //     );

    //     // inventory.equip(address(potion), tokenId);
    //     // assertEq(potion.balanceOf(address(owner)), 1);
    //     // assertEq(address(inventory).balance, 0.5 ether);
    //     // assertEq(vm.addr(2).balance, 0.5 ether);
    // }

    function test_EquipPotionsTooManyTimes() public {

        address owner = vm.addr(1);
        // address owner = address(pal);
        console.log("owner is a Pal:", owner);

        vm.startPrank(owner);
        potion.mint(owner);
        potion.mint(owner);
        potion.approve(address(inventory), 0); // tokenId = 0

        // IEquipRules pRules = palInventoryProxy.getEquipRules(address(potion), 0);
        // console.log("proxyrules:", address(pRules));


        IEquipRules eRules = inventory.getEquipRules(address(potion), 0);
        console.log("erules:", address(eRules));

        inventory.equip(address(potion), 0, 1);
        // inventory.equip(address(potion), 1, 1);
        // inventory.equip(address(potion), 2, 1);
        vm.stopPrank();

    }


    // function testPermissionControl() public {
    //     address owner = vm.addr(1);
    //     bytes32 salt = bytes32(uint256(200));

    //     uint256 tokenId = mintPal(owner);

    //     vm.prank(owner, owner);
    //     address account = registry.createAccount(
    //         address(palInventoryImpl), salt, block.chainid, address(pal), tokenId
    //     );

    //     vm.deal(account, 1 ether);

    //     IERC6551Account accountInstance = IERC6551Account(payable(account));
    //     IERC6551Executable executableAccountInstance = IERC6551Executable(account);

    //     vm.prank(vm.addr(3));
    //     vm.expectRevert("Caller is not owner");
    //     executableAccountInstance.execute(payable(vm.addr(2)), 0.5 ether, "", 0);

    //     vm.prank(owner);
    //     executableAccountInstance.execute(payable(vm.addr(2)), 0.5 ether, "", 0);

    //     assertEq(account.balance, 0.5 ether);
    //     assertEq(vm.addr(2).balance, 0.5 ether);
    //     assertEq(accountInstance.state(), 1);
    // }

    // function test_MustUseEquip() public {
    //     address owner = vm.addr(1);
    //     bytes32 salt = bytes32(uint256(200));

    //     uint256 tokenId = mintPal(owner);
    //     uint256 tokenIdPotion = mintPotion(owner);

    //     vm.prank(owner);
    //     address account = registry.createAccount(
    //         address(palInventoryImpl), salt, block.chainid, address(pal), tokenId
    //     );

    //     vm.prank(owner);
    //     // expect a direct mint() to inventory to revert with MustUseEquipFunction
    //     vm.expectRevert(PalInventory.MustUseEquipFunction.selector);
    //     potion.safeTransferFrom(owner, account, tokenIdPotion);
    // }

    // function test_CannotOwnSelf() public {
    //     address owner = vm.addr(1);
    //     bytes32 salt = bytes32(uint256(200));

    //     uint256 tokenId = mintPal(owner);

    //     vm.prank(owner, owner);
    //     address account = registry.createAccount(
    //         address(palInventoryImpl), salt, block.chainid, address(pal), tokenId
    //     );

    //     vm.prank(owner);
    //     vm.expectRevert("Cannot own yourself");
    //     pal.safeTransferFrom(owner, account, tokenId);
    // }
}
