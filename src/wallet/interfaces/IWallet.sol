// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { CallType, ExecType, ModeCode } from "@erc7579/lib/ModeLib.sol";

interface IWallet {
    error OnlySelf();
    error UnsupportedModuleType(uint256 moduleTypeId);
    error UnsupportedCallType(CallType callType);
    error UnsupportedExecType(ExecType execType);

    function execute(ModeCode mode, bytes calldata executionCalldata) external payable;
}