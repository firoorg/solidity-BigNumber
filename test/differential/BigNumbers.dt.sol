pragma solidity ^0.8.16;

import "../../src/BigNumbers.sol";
import "./util/Strings.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

contract BigNumbersDifferentialTest is Test, IBigNumbers {
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
        
        BigNumber memory a = a_val.init(a_neg);
        BigNumber memory b = b_val.init(b_neg);
        BigNumber memory res = a.mul(b);

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

        assertEq(js_res.neg, res.neg);
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
        a.div(b, js_res);
    }

    function testModMatchesJSImplementationFuzzed(bytes memory a_val, bytes memory n_val, bool a_neg) public {
        vm.assume(a_val.length > 1 && n_val.length > 1);
        
        BigNumber memory a = a_val.init(a_neg);
        BigNumber memory n = n_val.init(false);
        BigNumber memory res = a.mod(n);

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

    function testShlMatchesJSImplementationFuzzed(bytes memory a_val, bool a_neg, uint bits) public {
        vm.assume(a_val.length > 1 && bits <= 2048);
        
        BigNumber memory a = a_val.init(a_neg);
        BigNumber memory res = a.shl(bits);

        string[] memory runJsInputs = new string[](10);

        // build ffi command string
        runJsInputs[0]  = 'npm';
        runJsInputs[1]  = '--prefix';
        runJsInputs[2]  = 'test/differential/scripts/';
        runJsInputs[3]  = '--silent';
        runJsInputs[4]  = 'run';
        runJsInputs[5]  = 'differential';
        runJsInputs[6]  = 'shl';
        runJsInputs[7]  = a_val.toHexString();
        runJsInputs[8]  = a_neg.toString();
        runJsInputs[9] = bits.toString();

        // run and captures output
        bytes memory jsResult = vm.ffi(runJsInputs);
        (bool neg, bytes memory js_res_val ) = abi.decode(jsResult, (bool, bytes));
        BigNumber memory js_res = js_res_val.init(neg);

        assertEq(js_res.cmp(res, true), 0);
    }

    function testShrMatchesJSImplementationFuzzed(bytes memory a_val, bool a_neg, uint bits) public {
        vm.assume(a_val.length > 1);
        
        BigNumber memory a = a_val.init(a_neg);
        BigNumber memory res = a.shr(bits);

        string[] memory runJsInputs = new string[](10);

        // build ffi command string
        runJsInputs[0]  = 'npm';
        runJsInputs[1]  = '--prefix';
        runJsInputs[2]  = 'test/differential/scripts/';
        runJsInputs[3]  = '--silent';
        runJsInputs[4]  = 'run';
        runJsInputs[5]  = 'differential';
        runJsInputs[6]  = 'shr';
        runJsInputs[7]  = a_val.toHexString();
        runJsInputs[8]  = a_neg.toString();
        runJsInputs[9] = bits.toString();

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
}
