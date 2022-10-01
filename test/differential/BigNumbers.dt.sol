pragma solidity ^0.8.16;

import "../../src/BigNumbers.sol";
import "./util/Strings.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

contract BigNumbersDifferentialTest is Test, IBigNumbers {
    using BigNumbers for *;
    using {Strings.toHexString} for bytes;
    using {Strings.toString} for bool;

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

        assertEq(res.neg, js_res.neg);
        assertEq(res.val, js_res.val);
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

        assertEq(res.neg, js_res.neg);
        assertEq(res.val, js_res.val);
    }
}
