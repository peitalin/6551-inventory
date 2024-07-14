// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import {ERC6551Registry} from "@6551/ERC6551Registry.sol";
import {ERC6551AccountUpgradeable} from "@6551/examples/upgradeable/ERC6551AccountUpgradeable.sol";
import {IERC6551Account} from "@6551/interfaces/IERC6551Account.sol";
import {IERC6551Executable} from "@6551/interfaces/IERC6551Executable.sol";

import {IBaseEquipRules} from "../src/EquipRules/IBaseEquipRules.sol";
import {PotionEquipRules} from "../src/EquipRules/PotionEquipRules.sol";
import {ResourcesEquipRules} from "../src/EquipRules/ResourcesEquipRules.sol";

import {Potion721} from "../src/items/Potion721.sol";
import {Resources1155} from "../src/items/Resources1155.sol";
import {IPalInventory} from "../src/interfaces/IPalInventory.sol";
import {ERC6551Inventory, Interfaces, EquipConfig} from "../src/ERC6551Inventory.sol";
import {Pal721} from "../src/Pal721.sol";
import {PalInventory, DEFAULT_ID} from "../src/PalInventory.sol";



contract PalTest is Test {

    ERC6551Registry public registry;
    PalInventory public palInventoryProxy; // ERC6551Accountupgradeable
    PalInventory public palInventoryImpl; // ERC6551Accountupgradeable
    ProxyAdmin proxyAdmin;

    Pal721 public pal;
    PalInventory public inventory; // instance of palInventory
    Potion721 public potion;
    Resources1155 public resources;
    PotionEquipRules public potionEquipRules;
    ResourcesEquipRules public resourcesEquipRules;

    address public owner;

    function setUp() public {

        proxyAdmin = new ProxyAdmin(msg.sender);

        potion = deployPotionsNFT("Potion", "POT");
        resources = deployResourcesNFT();

        potionEquipRules = new PotionEquipRules(3);
        resourcesEquipRules = new ResourcesEquipRules();

        uint256 numberOfRules = 2;

        EquipConfig[] memory equipConfigs = new EquipConfig[](numberOfRules);

        // Potion Equip Rules
        EquipConfig memory potionEquipConfig = EquipConfig({
            nft: address(potion),
            tokenId: DEFAULT_ID,
            supportedInterface: Interfaces.ERC721,
            equipRules: IBaseEquipRules(potionEquipRules)
        });
        equipConfigs[0] = potionEquipConfig;
        uint256 maxWeight = 15;

        // Resources Equip Rules
        uint256 resourceTokenId = 0; // say wood
        EquipConfig memory resourcesEquipConfig = EquipConfig({
            nft: address(resources),
            tokenId: resourceTokenId,
            supportedInterface: Interfaces.ERC1155,
            equipRules: IBaseEquipRules(resourcesEquipRules)
        });
        equipConfigs[1] = resourcesEquipConfig;

        registry = new ERC6551Registry();
        pal = deployPalNFT("Pal", "PAL");
        owner = vm.addr(1);
        uint256 tokenId = mintPal(owner);
        inventory = deployPalInventory(tokenId, maxWeight, equipConfigs);

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

    function deployResourcesNFT() public returns (Resources1155) {
        vm.startBroadcast();
        string memory baseURI = "ipfs://";
        Resources1155 impl = new Resources1155();
        Resources1155 proxy = Resources1155(
            address(new TransparentUpgradeableProxy(
                address(impl),
                address(proxyAdmin),
                abi.encodeWithSelector(
                    impl.initialize.selector,
                    baseURI
                )
            ))
        );
        vm.stopBroadcast();
        return proxy;
    }

    function deployPalInventory(
        uint256 tokenId, // PalTokenId
        uint256 maxWeight,
        EquipConfig[] memory _equipConfigs
    ) public returns (PalInventory) {
        vm.startBroadcast();

        palInventoryImpl = new PalInventory();

        bytes32 salt = bytes32(uint256(200));
        inventory = PalInventory(payable(
            registry.createAccount(
                address(palInventoryImpl), salt, block.chainid, address(pal), tokenId
            )
        ));
        // initialize the proxy
        inventory.initialize(maxWeight, _equipConfigs);

        vm.deal(address(inventory), 1 ether);

        vm.stopBroadcast();
        return inventory;
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

        vm.startPrank(owner);
        uint256 tokenId1 = potion.mint(owner);
        uint256 tokenId2 = potion.mint(owner);
        uint256 tokenId3 = potion.mint(owner);
        uint256 tokenId4 = potion.mint(owner);
        potion.approve(address(inventory), tokenId1);
        potion.approve(address(inventory), tokenId2);
        potion.approve(address(inventory), tokenId3);
        potion.approve(address(inventory), tokenId4);

        // IBaseEquipRules pRules = palInventoryProxy.getEquipRules(address(potion), 0);
        // console.log("proxyrules:", address(pRules));

        EquipConfig memory eConfig = inventory.getEquipConfig(address(potion), tokenId1);
        console.log("erules:", address(eConfig.equipRules));
        console.log("owner:", address(owner));

        inventory.equip(address(potion), tokenId1, 1);
        inventory.equip(address(potion), tokenId2, 1);
        inventory.equip(address(potion), tokenId3, 1);

        vm.expectRevert(PotionEquipRules.PotionsExceedMaxLimit.selector);
        inventory.equip(address(potion), tokenId4, 1);
        vm.stopPrank();

    }


    function test_OverweightWithPotionsAndResources() public {

        vm.startPrank(owner);
        uint256 tokenId1 = potion.mint(owner);
        uint256 tokenId2 = potion.mint(owner);
        uint256 tokenId3 = potion.mint(owner);
        uint256 tokenId4 = potion.mint(owner);
        potion.approve(address(inventory), tokenId1);
        potion.approve(address(inventory), tokenId2);
        potion.approve(address(inventory), tokenId3);
        potion.approve(address(inventory), tokenId4);
        // equip a bunch of potions
        inventory.equip(address(potion), tokenId1, 1);
        inventory.equip(address(potion), tokenId2, 1);
        inventory.equip(address(potion), tokenId3, 1);

        uint256 tokenId10 = resources.mint(owner, 0);
        for (uint32 i = 0; i < 7; ++i) {
            resources.mint(owner, 0);
        }
        // same tokenIds for 1155 mints
        resources.setApprovalForAll(address(inventory), true);

        inventory.equip(address(resources), tokenId10, 1);
        inventory.equip(address(resources), tokenId10, 1);
        inventory.equip(address(resources), tokenId10, 1);
        vm.expectRevert(ResourcesEquipRules.ExceedsInventoryMaxWeight.selector);
        inventory.equip(address(resources), tokenId10, 1);

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
