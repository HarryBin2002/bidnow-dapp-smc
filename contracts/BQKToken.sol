// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BQKToken is ERC20, Ownable {
    constructor() ERC20("BQKToken", "BQK") {}
    
    function mintAndApproveToken(address spender, uint256 amount) public {
        // automatically approve to spender is contract and amount is all BQK token minted
        _approve(msg.sender, spender, amount);
        // Mint to owner of contract (msg.sender): 100,000 BQK
        _mint(msg.sender, 100000 * (10**18));
    }

    // 000000000000000000
}