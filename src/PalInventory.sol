// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC6551AccountUpgradeable} from "@6551/examples/upgradeable/ERC6551AccountUpgradeable.sol";
import {IERC6551Account} from "@6551/interfaces/IERC6551Account.sol";
import {IERC6551Executable} from "@6551/interfaces/IERC6551Executable.sol";
import {Initializable} from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";

contract PalInventory is ERC6551AccountUpgradeable, Initializable {

    function initialize() initializer public {
    }

    // function token() public view override returns (uint256, address, uint256) {
    // }

}
