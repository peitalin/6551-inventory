//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";

contract Adminable is OwnableUpgradeable {

    mapping(address => bool) private admins;

    function __Adminable_init() internal initializer {
        OwnableUpgradeable.__Ownable_init(msg.sender);
    }

    function addAdmin(address addr) external onlyOwner {
        admins[addr] = true;
    }

    function removeAdmin(address addr) external onlyOwner {
        admins[addr] = false;
    }

    function isAdmin(address addr) public view returns(bool) {
        return admins[addr];
    }

    modifier onlyAdmin() {
        require(admins[msg.sender] == true, "Not an admin");
        _;
    }

    modifier onlyAdminOrOwner() {
        require(admins[msg.sender] || isOwner(), "Not admin or owner");
        _;
    }

    function isOwner() internal view returns(bool) {
        return owner() == msg.sender;
    }

}
