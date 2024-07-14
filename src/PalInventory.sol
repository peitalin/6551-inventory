// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC6551AccountUpgradeable} from "@6551/examples/upgradeable/ERC6551AccountUpgradeable.sol";
import {IERC6551Account} from "@6551/interfaces/IERC6551Account.sol";
import {IERC6551Executable} from "@6551/interfaces/IERC6551Executable.sol";
import {Initializable} from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import {ERC6551Inventory, Interfaces, EquipConfig} from "./ERC6551Inventory.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IERC6551Inventory} from "./interfaces/IERC6551Inventory.sol";
import {IBaseEquipRules} from "./EquipRules/IBaseEquipRules.sol";
import {HasWeight} from "./items/HasWeight.sol";
import "forge-std/Test.sol";


/// @dev if `allowedItems` is set for DEFAULT_ID as `tokenId`,
///      that value will be used as default for all collection,
///      unless specified differently
uint256 constant DEFAULT_ID = 69420e18;


contract PalInventory is ERC6551Inventory, Initializable {

    error RestrictMint();
    error UnsupportItemInterface();

    uint256 public inventoryMaxWeight;
    uint256 public inventoryWeight;

    function initialize(
        uint256 _inventoryMaxWeight,
        EquipConfig[] memory equipConfigs
    ) public initializer {

        inventoryMaxWeight = _inventoryMaxWeight;
        inventoryWeight = 0;

        for (uint256 i = 0; i < equipConfigs.length; ++i) {
            _setEquipConfigs(equipConfigs[i]);
        }
    }

    function getInventoryMaxWeight() public view returns (uint256) {
        return inventoryMaxWeight;
    }

    function getInventoryWeight() public view returns (uint256) {
        return inventoryWeight;
    }

    function addInventoryWeight(uint256 weight) external returns (uint256) {
        /// restrict to equiprules contracts only
        /// move tokenId -> weight lookup and calculation here, or anyone can call this function
        console.log("");
        console.log("msg.sender", msg.sender);
        inventoryWeight += weight;
    }
    function subInventoryWeight(uint256 weight) external returns (uint256) {
        /// restrict to equiprules contracts only
        console.log("msg.sender", msg.sender);
        inventoryWeight -= weight;
    }

    function beforeEquip(address nft, uint256 tokenId, uint256 amount) public override returns (bytes4) {

        EquipConfig memory equipConfig = getEquipConfig(nft, tokenId);

        equipConfig.equipRules.canEquip(address(this), nft, tokenId, amount);

        return IERC6551Inventory.beforeEquip.selector;
    }

    function afterEquip(address nft, uint256 tokenId, uint256 amount) public override returns (bytes4) {
        // do something
        return IERC6551Inventory.afterEquip.selector;
    }

    function equip(address nft, uint256 tokenId, uint256 amount) external override returns (uint256) {

        require(_isValidSigner(msg.sender), "Caller is not owner");

        console.log("before...");
        beforeEquip(nft, tokenId, amount);

        console.log("transferring...");
        EquipConfig memory equipConfig = getEquipConfig(nft, tokenId);
        Interfaces supportedInterface = equipConfig.supportedInterface;

        if (supportedInterface == Interfaces.ERC721) {
            IERC721(nft).safeTransferFrom(msg.sender, address(this), tokenId);
        } else if (supportedInterface == Interfaces.ERC1155) {

            uint256[] memory tokenIds = new uint256[](1);
            uint256[] memory values = new uint256[](1);
            tokenIds[0] = tokenId;
            values[0] = 1;
            IERC1155(nft).safeBatchTransferFrom(msg.sender, address(this), tokenIds, values, abi.encode(0));
        } else {
            revert UnsupportItemInterface();
        }

        console.log("after...");
        // careful reentrancy
        afterEquip(nft, tokenId, amount);

    }

    function unequip(address nft, uint256 tokenId) external override returns (uint256) {
        require(_isValidSigner(msg.sender), "Caller is not owner");
        IERC721(nft).safeTransferFrom(address(this), ERC6551AccountUpgradeable.owner(), tokenId);
    }

    function getEquipConfig(address nft, uint256 tokenId) public override returns (EquipConfig memory) {

        IBaseEquipRules equipRules = allowedItems[nft][tokenId].equipRules;

        if (address(equipRules) == address(0)) {
            return allowedItems[nft][DEFAULT_ID];
        } else if (tokenId == DEFAULT_ID) {
            return allowedItems[nft][DEFAULT_ID];
        } else {
            return allowedItems[nft][tokenId];
        }
    }

    function beforeExecute(bytes calldata data) public override returns (bytes4) {
        bytes4 functionSelector = bytes4(data);
        // "mint(address,uint256)"
        if (functionSelector == 0x6a627842) {
            revert RestrictMint();
        }
        return IERC6551Inventory.beforeExecute.selector;
    }

    function afterExecute(
        bytes calldata data,
        bool success,
        bytes memory results
    ) public override returns (bytes4) {
        console.log("after exec");
        return IERC6551Inventory.afterExecute.selector;
    }


    function burn(address nft, uint256 tokenId) public {
        // anyone can burn NFTs that are directly transferred into the inventory.
        // use equip and unequip to transfer NFTs in and out of the inventory.
        // require(_allowedItems[nft][tokenId] != 0);
        IERC721(nft).safeTransferFrom(address(this), address(0), tokenId);
    }

    // force balances to match reserves
    function skim(address to) external {
        // address _token0 = token0; // gas savings
        // address _token1 = token1; // gas savings
        // _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        // _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }

}
