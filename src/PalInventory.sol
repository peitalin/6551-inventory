// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC6551Account} from "@6551/examples/upgradeable/ERC6551AccountUpgradeable.sol";
import {IERC6551Account} from "@6551/interfaces/IERC6551Account.sol";
import {IERC6551Executable} from "@6551/interfaces/IERC6551Executable.sol";

contract PalInventory is ERC6551, Initializable {

    function initialize() initializer public {
        __ERC6551_init();
    }

    // function token() public view override returns () {}

}
