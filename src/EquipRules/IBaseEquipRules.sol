// SPDX-License: MIT
pragma solidity 0.8.20;

interface IBaseEquipRules {

    function canEquip(address inventory, address nft, uint256 tokenId, uint256 amount) external returns (bool);

    function canUnequip(address inventory, address nft, uint256 tokenId, uint256 amount) external returns (bool);
}