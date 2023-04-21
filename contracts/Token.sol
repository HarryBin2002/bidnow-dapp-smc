// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, Ownable {
    constructor() ERC20("Token", "BQT") {}
    
    function mintAndApproveToken(address bidNowContract) public {
        // automatically approve to spender is contract and amount is all BQK token minted
        _approve(msg.sender, bidNowContract, 100000 * (10**18));
        // Mint to owner of contract (msg.sender): 100,000 BQK
        _mint(msg.sender, 100000 * (10**18));
    }
}
// 000000000000000000