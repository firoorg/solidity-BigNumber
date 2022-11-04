// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../src/BigNumbers.sol";
import "./util/Strings.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

contract BigNumbersDifferentialTest is Test {
    using BigNumbers for *;
    using Strings for *;
    bytes constant ZERO = hex"0000000000000000000000000000000000000000000000000000000000000000";
    bytes constant  ONE = hex"0000000000000000000000000000000000000000000000000000000000000001";
    bytes constant  TWO = hex"0000000000000000000000000000000000000000000000000000000000000002";

    function testAddMatchesJSImplementationFuzzed(bytes memory a_val, bytes memory b_val, bool a_neg, bool b_neg) public {
        vm.assume(a_val.length > 1 && b_val.length > 1);
        
        BigNumber memory a = a_val.init(a_neg);
        BigNumber memory b = b_val.init(b_neg);
        BigNumber memory res = a.add(b);
        if(res.isZero()) res.neg = false;

        string[] memory runJsInputs = new string[](11);

        // build ffi command string
        runJsInputs[0]  = 'npm';
        runJsInputs[1]  = '--prefix';
        runJsInputs[2]  = 'test/differential/scripts/';
        runJsInputs[3]  = '--silent';
        runJsInputs[4]  = 'run';
        runJsInputs[5]  = 'differential';
        runJsInputs[6]  = 'add';
        runJsInputs[7]  = a_val.toHexString();
        runJsInputs[8]  = b_val.toHexString();
        runJsInputs[9]  = a_neg.toString();
        runJsInputs[10] = b_neg.toString();

        // run and captures output
        bytes memory jsResult = vm.ffi(runJsInputs);
        (bool neg, bytes memory js_res_val ) = abi.decode(jsResult, (bool, bytes));
        BigNumber memory js_res = js_res_val.init(neg);

        assertEq(js_res.neg, res.neg);
        assertEq(js_res.val, res.val);
    }

    function testSubMatchesJSImplementationFuzzed(bytes memory a_val, bytes memory b_val, bool a_neg, bool b_neg) public {
        vm.assume(a_val.length > 1 && b_val.length > 1);
        
        BigNumber memory a = a_val.init(a_neg);
        BigNumber memory b = b_val.init(b_neg);
        BigNumber memory res = a.sub(b);
        if(res.isZero()) res.neg = false;

        string[] memory runJsInputs = new string[](11);

        // build ffi command string
        runJsInputs[0]  = 'npm';
        runJsInputs[1]  = '--prefix';
        runJsInputs[2]  = 'test/differential/scripts/';
        runJsInputs[3]  = '--silent';
        runJsInputs[4]  = 'run';
        runJsInputs[5]  = 'differential';
        runJsInputs[6]  = 'sub';
        runJsInputs[7]  = a_val.toHexString();
        runJsInputs[8]  = b_val.toHexString();
        runJsInputs[9]  = a_neg.toString();
        runJsInputs[10] = b_neg.toString();

        // run and captures output
        bytes memory jsResult = vm.ffi(runJsInputs);
        (bool neg, bytes memory js_res_val ) = abi.decode(jsResult, (bool, bytes));
        BigNumber memory js_res = js_res_val.init(neg);

        assertEq(js_res.neg, res.neg);
        assertEq(js_res.val, res.val);
    }

    function testMulMatchesJSImplementationFuzzed(bytes memory a_val, bytes memory b_val, bool a_neg, bool b_neg) public {
        vm.assume(a_val.length > 1 && b_val.length > 1);
        
        BigNumber memory a = a_val.init(true);
        BigNumber memory b = b_val.init(false);
        BigNumber memory res = a.mul(b);
        //if(res.isZero()) res.neg = false;

        string[] memory runJsInputs = new string[](11);

        // build ffi command string
        runJsInputs[0]  = 'npm';
        runJsInputs[1]  = '--prefix';
        runJsInputs[2]  = 'test/differential/scripts/';
        runJsInputs[3]  = '--silent';
        runJsInputs[4]  = 'run';
        runJsInputs[5]  = 'differential';
        runJsInputs[6]  = 'mul';
        runJsInputs[7]  = a_val.toHexString();
        runJsInputs[8]  = b_val.toHexString();
        runJsInputs[9]  = a_neg.toString();
        runJsInputs[10] = b_neg.toString();

        // run and captures output
        bytes memory jsResult = vm.ffi(runJsInputs);
        (bool neg, bytes memory js_res_val ) = abi.decode(jsResult, (bool, bytes));
        BigNumber memory js_res = js_res_val.init(neg);

        //assertEq(js_res.neg, res.neg);
        assertEq(js_res.val, res.val);
    }

    function testDivMatchesJSImplementationFuzzed(bytes memory a_val, bytes memory b_val, bool a_neg, bool b_neg) public {
        vm.assume(a_val.length > 1 && b_val.length > 1);
        BigNumber memory b = b_val.init(b_neg);
        BigNumber memory zero = BigNumber(ZERO,false,0); 
        vm.assume(b.cmp(zero, false)!=0); // assert that b is not zero
        
        BigNumber memory a = a_val.init(a_neg);

        string[] memory runJsInputs = new string[](11);

        // build ffi command string
        runJsInputs[0]  = 'npm';
        runJsInputs[1]  = '--prefix';
        runJsInputs[2]  = 'test/differential/scripts/';
        runJsInputs[3]  = '--silent';
        runJsInputs[4]  = 'run';
        runJsInputs[5]  = 'differential';
        runJsInputs[6]  = 'div';
        runJsInputs[7]  = a_val.toHexString();
        runJsInputs[8]  = b_val.toHexString();
        runJsInputs[9]  = a_neg.toString();
        runJsInputs[10] = b_neg.toString();

        // run and captures output
        bytes memory jsResult = vm.ffi(runJsInputs);
        (bool neg, bytes memory js_res_val ) = abi.decode(jsResult, (bool, bytes));
        BigNumber memory js_res = js_res_val.init(neg);
        // function will fail if js_res is not the division result
        a.divVerify(b, js_res);
    }

    function testModMatchesJSImplementationFuzzed(bytes memory a_val, bytes memory n_val, bool a_neg) public {
        vm.assume(a_val.length > 1 && n_val.length > 1);
        BigNumber memory n = n_val.init(false);
        BigNumber memory zero = BigNumber(ZERO,false,0); 
        vm.assume(n.cmp(zero, true)!=0); // assert that n is not zero
        
        BigNumber memory a = a_val.init(a_neg);
        BigNumber memory res = a.mod(n);
        if(res.isZero()) res.neg = false;

        string[] memory runJsInputs = new string[](11);

        // build ffi command string
        runJsInputs[0]  = 'npm';
        runJsInputs[1]  = '--prefix';
        runJsInputs[2]  = 'test/differential/scripts/';
        runJsInputs[3]  = '--silent';
        runJsInputs[4]  = 'run';
        runJsInputs[5]  = 'differential';
        runJsInputs[6]  = 'mod';
        runJsInputs[7]  = a_val.toHexString();
        runJsInputs[8]  = n_val.toHexString();
        runJsInputs[9]  = a_neg.toString();

        // run and captures output
        bytes memory jsResult = vm.ffi(runJsInputs);
        (bool neg, bytes memory js_res_val ) = abi.decode(jsResult, (bool, bytes));
        BigNumber memory js_res = js_res_val.init(neg);

        assertEq(js_res.neg, res.neg);
        assertEq(js_res.val, res.val);
    }

    function testShlMatchesJSImplementationFuzzed(bytes memory a_val, uint bits) public {
        vm.assume(a_val.length > 1 && bits <= 2048);
        
        BigNumber memory a = a_val.init(false);
        BigNumber memory res = a.shl(bits);
        if(res.isZero()) res.neg = false;

        console.log('res out:');
        console.logBytes(res.val);

        string[] memory runJsInputs = new string[](9);

        // build ffi command string
        runJsInputs[0]  = 'npm';
        runJsInputs[1]  = '--prefix';
        runJsInputs[2]  = 'test/differential/scripts/';
        runJsInputs[3]  = '--silent';
        runJsInputs[4]  = 'run';
        runJsInputs[5]  = 'differential';
        runJsInputs[6]  = 'shl';
        runJsInputs[7]  = a_val.toHexString();
        runJsInputs[8] = bits.toString();

        // run and captures output
        bytes memory jsResult = vm.ffi(runJsInputs);
        (bool neg, bytes memory js_res_val ) = abi.decode(jsResult, (bool, bytes));
        BigNumber memory js_res = js_res_val.init(neg);

        assertEq(js_res.cmp(res, true), 0);
    }

    function testShrMatchesJSImplementationFuzzed(bytes memory a_val, uint bits) public {
        vm.assume(a_val.length > 1 && bits <= 2048);
        
        BigNumber memory a = a_val.init(false);
        BigNumber memory res = a.shr(bits);
        if(res.isZero()) res.neg = false;

        string[] memory runJsInputs = new string[](9);

        // build ffi command string
        runJsInputs[0]  = 'npm';
        runJsInputs[1]  = '--prefix';
        runJsInputs[2]  = 'test/differential/scripts/';
        runJsInputs[3]  = '--silent';
        runJsInputs[4]  = 'run';
        runJsInputs[5]  = 'differential';
        runJsInputs[6]  = 'shr';
        runJsInputs[7]  = a_val.toHexString();
        runJsInputs[8] = bits.toString();

        // run and captures output
        bytes memory jsResult = vm.ffi(runJsInputs);
        (bool neg, bytes memory js_res_val ) = abi.decode(jsResult, (bool, bytes));
        BigNumber memory js_res = js_res_val.init(neg);

        assertEq(js_res.cmp(res, true), 0);
    }

    function testCmpMatchesJSImplementationFuzzed(bytes memory a_val, bytes memory b_val, bool a_neg, bool b_neg, bool signed) public {
        vm.assume(a_val.length > 1 && b_val.length > 1);
        
        BigNumber memory a = a_val.init(a_neg);
        BigNumber memory b = b_val.init(b_neg);
        int res = a.cmp(b, signed);

        string[] memory runJsInputs = new string[](12);

        // build ffi command string
        runJsInputs[0]  = 'npm';
        runJsInputs[1]  = '--prefix';
        runJsInputs[2]  = 'test/differential/scripts/';
        runJsInputs[3]  = '--silent';
        runJsInputs[4]  = 'run';
        runJsInputs[5]  = 'differential';
        runJsInputs[6]  = 'cmp';
        runJsInputs[7]  = a_val.toHexString();
        runJsInputs[8]  = b_val.toHexString();
        runJsInputs[9]  = a_neg.toString();
        runJsInputs[10] = b_neg.toString();
        runJsInputs[11] = signed.toString();

        // run and captures output
        bytes memory jsResult = vm.ffi(runJsInputs);
        int js_res = abi.decode(jsResult, (int));

        assertEq(js_res, res);
    }

    function testModMulMatchesJSImplementationFuzzed(bytes memory a_val, bytes memory b_val, bytes memory n_val, bool a_neg, bool b_neg) public {
        vm.assume(a_val.length > 1 && b_val.length > 1 && n_val.length > 1);
        
        BigNumber memory a = a_val.init(a_neg);
        BigNumber memory b = b_val.init(b_neg);
        BigNumber memory n = n_val.init(false);
        BigNumber memory zero = BigNumber(ZERO,false,0); 
        vm.assume(n.cmp(zero, true)!=0); // assert that n is not zero

        BigNumber memory res = a.modmul(b, n);
        if(res.isZero()) res.neg = false;

        string[] memory runJsInputs = new string[](12);

        // build ffi command string
        runJsInputs[0]  = 'npm';
        runJsInputs[1]  = '--prefix';
        runJsInputs[2]  = 'test/differential/scripts/';
        runJsInputs[3]  = '--silent';
        runJsInputs[4]  = 'run';
        runJsInputs[5]  = 'differential';
        runJsInputs[6]  = 'modmul';
        runJsInputs[7]  = a_val.toHexString();
        runJsInputs[8]  = b_val.toHexString();
        runJsInputs[9]  = n_val.toHexString();
        runJsInputs[10] = a_neg.toString();
        runJsInputs[11] = b_neg.toString();

        // run and captures output
        bytes memory jsResult = vm.ffi(runJsInputs);
        (bool neg, bytes memory js_res_val ) = abi.decode(jsResult, (bool, bytes));
        BigNumber memory js_res = js_res_val.init(neg);

        assertEq(js_res.eq(res), true);
    }

    function testInvModMatchesJSImplementationFuzzed(bytes memory a_val, bytes memory m_val) public {
        vm.assume(a_val.length > 1 && m_val.length > 1);
        BigNumber memory m = m_val.init(false);
        BigNumber memory zero = BigNumber(ZERO,false,0); 
        vm.assume(!m.eq(zero)); // assert that modulus is not zero
        
        BigNumber memory a = a_val.init(false);

        (bool valid, BigNumber memory js_res ) = invMod(a, m);
        vm.assume(valid); // we don't continue if there is no modular multiplicative inverse for a

        // function will fail if js_res is not the inverse mod result
        a.modinvVerify(m, js_res);
    }

    function testModExpMatchesJSImplementationFuzzed(bytes memory a_val, bytes memory e_val, bytes memory m_val) public {
        vm.assume(a_val.length > 1 && e_val.length > 1 && m_val.length > 1);
        BigNumber memory m = m_val.init(false);
        BigNumber memory zero = BigNumber(ZERO,false,0); 
        vm.assume(!m.eq(zero));
        
        BigNumber memory a = a_val.init(false);
        (bool valid, BigNumber memory a_inv ) = invMod(a, m);
        vm.assume(valid); // we don't continue if there is no modular multiplicative inverse for a

        BigNumber memory e = e_val.init(true);

        BigNumber memory res = a.modexp(a_inv, e, m);

        string[] memory runJsInputs = new string[](10);

        // build ffi command string
        runJsInputs[0]  = 'npm';
        runJsInputs[1]  = '--prefix';
        runJsInputs[2]  = 'test/differential/scripts/';
        runJsInputs[3]  = '--silent';
        runJsInputs[4]  = 'run';
        runJsInputs[5]  = 'differential';
        runJsInputs[6]  = 'modexp';
        runJsInputs[7]  = a_inv.val.toHexString();
        runJsInputs[8]  = e_val.toHexString();
        runJsInputs[9]  = m_val.toHexString();

        // run and captures output
        bytes memory jsResult = vm.ffi(runJsInputs);
        (bool neg, bytes memory js_res_val ) = abi.decode(jsResult, (bool, bytes));

        BigNumber memory js_res = js_res_val.init(neg);

        assertEq(res.eq(js_res), true);
    }

    function invMod(BigNumber memory a, BigNumber memory m) public returns(bool, BigNumber memory) {
        string[] memory runJsInputs = new string[](11);

        // build ffi command string
        runJsInputs[0]  = 'npm';
        runJsInputs[1]  = '--prefix';
        runJsInputs[2]  = 'test/differential/scripts/';
        runJsInputs[3]  = '--silent';
        runJsInputs[4]  = 'run';
        runJsInputs[5]  = 'differential';
        runJsInputs[6]  = 'invmod';
        runJsInputs[7]  = a.val.toHexString();
        runJsInputs[8]  = m.val.toHexString();

        // run and captures output
        bytes memory jsResult = vm.ffi(runJsInputs);
        (bool valid, bool neg, bytes memory val ) = abi.decode(jsResult, (bool, bool, bytes));
        BigNumber memory res = val.init(neg);

        return (valid, res);
    }

    // write a test case for divmod

    // write a test case for div

    // write a test case for mulmod

    // write a test case for powmod

    // write a test case for exp

    // write a test case for invmod

    // write a test case for inv

    // write a test case for sqrt

}
