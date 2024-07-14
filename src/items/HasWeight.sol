// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

abstract contract HasWeight {

    function setWeight(uint256 tokenId, uint256 weight) internal virtual returns (uint256);

    function getWeight(uint256 tokenId) external virtual view returns (uint256);
}
