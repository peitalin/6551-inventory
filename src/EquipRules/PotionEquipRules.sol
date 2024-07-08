// SPDX-License: MIT
pragma solidity 0.8.20;

import "./BaseEquipRules.sol";
import "forge-std/Test.sol";

contract PotionEquipRules is BaseEquipRules {

    uint256 maxPotionsEquippable;
    mapping(address user => uint256 potionsEquipped) potionsEquipped;

    error PotionsExceedMaxLimit();
    error PotionsLowerLimit();

    constructor(
        uint256 _maxPotionsEquippable
    )  {
        maxPotionsEquippable = _maxPotionsEquippable;
    }

    function canEquip(
        address inventory,
        address nft,
        uint256 tokenId,
        uint256 amount
    ) external override validateInput(inventory, amount) returns (bool) {
        potionsEquipped[inventory] += amount;
        if (potionsEquipped[inventory] > maxPotionsEquippable) revert PotionsExceedMaxLimit();
        return true;
    }

    function canUnequip(
        address inventory,
        address nft,
        uint256 tokenId,
        uint256 amount
    ) external override validateInput(inventory, amount) returns (bool) {
        potionsEquipped[inventory] -= amount;
        if (potionsEquipped[inventory] <= 0) revert PotionsLowerLimit();
        return true;
    }

}