// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Vault is Ownable {
    event Received(address indexed payer, uint value);
   
    constructor(){}

    receive() external payable { 
        emit Received(msg.sender, msg.value);
    }

    // Ottengo il balance dello smart contract
    function getVaultBalance() public view onlyOwner returns(uint256) {
        return address(this).balance;
    }

    // Sposto il balance dello smart contract
    function sendVaultBalance(uint256 _amount, address payable _receiver) public onlyOwner {
        require(address(this).balance >= _amount, "Not enought WEI in the balance");
        _receiver.transfer(_amount);
    }

}