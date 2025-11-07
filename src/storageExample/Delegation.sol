// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title Delegation
 * @author Pavel Naydanov
 * @notice Показываем работу хранилища и контекста вызовов при делегировании вызовов через EOA
 */
contract Delegation {
    uint256 private value;

    constructor(uint256 initialValue) {
        value = initialValue;
    }

    function setValue(uint256 newValue) external {
        value = newValue;
    }

    function getValue() external view returns (uint256) {
        return value;
    }
}
