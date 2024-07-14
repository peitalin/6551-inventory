// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC6551Account} from "@6551/interfaces/IERC6551Account.sol";
import {IERC6551Executable} from "@6551/interfaces/IERC6551Executable.sol";

interface IPalInventory is IERC6551Account, IERC6551Executable {

    function getInventoryMaxWeight() external view returns (uint256);

    function getInventoryWeight() external view returns (uint256);

    function equip(address nft, uint256 tokenId, uint256 amount) external returns (uint256);

    function unequip(address nft, uint256 tokenId, uint256 amount) external returns (uint256);

}
