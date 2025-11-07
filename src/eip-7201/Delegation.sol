// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract Delegation {
    /// @custom:storage-location erc7201:example.main
    struct MainStorage {
        uint256 value;
    }

    // keccak256(abi.encode(uint256(keccak256("MetaLamp_is_the_best")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant MAIN_STORAGE_LOCATION = 0x4c2a6fb6d4ad5058ad6067ef53e231eacc0126d5feacde7622a1c73fcff9cf00;

    function _getMainStorage() private pure returns (MainStorage storage $) {
        assembly {
            $.slot := MAIN_STORAGE_LOCATION
        }
    }

    function getValue() external view returns (uint256) {
        MainStorage storage $ = _getMainStorage();

        // Получаем значение из хранилища, которое хранится в специальном слоте
        return $.value;
    }
}
