// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";

contract CounterTest is Test {
    Counter c;

    function setUp() public {
        c = new Counter();
    }

    function testIncrement() public {
        c.increment();
        assertEq(c.count(), 1);
    }

    function testDecrementRevertsOnUnderflow() public {
        vm.expectRevert(bytes("underflow"));
        c.decrement();
    }
}
