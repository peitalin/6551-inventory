// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC6551AccountUpgradeable} from "@6551/examples/upgradeable/ERC6551AccountUpgradeable.sol";
// import {ERC6551AccountUpgradeable} from "./ERC6551AccountUpgradeable.sol";
import {IERC6551Account} from "@6551/interfaces/IERC6551Account.sol";
import {IERC6551Executable} from "@6551/interfaces/IERC6551Executable.sol";
import {Initializable} from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {BaseHook} from "./BaseHook.sol";
import {IEquipRules} from "./EquipRules/IEquipRules.sol";
import "forge-std/Test.sol";



contract PalInventory is ERC6551AccountUpgradeable, Initializable, BaseHook {

    error MustUseEquipFunction();
    error RestrictMint();
    error InvalidAddress();
    error WrongInterface();
    error CallerIsNotOwner();

    event EquipConfigSet(address, uint256, Interfaces, address);

    enum Interfaces { Unsupported, ERC721, ERC1155, DN404, ERC20 }

    struct EquipConfig {
        address nft;
        uint256 tokenId;
        Interfaces supportedInterface;
        IEquipRules equipRules;
    }

    mapping(address nft => mapping(uint256 tokenId => EquipConfig EquipConfig)) public allowedItems;

    /// @dev number of contracts/tokens using given equipping rules
    mapping(address => uint256) public equipRulesUsage;

    /// @dev all equipping rules
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private allEquipRules;


    function initialize(EquipConfig[] memory equipConfigs) public initializer {

        for (uint256 i = 0; i < equipConfigs.length; ++i) {
            _setEquipConfigs(equipConfigs[i]);
        }
    }


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
        console.log(address(allowedItems[equipConfig.nft][equipConfig.tokenId].equipRules));

        emit EquipConfigSet(equipConfig.nft, equipConfig.tokenId, equipConfig.supportedInterface, newRules);
    }

    function beforeEquip(address nft, uint256 tokenId, uint256 amount) public override returns (bytes4) {

        IEquipRules equipRules = getEquipRules(nft, tokenId);

        equipRules.canEquip(address(this), nft, tokenId, amount);

        // lookup the correct NftHandler for the NFT
        // call canEquip() on the NftHandler
        return BaseHook.beforeEquip.selector;
    }

    function afterEquip(address nft, uint256 tokenId, uint256 amount) public override returns (bytes4) {
        // do something
        return BaseHook.afterEquip.selector;
    }

    function equip(address nft, uint256 tokenId, uint256 amount) external returns (uint256) {

        require(_isValidSigner(msg.sender), "Caller is not owner");

        console.log("before");
        beforeEquip(nft, tokenId, amount);

        console.log("transferring...");
        IERC721(nft).safeTransferFrom(msg.sender, address(this), tokenId);

        console.log("after...");
        // careful reentrancy
        afterEquip(nft, tokenId, amount);

    }

    function unequip(address nft, uint256 tokenId) external returns (uint256) {
        require(_isValidSigner(msg.sender), "Caller is not owner");
        IERC721(nft).safeTransferFrom(address(this), ERC6551AccountUpgradeable.owner(), tokenId);
    }

    function getEquipRules(address nft, uint256 tokenId) public returns (IEquipRules) {
        if (nft == address(0)) revert InvalidAddress();

        return allowedItems[nft][tokenId].equipRules;
    }


    function beforeExecute(bytes calldata data) public override returns (bytes4) {
        console.log("before exec");
        bytes4 functionSelector = bytes4(data);
        // "mint(address,uint256)"
        if (functionSelector == 0x6a627842) {
            revert RestrictMint();
        }
        return BaseHook.beforeExecute.selector;
    }

    function afterExecute(bytes calldata data) public override returns (bytes4) {
        console.log("after exec");
        return BaseHook.afterExecute.selector;
    }

    function execute(address _target, uint256 _value, bytes calldata _data, uint8 _operation)
        external
        payable
        override
        returns (bytes memory _result)
    {
        require(_isValidSigner(msg.sender), "Caller is not owner");
        require(_operation == 0, "Only call operations are supported");
        ++state;
        bool success;

        beforeExecute(_data);

        // solhint-disable-next-line avoid-low-level-calls
        (success, _result) = _target.call{value: _value}(_data);
        console.log("executing function:", _target);
        console.log("value:", _value);
        console.log("data:");
        console.logBytes(_data);

        afterExecute(_data);

        require(success, string(_result));
        return _result;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external view override returns (bytes4) {
        ERC6551AccountUpgradeable._revertIfOwnershipCycle(msg.sender, tokenId);

        // bytes4 functionSelector = bytes4(data);
        // // "equip(address,uint256)"
        // if (functionSelector != 0xe0e5d2b2) {
        //     // revert("must use equip(address,uint256) to transfer NFT to inventory");
        //     revert MustUseEquipFunction();
        // }

        return IERC721Receiver.onERC721Received.selector;
    }

    function burn(address nft, uint256 tokenId) public {
        // anyone can burn NFTs that are directly transferred into the inventory.
        // use equip and unequip to transfer NFTs in and out of the inventory.
        // require(_allowedItems[nft][tokenId] != 0);
        IERC721(nft).safeTransferFrom(address(this), address(0), tokenId);
    }

    // force balances to match reserves
    function skim(address to) external {
        // address _token0 = token0; // gas savings
        // address _token1 = token1; // gas savings
        // _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        // _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }

}
