// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC6551AccountUpgradeable} from "@6551/examples/upgradeable/ERC6551AccountUpgradeable.sol";
import {IERC6551Account} from "@6551/interfaces/IERC6551Account.sol";
import {IERC6551Executable} from "@6551/interfaces/IERC6551Executable.sol";
import {Initializable} from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IERC6551Inventory} from "./interfaces/IERC6551Inventory.sol";
import {IBaseEquipRules} from "./EquipRules/IBaseEquipRules.sol";

enum Interfaces { Unsupported, ERC721, ERC1155, DN404, ERC20 }

struct EquipConfig {
    address nft;
    uint256 tokenId;
    Interfaces supportedInterface;
    IBaseEquipRules equipRules;
}


abstract contract ERC6551Inventory is ERC6551AccountUpgradeable, IERC6551Inventory {

    error MustUseEquipFunction();
    error WrongInterface();
    error CallerIsNotOwner();
    error OnlyCallOperationsSupported();

    event EquipConfigSet(address, uint256, Interfaces, address);


    // struct EquipConfig {
    //     address nft;
    //     uint256 tokenId;
    //     Interfaces supportedInterface;
    //     IBaseEquipRules equipRules;
    // }

    mapping(address nft => mapping(uint256 tokenId => EquipConfig EquipConfig)) public allowedItems;

    /// @dev number of contracts/tokens using given equipping rules
    mapping(address => uint256) public equipRulesUsage;

    /// @dev all equipping rules
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private allEquipRules;


    function _setEquipConfigs(EquipConfig memory equipConfig) internal {

        address newRules = address(equipConfig.equipRules);
        address oldRules = address(allowedItems[equipConfig.nft][equipConfig.tokenId].equipRules);

        if (newRules != oldRules) {
            if (oldRules == address(0)) {
                // no old configs, add new configs
                if (equipConfig.supportedInterface == Interfaces.Unsupported) revert WrongInterface();

                allEquipRules.add(newRules);
                equipRulesUsage[newRules]++;
            } else if (newRules == address(0)) {
                // empty new configs, remove old configs
                if (equipRulesUsage[oldRules] == 1) allEquipRules.remove(oldRules);

                equipRulesUsage[oldRules]--;
                equipConfig.supportedInterface = Interfaces.Unsupported;
            } else {
                // update rules
                if (equipConfig.supportedInterface == Interfaces.Unsupported) revert WrongInterface();

                if (equipRulesUsage[oldRules] == 1) allEquipRules.remove(oldRules);
                equipRulesUsage[oldRules]--;

                allEquipRules.add(newRules);
                equipRulesUsage[newRules]++;
            }
        }
        allowedItems[equipConfig.nft][equipConfig.tokenId] = equipConfig;
        emit EquipConfigSet(equipConfig.nft, equipConfig.tokenId, equipConfig.supportedInterface, newRules);
    }

    function beforeEquip(address nft, uint256 tokenId, uint256 amount) public override virtual returns (bytes4);

    function afterEquip(address nft, uint256 tokenId, uint256 amount) public override virtual returns (bytes4);

    function equip(address nft, uint256 tokenId, uint256 amount) external virtual returns (uint256);

    function unequip(address nft, uint256 tokenId) external virtual returns (uint256);

    function getEquipConfig(address nft, uint256 tokenId) public virtual returns (EquipConfig memory);

    function beforeExecute(bytes calldata data) public override virtual returns (bytes4) {
        return IERC6551Inventory.beforeExecute.selector;
    }

    function afterExecute(
        bytes calldata data,
        bool success,
        bytes memory result
    ) public override virtual returns (bytes4) {
        return IERC6551Inventory.afterExecute.selector;
    }

    function execute(address _target, uint256 _value, bytes calldata _data, uint8 _operation)
        external
        payable
        override
        virtual
        returns (bytes memory _result)
    {
        if (!_isValidSigner(msg.sender)) revert CallerIsNotOwner();
        if (_operation != 0) revert OnlyCallOperationsSupported();
        ++state;
        bool success;

        beforeExecute(_data);
        {
            // solhint-disable-next-line avoid-low-level-calls
            (success, _result) = _target.call{value: _value}(_data);
            // console.log("executing function:", _target);
            // console.log("value:", _value);
            // console.log("data:");
            // console.logBytes(_data);
        }
        afterExecute(_data, success, _result);

        require(success, string(_result));
        return _result;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external view override virtual returns (bytes4) {
        ERC6551AccountUpgradeable._revertIfOwnershipCycle(msg.sender, tokenId);

        // bytes4 functionSelector = bytes4(data);
        // // "equip(address,uint256)"
        // if (functionSelector != 0xe0e5d2b2) {
        //     // revert("must use equip(address,uint256) to transfer NFT to inventory");
        //     revert MustUseEquipFunction();
        // }

        return IERC721Receiver.onERC721Received.selector;
    }

}
