// SPDX-License: MIT
pragma solidity 0.8.20;

import {HasWeight} from "../items/HasWeight.sol";
import {PalInventory} from "../PalInventory.sol";
import {BaseEquipRules} from "./BaseEquipRules.sol";
import "forge-std/Test.sol";

contract ResourcesEquipRules is BaseEquipRules {

    error ExceedsInventoryMaxWeight();
    error InvalidInventoryWeight();

    constructor() { }

    function canEquip(
        address inventoryAddr,
        address nftAddr,
        uint256 tokenId,
        uint256 amount
    ) external override validateInput(inventoryAddr, amount) returns (bool) {

        PalInventory inventory = PalInventory(payable(inventoryAddr));
        uint256 resourceWeight = HasWeight(nftAddr).getWeight(tokenId);
        uint256 inventoryWeight = inventory.getInventoryWeight();
        uint256 inventoryMaxWeight = inventory.getInventoryMaxWeight();
        console.log("resourceWeight:", resourceWeight);
        console.log("new inventoryWeight:", inventoryWeight + resourceWeight);
        console.log("inventoryMaxWeight:", inventoryMaxWeight);

        if (inventoryWeight + resourceWeight > inventoryMaxWeight) revert ExceedsInventoryMaxWeight();

        inventory.addInventoryWeight(resourceWeight);

        return true;
    }

    function canUnequip(
        address inventoryAddr,
        address nftAddr,
        uint256 tokenId,
        uint256 amount
    ) external override validateInput(inventoryAddr, amount) returns (bool) {

        PalInventory inventory = PalInventory(payable(inventoryAddr));
        uint256 resourceWeight = HasWeight(nftAddr).getWeight(tokenId);
        uint256 inventoryWeight = inventory.getInventoryWeight();

        if (inventoryWeight - resourceWeight < 0) revert InvalidInventoryWeight();

        inventory.subInventoryWeight(resourceWeight);

        return true;
    }


}