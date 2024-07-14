// SPDX-License: MIT
pragma solidity 0.8.20;

import "./IBaseEquipRules.sol";

abstract contract BaseEquipRules is IBaseEquipRules {

    error ZeroAddress();
    error ZeroAmount();

    modifier validateInput(address inventory, uint256 amount) {
        if (inventory == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();
        _;
    }

    function canEquip(address inventory, address nft, uint256 tokenId, uint256 amount) external virtual returns (bool);

    function canUnequip(address inventory, address nft, uint256 tokenId, uint256 amount) external virtual returns (bool);

}