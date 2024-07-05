// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Initializable} from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import {ERC721Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol";
import {ERC721URIStorageUpgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import {Adminable} from "./utils/Adminable.sol";


contract Pal721 is Initializable, ERC721URIStorageUpgradeable, Adminable {

    uint256 private tokenIdCounter;

    function initialize(
        string memory name,
        string memory symbol
    ) initializer public {
        __ERC721_init(name, symbol);
        __Adminable_init();
    }

    function mint(address user) public onlyAdminOrOwner returns (uint256) {
        uint256 tokenId = tokenIdCounter;
        _safeMint(user, tokenId);
        _setTokenURI(tokenId, "ifps://pal");
        ++tokenIdCounter;
        return tokenId;
    }

}
