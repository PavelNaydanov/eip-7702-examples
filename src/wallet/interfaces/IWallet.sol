// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { CallType, ExecType, ModeCode } from "@erc7579/lib/ModeLib.sol";
import {ExecutionRequest} from "../libraries/WalletValidator.sol";

interface IWallet {
    error OnlySelf();
    error UnsupportedModuleType(uint256 moduleTypeId);
    error UnsupportedCallType(CallType callType);
    error UnsupportedExecType(ExecType execType);

    function execute(ModeCode mode, bytes calldata executionCalldata) external payable;
    function execute(ExecutionRequest calldata request, bytes calldata signature) external payable;
    function isSaltUsed(bytes32 salt) external view returns (bool);
}