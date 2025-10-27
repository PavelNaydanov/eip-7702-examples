// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title Инсайты:
 * 1. Хранилище смарт-контракта SimpleDelegation, не является доступным для вызовов через EOA. Конструктор контракта не вызывать в контексте EOA.
 *    Поэтому нельзя устанавливать данные через конструктор. Эти данные будут недоступны с вызовом с EOA.
 * + 2. Если SimpleDelegation вызывает другой контракт, то на втором контракте sender будет EOA, а не SimpleDelegation. tx.origin не изменится.
 *    Отсюда проверки, что tx.origin == msg.sender теряют актуальность.
 * 3. Изменение переменных стораджа при вызове остается к контексте EOA.
 * 4. При смене адреса контракта, к которому делигируется вызов, сторадж не будет пустым и может затерт новым контрактом. Получается что сторадж EOA один для всех приконекченных контрактов.
 * 5. Если EOA прикрепил смарт-контракт, то смарт-контракт должен реализовывать функцию receive() иначе нативку невозможно будет отправить на EOA.
 * 6. Отправляем вместе вызовом эфир, то тогда он останется на балансе EOA. Если контракт прикрепленный к EOA отправляет эфир дальше на другой контракт, то он туда и уйдет.
 * 7. Беда при приеме и нфт. Если ты прикрепил код к EOA, то надо, чтобы код умел принимать нфт.
 */
contract SimpleDelegation {
    bool private _isCalled;

    event Called(address indexed origin, address indexed sender, uint256 value);

    constructor() {
        _isCalled = false;
    }

    function callMe(address target) external payable{
        _isCalled = true;

        Target(target).call();

        emit Called(tx.origin, msg.sender, msg.value);
    }

    function callMeWithEth(address target) external payable{
        _isCalled = true;

        Target(target).call{value: msg.value}();

        emit Called(tx.origin, msg.sender, msg.value);
    }

    function isCalled() external view returns (bool) {
        return _isCalled;
    }
}

contract Target {
    event TargetCalled(address indexed origin, address indexed sender, uint256 value);

    function call() external payable {
        emit TargetCalled(tx.origin, msg.sender, msg.value);
    }
}

contract SimpleDelegationSecond {
    uint256 public value;

    function getValue() external view returns (uint256) {
        return value;
    }
}