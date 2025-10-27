// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract Target {
    uint256 private value;

    error EOACallIsNotAllowed();

    function setValue(uint256 newValue) external {
        if (tx.origin == msg.sender) {
            revert EOACallIsNotAllowed();
        }

        value = newValue;
    }

    function getValue() external view returns (uint256) {
        return value;
    }
}

/**
 * @title Delegation
 * @author Pavel Naydanov
 * @notice Показываем, что теперь EOA обходит проверку tx.origin == msg.sender
 */
contract Delegation {
    function setValue(address target, uint256 value) external {
        Target(target).setValue(value);
    }
}