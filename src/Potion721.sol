// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Initializable} from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import {ERC721URIStorageUpgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import {Adminable} from "./utils/Adminable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Potion721 is Initializable, ERC721URIStorageUpgradeable, Adminable {

    uint256 private _tokenIdCounter;

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
        ++_tokenIdCounter;
        return tokenId;
    }

    function _baseURI() internal view override returns (string memory) {
        return "ifps://";
    }

}
