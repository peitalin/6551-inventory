// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC721} from "openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";

import {ERC6551Account} from "@6551/examples/simple/ERC6551Account.sol";
import {IERC6551Account} from "@6551/interfaces/IERC6551Account.sol";
import {IERC6551Executable} from "@6551/interfaces/IERC6551Executable.sol";

import "./utils/Adminable.sol";

contract Pal721 is ERC721, Adminable {

    using Counters for Counters.Counter;
    Counteres.Counter private _tokenIds;

    function initialize(string memory name, string memory symbol) initializer public {
        ERC721.__ERC721_init(name, symbol);
        Adminable.__Adminable_init();
    }

    function mint(address user, string memory tokenURI) public onlyAdminOrOwner returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(user, newTokenId);
        _setTokenURI(newItemId, tokenURI);
        return newTokenId;
    }

}
