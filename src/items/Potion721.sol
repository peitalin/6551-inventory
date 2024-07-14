// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Initializable} from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import {ERC721URIStorageUpgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {Adminable} from "../utils/Adminable.sol";
import {HasWeight} from "./HasWeight.sol";

contract Potion721 is Initializable, ERC721URIStorageUpgradeable, Adminable, HasWeight {

    uint256 private _tokenIdCounter;
    mapping(uint256 _tokeIdCounter => uint256 weight) weight;

    function initialize(
        string memory name,
        string memory symbol
    ) initializer public {
        __ERC721_init(name, symbol);
        __ERC721URIStorage_init();
        __Adminable_init();
    }

    function mint(address user) public returns (uint256) {
        uint256 tokenId = _tokenIdCounter;
        _safeMint(user, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked("potions/", Strings.toString(tokenId), ".json")));

        uint256 randomWeight = tokenId + 2;
        setWeight(tokenId, randomWeight);
        ++_tokenIdCounter;
        return tokenId;
    }

    function setWeight(uint256 tokenId, uint256 randomWeight) internal override returns (uint256) {
        // redo random
        weight[tokenId] = randomWeight;
    }

    function getWeight(uint256 tokenId) external override view returns (uint256) {
        return weight[tokenId];
    }

    function _baseURI() internal view override returns (string memory) {
        return "ipfs://";
    }

}
