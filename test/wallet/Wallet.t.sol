// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, StdCheats, Vm, console} from "forge-std/Test.sol";
import {IERC20, IERC20Errors} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ModeLib, ModeCode, CALLTYPE_SINGLE, CALLTYPE_BATCH, EXECTYPE_DEFAULT, EXECTYPE_TRY, MODE_DEFAULT, ModePayload, CallType, ExecType} from "@erc7579/lib/ModeLib.sol";
import {ExecutionLib, Execution} from "@erc7579/lib/ExecutionLib.sol";
import {ExecutionHelper} from "@erc7579/core/ExecutionHelper.sol";

import {Wallet, IWallet} from "src/wallet/Wallet.sol";
import {ERC721Mock} from "../mocks/ERC721Mock.sol";
import {ERC1155Mock} from "../mocks/ERC1155Mock.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";

contract WalletTest is Test {
    Wallet public wallet;
    ERC721Mock public erc721Token;
    ERC1155Mock public erc1155Token;
    ERC20Mock public erc20Token;

    StdCheats.Account user;

    function setUp() external {
        user = makeAccount("user");

        wallet = new Wallet();
        erc721Token = new ERC721Mock();
        erc1155Token = new ERC1155Mock();
        erc20Token = new ERC20Mock("Tether USD", "USDT", 6);

        vm.startBroadcast(user.key);

        vm.signAndAttachDelegation(address(wallet), user.key);
        assertTrue(address(user.addr).code.length > 0);

        vm.stopBroadcast();

        vm.label(address(wallet), "Wallet");
        vm.label(user.addr, "User");
        vm.label(address(erc20Token), "USDT");
    }

    // region - User transfer native currency-

    function test_execute_transferNative(uint256 amount) external {
        address recipient = makeAddr("recipient");
        deal(user.addr, amount);

        ModeCode modeCode = ModeLib.encodeSimpleSingle();
        bytes memory userOpCalldata = ExecutionLib.encodeSingle(recipient, amount, "");

        vm.prank(user.addr);
        IWallet(user.addr).execute(modeCode, userOpCalldata);

        assertEq(recipient.balance, amount);
        assertEq(user.addr.balance, 0);
    }

    function test_execute_transferNative_revertIfNotSelf(uint256 amount) external {
        address recipient = makeAddr("recipient");
        deal(user.addr, amount);

        ModeCode modeCode = ModeLib.encodeSimpleSingle();
        bytes memory userOpCalldata = ExecutionLib.encodeSingle(recipient, amount, "");

        vm.expectRevert(IWallet.OnlySelf.selector);

        IWallet(user.addr).execute(modeCode, userOpCalldata);
    }

    // endregion

    // region - User transfer erc-20 token -

    function test_execute_transferERC20(uint256 amount) external {
        address recipient = makeAddr("recipient");
        deal(address(erc20Token), user.addr, amount);

        ModeCode modeCode = ModeLib.encodeSimpleSingle();
        bytes memory userOpCalldata = ExecutionLib.encodeSingle(
            address(erc20Token),
            0,
            abi.encodeWithSelector(IERC20.transfer.selector, recipient, amount)
        );

        vm.prank(user.addr);
        IWallet(user.addr).execute(modeCode, userOpCalldata);

        assertEq(erc20Token.balanceOf(recipient), amount);
        assertEq(erc20Token.balanceOf(user.addr), 0);
    }

    function test_execute_transferERC20_revertIfNotSelf(uint256 amount) external {
        address recipient = makeAddr("recipient");
        deal(address(erc20Token), user.addr, amount);

        ModeCode modeCode = ModeLib.encodeSimpleSingle();

        bytes memory userOpCalldata = ExecutionLib.encodeSingle(
            address(erc20Token),
            0,
            abi.encodeWithSelector(IERC20.transfer.selector, recipient, amount)
        );

        vm.expectRevert(IWallet.OnlySelf.selector);

        IWallet(user.addr).execute(modeCode, userOpCalldata);
    }

    // endregion

    // region - Single execute -

    function test_execute_revertIfUnsupportedCallType(uint256 amount, bytes1 invalidCallType) external {
        address recipient = makeAddr("recipient");
        deal(address(erc20Token), user.addr, amount);

        vm.assume(invalidCallType != 0x00 && invalidCallType != 0x01 && invalidCallType != 0xFE && invalidCallType != 0xFF);

        ModeCode modeCode = ModeLib.encode(CallType.wrap(invalidCallType), EXECTYPE_DEFAULT, MODE_DEFAULT, ModePayload.wrap(0x00));
        bytes memory userOpCalldata = ExecutionLib.encodeSingle(
            address(erc20Token),
            0,
            abi.encodeWithSelector(IERC20.transfer.selector, recipient, amount)
        );

        vm.expectRevert(abi.encodeWithSelector(IWallet.UnsupportedCallType.selector, invalidCallType));

        vm.prank(user.addr);
        IWallet(user.addr).execute(modeCode, userOpCalldata);
    }

    function test_execute_CALLTYPE_SINGLE_EXECTYPE_DEFAULT(uint256 amount) external {
        address recipient = makeAddr("recipient");
        deal(address(erc20Token), user.addr, amount);

        ModeCode modeCode = ModeLib.encodeSimpleSingle();
        bytes memory userOpCalldata = ExecutionLib.encodeSingle(
            address(erc20Token),
            0,
            abi.encodeWithSelector(IERC20.transfer.selector, recipient, amount)
        );

        vm.prank(user.addr);
        IWallet(user.addr).execute(modeCode, userOpCalldata);

        assertEq(erc20Token.balanceOf(recipient), amount);
        assertEq(erc20Token.balanceOf(user.addr), 0);
    }

    function test_execute_CALLTYPE_SINGLE_EXECTYPE_TRY(uint256 amount) external {
        address recipient = makeAddr("recipient");
        deal(address(erc20Token), user.addr, amount);

        ModeCode modeCode = ModeLib.encode(CALLTYPE_SINGLE, EXECTYPE_TRY, MODE_DEFAULT, ModePayload.wrap(0x00));
        bytes memory userOpCalldata = ExecutionLib.encodeSingle(
            address(erc20Token),
            0,
            abi.encodeWithSelector(IERC20.transfer.selector, recipient, amount)
        );

        vm.prank(user.addr);
        IWallet(user.addr).execute(modeCode, userOpCalldata);

        assertEq(erc20Token.balanceOf(recipient), amount);
        assertEq(erc20Token.balanceOf(user.addr), 0);
    }

    function test_execute_CALLTYPE_SINGLE_EXECTYPE_TRY_emitTryExecuteUnsuccessful(uint256 amount) external {
        address recipient = makeAddr("recipient");

        ModeCode modeCode = ModeLib.encode(CALLTYPE_SINGLE, EXECTYPE_TRY, MODE_DEFAULT, ModePayload.wrap(0x00));
        bytes memory userOpCalldata = ExecutionLib.encodeSingle(
            address(erc20Token),
            0,
            abi.encodeWithSelector(IERC20.transfer.selector, recipient, amount)
        );

        // TODO: We can't check event, because it has place in deep callstack. Revert is happen earlier
        vm.prank(user.addr);
        IWallet(user.addr).execute(modeCode, userOpCalldata);

        assertEq(erc20Token.balanceOf(recipient), 0);
        assertEq(erc20Token.balanceOf(user.addr), 0);
    }

    function test_execute_CALLTYPE_SINGLE_revertIfUnsupportedExecType(uint256 amount, bytes1 invalidExecType) external {
        address recipient = makeAddr("recipient");
        deal(address(erc20Token), user.addr, amount);

        vm.assume(invalidExecType != 0x00 && invalidExecType != 0x01);

        ModeCode modeCode = ModeLib.encode(CALLTYPE_SINGLE, ExecType.wrap(invalidExecType), MODE_DEFAULT, ModePayload.wrap(0x00));
        bytes memory userOpCalldata = ExecutionLib.encodeSingle(
            address(erc20Token),
            0,
            abi.encodeWithSelector(IERC20.transfer.selector, recipient, amount)
        );

        vm.expectRevert(abi.encodeWithSelector(IWallet.UnsupportedExecType.selector, invalidExecType));

        vm.prank(user.addr);
        IWallet(user.addr).execute(modeCode, userOpCalldata);

    }

    // endregion

    // region - Batch execute -

    function test_execute_CALLTYPE_BATCH_EXECTYPE_DEFAULT(uint64 amount) external {
        SpenderMock spender = new SpenderMock();
        vm.label(address(spender), "Spender");

        deal(address(erc20Token), user.addr, amount);

        ModeCode modeCode = ModeLib.encode(CALLTYPE_BATCH, EXECTYPE_DEFAULT, MODE_DEFAULT, ModePayload.wrap(0x00));

        Execution[] memory executions = new Execution[](2);
        executions[0] = Execution({
            target: address(erc20Token),
            value: 0,
            callData: abi.encodeWithSelector(IERC20.approve.selector, address(spender), amount)
        });
        executions[1] = Execution({
            target: address(spender),
            value: 0,
            callData: abi.encodeWithSelector(SpenderMock.deposit.selector, address(erc20Token), amount)
        });

        bytes memory userOpCalldata = ExecutionLib.encodeBatch(executions);

        vm.prank(user.addr);
        IWallet(user.addr).execute(modeCode, userOpCalldata);

        assertEq(erc20Token.balanceOf(address(spender)), amount);
        assertEq(erc20Token.allowance(user.addr, address(spender)), 0);
        assertEq(erc20Token.balanceOf(user.addr), 0);
    }

    function test_execute_CALLTYPE_BATCH_EXECTYPE_TRY(uint64 amount) external {
        SpenderMock spender = new SpenderMock();
        vm.label(address(spender), "Spender");

        ModeCode modeCode = ModeLib.encode(CALLTYPE_BATCH, EXECTYPE_TRY, MODE_DEFAULT, ModePayload.wrap(0x00));

        Execution[] memory executions = new Execution[](2);
        executions[0] = Execution({
            target: address(erc20Token),
            value: 0,
            callData: abi.encodeWithSelector(IERC20.approve.selector, address(spender), amount)
        });
        executions[1] = Execution({
            target: address(spender),
            value: 0,
            callData: abi.encodeWithSelector(SpenderMock.deposit.selector, address(erc20Token), amount)
        });

        bytes memory userOpCalldata = ExecutionLib.encodeBatch(executions);

        vm.prank(user.addr);
        IWallet(user.addr).execute(modeCode, userOpCalldata);

        assertEq(erc20Token.balanceOf(address(spender)), 0);
        assertEq(erc20Token.allowance(user.addr, address(spender)), amount);
        assertEq(erc20Token.balanceOf(user.addr), 0);
    }

    function test_execute_CALLTYPE_BATCH_revertIfUnsupportedExecType(uint64 amount, bytes1 invalidExecType) external {
        SpenderMock spender = new SpenderMock();
        vm.label(address(spender), "Spender");

        deal(address(erc20Token), user.addr, amount);

        vm.assume(invalidExecType != 0x00 && invalidExecType != 0x01);

        ModeCode modeCode = ModeLib.encode(CALLTYPE_BATCH, ExecType.wrap(invalidExecType), MODE_DEFAULT, ModePayload.wrap(0x00));

        Execution[] memory executions = new Execution[](2);
        executions[0] = Execution({
            target: address(erc20Token),
            value: 0,
            callData: abi.encodeWithSelector(IERC20.approve.selector, address(spender), amount)
        });
        executions[1] = Execution({
            target: address(spender),
            value: 0,
            callData: abi.encodeWithSelector(SpenderMock.deposit.selector, address(erc20Token), amount)
        });

        bytes memory userOpCalldata = ExecutionLib.encodeBatch(executions);

        vm.expectRevert(abi.encodeWithSelector(IWallet.UnsupportedExecType.selector, invalidExecType));

        vm.prank(user.addr);
        IWallet(user.addr).execute(modeCode, userOpCalldata);
    }

    // endregion

    // region - Wallet can get other tokens -

    function test_sendERC721() external {
        address sender = makeAddr("sender");
        uint256 tokenId = 1;

        erc721Token.mint(sender, tokenId);

        vm.prank(sender);
        erc721Token.safeTransferFrom(sender, address(wallet), tokenId);

        assertEq(erc721Token.ownerOf(tokenId), address(wallet));
        assertNotEq(erc721Token.ownerOf(tokenId), sender);
    }

    function test_sendERC1155() external {
        address sender = makeAddr("sender");
        uint256 tokenId = 1;
        uint256 value = 1;

        erc1155Token.mint(sender, tokenId, value);

        vm.prank(sender);
        erc1155Token.safeTransferFrom(sender, address(wallet), tokenId, value, "");

        assertEq(erc1155Token.balanceOf(address(wallet), tokenId), value);
        assertEq(erc1155Token.balanceOf(sender, tokenId), 0);
    }

    function test_sendNative(uint256 value) external {
        address sender = makeAddr("sender");
        deal(sender, value);


        vm.prank(sender);
        (bool success,) = address(wallet).call{value: value}("");

        assertTrue(success);
        assertEq(address(wallet).balance, value);
        assertEq(sender.balance, 0);
    }

    // endregion
}

contract SpenderMock {
    function deposit(address token, uint256 amount) external {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }
}