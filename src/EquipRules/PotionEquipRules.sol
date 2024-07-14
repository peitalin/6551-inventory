// SPDX-License: MIT
pragma solidity 0.8.20;

import {HasWeight} from "../items/HasWeight.sol";
import {PalInventory} from "../PalInventory.sol";
import {BaseEquipRules} from "./BaseEquipRules.sol";
import "forge-std/Test.sol";

contract PotionEquipRules is BaseEquipRules {

    uint256 maxPotionsEquippable;
    // this is for an individual's inventory, so you don't need to track a bunch of users here
    mapping(address user => uint256 potionsEquipped) potionsEquipped;

    error PotionsExceedMaxLimit();
    error InvalidInventoryWeight();
    error ExceedsInventoryMaxWeight();

    constructor(
        uint256 _maxPotionsEquippable
    ) {
        maxPotionsEquippable = _maxPotionsEquippable;
    }

    function canEquip(
        address inventoryAddr,
        address nftAddr,
        uint256 tokenId,
        uint256 amount
    ) external override validateInput(inventoryAddr, amount) returns (bool) {

        PalInventory inventory = PalInventory(payable(inventoryAddr));
        uint256 potionWeight = HasWeight(nftAddr).getWeight(tokenId);
        uint256 inventoryWeight = inventory.getInventoryWeight();
        uint256 inventoryMaxWeight = inventory.getInventoryMaxWeight();

        if (inventoryWeight + potionWeight > inventoryMaxWeight) revert ExceedsInventoryMaxWeight();
        if (potionsEquipped[inventoryAddr] + amount > maxPotionsEquippable) revert PotionsExceedMaxLimit();

        potionsEquipped[inventoryAddr] += amount;

        inventory.addInventoryWeight(potionWeight);

        return true;
    }

    function canUnequip(
        address inventoryAddr,
        address nftAddr,
        uint256 tokenId,
        uint256 amount
    ) external override validateInput(inventoryAddr, amount) returns (bool) {

        PalInventory inventory = PalInventory(payable(inventoryAddr));
        uint256 potionWeight = HasWeight(nftAddr).getWeight(tokenId);
        uint256 inventoryWeight = inventory.getInventoryWeight();

        if (inventoryWeight - potionWeight < 0) revert InvalidInventoryWeight();
        if (potionsEquipped[inventoryAddr] - amount <= 0) revert InvalidInventoryWeight();

        inventory.subInventoryWeight(potionWeight);
        potionsEquipped[inventoryAddr] -= amount;

        return true;
    }

}