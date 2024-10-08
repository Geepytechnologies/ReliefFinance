// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockRWA is ERC20 {
    constructor() ERC20("Mock RWA", "MRWA") {
        _mint(msg.sender, 1000000 * 10 ** uint(decimals())); 
    }
}
