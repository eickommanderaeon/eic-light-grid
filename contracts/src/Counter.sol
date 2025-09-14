// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Counter {
    uint256 public count;

    function increment() external {
        unchecked { count += 1; }
    }

    function decrement() external {
        require(count > 0, "underflow");
        unchecked { count -= 1; }
    }
}
