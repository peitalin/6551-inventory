// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Initializable} from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import {ERC721URIStorageUpgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Adminable} from "./utils/Adminable.sol";


contract Pal721 is Initializable, IERC721Receiver, ERC721URIStorageUpgradeable, Adminable {

    uint256 private _tokenIdCounter;

    function initialize(
        string memory name,
        string memory symbol
    ) initializer public {
        __ERC721_init(name, symbol);
        __ERC721URIStorage_init();
        __Adminable_init();
    }

    function mint(address user) public onlyAdminOrOwner returns (uint256) {
        uint256 tokenId = _tokenIdCounter;
        _safeMint(user, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked("pals/", Strings.toString(tokenId), ".json")));
        ++_tokenIdCounter;
        return tokenId;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external view override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }


    function _baseURI() internal view override returns (string memory) {
        return "ipfs://";
    }

}
