// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { ExecutionHelper } from "@erc7579/core/ExecutionHelper.sol";
import { ExecutionLib } from "@erc7579/lib/ExecutionLib.sol";
import {
    ModeLib,
    ModeCode,
    Execution,
    CallType,
    ExecType,
    CALLTYPE_BATCH,
    EXECTYPE_DEFAULT,
    EXECTYPE_TRY,
    CALLTYPE_SINGLE
} from "@erc7579/lib/ModeLib.sol";

import {IWallet} from "./interfaces/IWallet.sol";

contract Wallet is IWallet, ExecutionHelper {
    using ModeLib for ModeCode;
    using ExecutionLib for bytes;

    modifier onlySelf {
        if (msg.sender != address(this)) {
            revert OnlySelf();
        }

        _;
    }

    function execute(ModeCode mode, bytes calldata executionCalldata) external payable onlySelf {
        (CallType callType, ExecType execType,,) = mode.decode();

        if (callType == CALLTYPE_BATCH) {
            Execution[] calldata executions_ = executionCalldata.decodeBatch();
            if (execType == EXECTYPE_DEFAULT) {
                _execute(executions_);
            } else if (execType == EXECTYPE_TRY) {
                _tryExecute(executions_);
            } else {
                revert UnsupportedExecType(execType);
            }
        } else if (callType == CALLTYPE_SINGLE) {
            (address target, uint256 value, bytes calldata callData) = executionCalldata.decodeSingle();
            if (execType == EXECTYPE_DEFAULT) {
                _execute(target, value, callData);
            } else if (execType == EXECTYPE_TRY) {
                bytes[] memory returnData_ = new bytes[](1);
                bool success_;
                (success_, returnData_[0]) = _tryExecute(target, value, callData);
                if (!success_) emit TryExecuteUnsuccessful(0, returnData_[0]);
            } else {
                revert UnsupportedExecType(execType);
            }
        } else {
            revert UnsupportedCallType(callType);
        }
    }
}