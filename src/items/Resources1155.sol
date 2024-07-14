// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Initializable} from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import {ERC1155URIStorageUpgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {Adminable} from "../utils/Adminable.sol";
import {HasWeight} from "./HasWeight.sol";


contract Resources1155 is Initializable, IERC1155Receiver, ERC1155URIStorageUpgradeable, Adminable, HasWeight {

    error InvalidTokenId();

    mapping(uint256 tokenId => uint256 weight) weight;

    uint256 num1155Tokens = 5;

    function initialize(string memory baseURI) initializer public {
        __ERC1155_init(baseURI);
        __ERC1155URIStorage_init();
        __Adminable_init();

        // tokenId 0, wood, 2kg
        // tokenId 1, stone, 4kg
        // tokenId 2, paldium, 3kg
        // tokenId 3, iron, 5kg
        // tokenId 4, coal, 1kg
        setWeight(0, 2);
        setWeight(1, 4);
        setWeight(2, 3);
        setWeight(3, 5);
        setWeight(4, 1);
    }

    function mint(address user, uint256 tokenId) public returns (uint256) {
        if (tokenId > num1155Tokens) revert InvalidTokenId();
        _mint(user, tokenId, 1, abi.encode(0));
        _setURI(tokenId, string(abi.encodePacked("resources/", Strings.toString(tokenId), ".json")));
        return tokenId;
    }

    function setWeight(uint256 tokenId, uint256 randomWeight) internal override returns (uint256) {
        weight[tokenId] = randomWeight;
    }

    function getWeight(uint256 tokenId) external override view returns (uint256) {
        return weight[tokenId];
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

}
