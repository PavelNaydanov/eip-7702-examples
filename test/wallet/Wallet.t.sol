// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, StdCheats, Vm, console} from "forge-std/Test.sol";
import {ModeLib, ModeCode} from "@erc7579/lib/ModeLib.sol";
import {ExecutionLib} from "@erc7579/lib/ExecutionLib.sol";

import {Wallet, IWallet} from "src/wallet/Wallet.sol";

contract WalletTest is Test {
    Wallet public wallet;

    StdCheats.Account user;

    function setUp() external {
        user = makeAccount("user");

        wallet = new Wallet();

        vm.startBroadcast(user.key);

        vm.signAndAttachDelegation(address(wallet), user.key);
        assertTrue(address(user.addr).code.length > 0);

        vm.stopBroadcast();
    }

    // region - User transfer native currency-

    function test_execute_transferNative(uint256 amount) external {
        address recipient = makeAddr("recipient");
        vm.deal(user.addr, amount);

        ModeCode modeCode = ModeLib.encodeSimpleSingle();
        bytes memory userOpCalldata = ExecutionLib.encodeSingle(recipient, amount, "");

        vm.prank(user.addr);
        IWallet(user.addr).execute(modeCode, userOpCalldata);

        assertEq(recipient.balance, amount);
        assertEq(user.addr.balance, 0);
    }

    function test_execute_transferNative_revertIfNotSelf(uint256 amount) external {
        address recipient = makeAddr("recipient");
        vm.deal(user.addr, amount);

        ModeCode modeCode = ModeLib.encodeSimpleSingle();
        bytes memory userOpCalldata = ExecutionLib.encodeSingle(recipient, amount, "");

        vm.expectRevert(IWallet.OnlySelf.selector);

        IWallet(user.addr).execute(modeCode, userOpCalldata);
    }

    // endregion

}