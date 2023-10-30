// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {Test, console2} from "forge-std/Test.sol";
import {HoldHelper} from "../src/HoldHelper.sol";
import {HoldHelperV2} from "../src/HoldHelperV2.sol";
import {HoldHelperV3} from "../src/HoldHelperV3.sol";

contract HoldTest is Test {
    function testHolder() public {
        HoldHelper hdr = new HoldHelper();
        uint256 holdSeconds = 60;
        address a1 = vm.addr(1);
        address a2 = vm.addr(2);
        vm.deal(a1, 10 ether);
        vm.deal(a2, 10 ether);

        vm.prank(a1);
        hdr.deposit{value: 1 ether}(holdSeconds);

        vm.prank(a2);
        hdr.deposit{value: 2 ether}(holdSeconds);

        console2.log("hold balance, a1, a2", address(hdr).balance, a1.balance, a2.balance);

        vm.warp(120);
        vm.prank(a1);
        hdr.withdraw(0);

        vm.prank(a2);
        vm.expectRevert();
        hdr.withdraw(3 ether);
        console2.log("hold balance, a1, a2", address(hdr).balance, a1.balance, a2.balance);

        vm.prank(a2);
        hdr.withdraw(1 ether);
        assert(address(hdr).balance == 1 ether);
        assert(a1.balance == 10 ether);
        assert(a2.balance == 9 ether);
        console2.log("hold balance, a1, a2", address(hdr).balance, a1.balance, a2.balance);
    }

    function testHolderV2() public {
        HoldHelperV2 hdr = new HoldHelperV2();
        uint256 holdSeconds = 60;
        address a1 = vm.addr(1);
        address a2 = vm.addr(2);
        vm.deal(a1, 10 ether);
        vm.deal(a2, 10 ether);

        vm.prank(a1);
        hdr.deposit{value: 1 ether}(holdSeconds);

        vm.prank(a2);
        hdr.deposit{value: 2 ether}(holdSeconds);

        console2.log("hold balance, a1, a2", address(hdr).balance, a1.balance, a2.balance);

        vm.warp(120);
        vm.prank(a1);
        hdr.withdraw(0);

        vm.prank(a2);
        vm.expectRevert();
        hdr.withdraw(3 ether);
        console2.log("hold balance, a1, a2", address(hdr).balance, a1.balance, a2.balance);

        vm.prank(a2);
        hdr.withdraw(1 ether);
        assert(address(hdr).balance == 1 ether);
        assert(a1.balance == 10 ether);
        assert(a2.balance == 9 ether);
        console2.log("hold balance, a1, a2", address(hdr).balance, a1.balance, a2.balance);

        hdr.authorisedWithdraw(a2);
        assert(address(hdr).balance == 0 ether);
        assert(a1.balance == 10 ether);
        assert(a2.balance == 9 ether);
        console2.log("hold balance, a1, a2", address(hdr).balance, a1.balance, a2.balance);
    }

    function testHolderV3() public {
        address a1 = vm.addr(1);
        address a2 = vm.addr(2);
        address a3 = vm.addr(3);
        vm.deal(a1, 10 ether);
        vm.deal(a2, 10 ether);

        vm.prank(a3); //a3 will be contract owner.
        HoldHelperV3 hdr = new HoldHelperV3(600);
        uint256 holdSeconds = 60;

        vm.prank(a1);
        hdr.deposit{value: 1 ether}(holdSeconds);

        vm.prank(a2);
        hdr.deposit{value: 2 ether}(holdSeconds);

        console2.log("hold balance, a1, a2", address(hdr).balance, a1.balance, a2.balance);

        vm.warp(120);
        vm.prank(a1);
        hdr.withdraw(0);

        vm.prank(a2);
        vm.expectRevert();
        hdr.withdraw(3 ether);
        console2.log("hold balance, a1, a2", address(hdr).balance, a1.balance, a2.balance);

        vm.prank(a2);
        hdr.withdraw(1 ether);
        assert(address(hdr).balance == 1 ether);
        assert(a1.balance == 10 ether);
        assert(a2.balance == 9 ether);
        console2.log("hold balance, a1, a2", address(hdr).balance, a1.balance, a2.balance);

        vm.prank(a3);
        hdr.proposeWithdraw(a2);
        vm.prank(a3);
        vm.expectRevert();
        hdr.authorisedWithdraw(a2);

        vm.warp(1000);
        vm.prank(a3);
        hdr.authorisedWithdraw(a2);
        assert(address(hdr).balance == 0 ether);
        assert(a1.balance == 10 ether);
        assert(a2.balance == 9 ether);
        assert(a3.balance == 1 ether);
        console2.log("a3, a1, a2", a3.balance / (1 ether), a1.balance / (1 ether), a2.balance / (1 ether));
    }

    receive() external payable {}
}
