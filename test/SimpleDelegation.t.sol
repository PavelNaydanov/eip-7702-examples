// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console, Vm} from "forge-std/Test.sol";
import {SimpleDelegation, Target, SimpleDelegationSecond} from "../src/SimpleDelegation.sol";

contract SimpleDelegationTest is Test {
    SimpleDelegation public simpleDelegation;
    Target public target;
    SimpleDelegationSecond public simpleDelegationSecond;

    uint256 AlicePK;
    address Alice;
    uint256 BobPK;
    address Bob;

    function setUp() external {
        simpleDelegation = new SimpleDelegation();
        target = new Target();
        simpleDelegationSecond = new SimpleDelegationSecond();

        (Alice, AlicePK) = makeAddrAndKey("Alice");
        (Bob, BobPK) = makeAddrAndKey("Bob");
    }

    function test_callMe() external {
        // Stage 1. Учимся добавлять код к EOA
        console.logBytes(Alice.code); // 0x

        Vm.SignedDelegation memory signedDelegation = vm.signDelegation(address(simpleDelegation), AlicePK);

        vm.startBroadcast(BobPK);
        vm.attachDelegation(signedDelegation);

        console.logBytes(Alice.code); // 0xef01005615deb798bb3e4dfa0139dfa1b3d433cc23b72f

        // Called(origin: Bob: [0x4dBa461cA9342F4A6Cf942aBd7eacf8AE259108C], sender: Bob: [0x4dBa461cA9342F4A6Cf942aBd7eacf8AE259108C], value: 0)
        // TargetCalled(origin: Bob: [0x4dBa461cA9342F4A6Cf942aBd7eacf8AE259108C], sender: Alice: [0xBf0b5A4099F0bf6c8bC4252eBeC548Bae95602Ea], value: 0)
        SimpleDelegation(Alice).callMe(address(target));

        vm.stopBroadcast();

        // Stage2. Смотрим, как меняется сторадж
        console.log(simpleDelegation.isCalled()); // false
        console.log(SimpleDelegation(Alice).isCalled()); // true

        // Stage 3. ДОбавляем код другого смарт-контракта для делегирования

        Vm.SignedDelegation memory signedDelegationSecond = vm.signDelegation(address(simpleDelegationSecond), AlicePK);

        vm.startBroadcast(BobPK);
        vm.attachDelegation(signedDelegationSecond);

        console.log(SimpleDelegationSecond(Alice).getValue()); // Будет 1, так как прошлые вызовы уже установили значение true.
        vm.stopBroadcast();
    }

    function test_callMeWithEth() external {
        Vm.SignedDelegation memory signedDelegation = vm.signDelegation(address(simpleDelegation), AlicePK);

        vm.deal(Bob, 1 ether);
        vm.startBroadcast(BobPK);
        vm.attachDelegation(signedDelegation);

        // emit Called(origin: Bob: [0x4dBa461cA9342F4A6Cf942aBd7eacf8AE259108C], sender: Bob: [0x4dBa461cA9342F4A6Cf942aBd7eacf8AE259108C], value: 1000000000000000000
        // emit TargetCalled(origin: Bob: [0x4dBa461cA9342F4A6Cf942aBd7eacf8AE259108C], sender: Alice: [0xBf0b5A4099F0bf6c8bC4252eBeC548Bae95602Ea], value: 1000000000000000000)
        SimpleDelegation(Alice).callMeWithEth{value: 1 ether}(address(target));

        vm.stopBroadcast();

        console.log(Alice.balance); // 0 ether
        console.log(address(simpleDelegation).balance); // 0
        console.log(address(target).balance); // 1 ether. То есть все деньги улетели на баланс таргет контракта, а не остались на балансе EOA в контексте кого мы это вызывали.
    }
}