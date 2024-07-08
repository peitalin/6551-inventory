// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IBaseHook} from "./IBaseHook.sol";

abstract contract BaseHook is IBaseHook {
    function beforeExecute(bytes calldata data) external virtual returns (bytes4);

    function afterExecute(bytes calldata data) external virtual returns (bytes4);

    function beforeEquip(address nft, uint256 tokenId, uint256 amount) external virtual returns (bytes4);

    function afterEquip(address nft, uint256 tokenId, uint256 amount) external virtual returns (bytes4);
}
