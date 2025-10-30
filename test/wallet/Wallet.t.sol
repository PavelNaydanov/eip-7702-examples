// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, StdCheats, Vm, console} from "forge-std/Test.sol";
import {ModeLib, ModeCode} from "@erc7579/lib/ModeLib.sol";
import {ExecutionLib} from "@erc7579/lib/ExecutionLib.sol";

import {Wallet, IWallet} from "src/wallet/Wallet.sol";
import {ERC721Mock} from "../mocks/ERC721Mock.sol";
import {ERC1155Mock} from "../mocks/ERC1155Mock.sol";

contract WalletTest is Test {
    Wallet public wallet;
    ERC721Mock public erc721Token;
    ERC1155Mock public erc1155Token;

    StdCheats.Account user;

    function setUp() external {
        user = makeAccount("user");

        wallet = new Wallet();
        erc721Token = new ERC721Mock();
        erc1155Token = new ERC1155Mock();

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