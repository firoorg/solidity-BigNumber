// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import "../src/BigNumbers.sol";

contract BigNumbersTest is Test, IBigNumbers {
    using BigNumbers for *;
    bytes constant ZERO = hex"0000000000000000000000000000000000000000000000000000000000000000";
    bytes constant  ONE = hex"0000000000000000000000000000000000000000000000000000000000000001";
    bytes constant  TWO = hex"0000000000000000000000000000000000000000000000000000000000000002";
    
    function testInit() public {
        bytes memory val;
        BigNumber memory bn;

        val = hex"ffffffff";
        bn = BigNumbers._init(val, false, 36);
        assertEq(bn.val.length,  0x20);
        assertEq(bn.val,  hex"00000000000000000000000000000000000000000000000000000000ffffffff");
        assertEq(bn.neg,  false);
        assertEq(bn.bitlen,  36);

        val = hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
        bn = BigNumbers._init(val, true, 0);
        assertEq(bn.val.length,  0x20);
        assertEq(bn.val,  hex"00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");
        assertEq(bn.neg,  true);
        assertEq(bn.bitlen,  248);

        val = hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
        bn = BigNumbers._init(val, false, 256);
        assertEq(bn.val.length,  0x20);
        assertEq(bn.val,  hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");
        assertEq(bn.neg,  false);
        assertEq(bn.bitlen,  256);
    }

    function testVerify() public pure {
        BigNumber memory bn = BigNumber({
            val: hex"00000000000000000000000000000000000000000000bccc69e47d98498430b725f7ff5af5be936fb1ccde3fdcda3b0882a9082eab761e75b34da18d8923d70b481d89e2e936eecec248b3d456b580900a18bcd39b3948bc956139367b89dde7",
            neg: false,
            bitlen: 592
        });
        bn.verify();
    }

    function testFailVerifyBitlen() public pure {
        BigNumber memory bn = BigNumber({
            val: hex"00000000000000000000000000000000000000000000bccc69e47d98498430b725f7ff5af5be936fb1ccde3fdcda3b0882a9082eab761e75b34da18d8923d70b481d89e2e936eecec248b3d456b580900a18bcd39b3948bc956139367b89dde7",
            neg: false,
            bitlen: 1
        });
        bn.verify();
    }

    function testFailVerifyLength() public pure {
        BigNumber memory bn = BigNumber({
            val: hex"000000000000000000000000000000000000000000bccc69e47d98498430b725f7ff5af5be936fb1ccde3fdcda3b0882a9082eab761e75b34da18d8923d70b481d89e2e936eecec248b3d456b580900a18bcd39b3948bc956139367b89dde7",
            neg: false,
            bitlen: 592
        });
        bn.verify();
    }

    function testLengths() public {
        bytes memory val = hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
        assertEq(BigNumbers.get_bit_length(val), 256);
        val = hex"0000000000000000000000000000000000000000000000000000000000000000";
        assertEq(BigNumbers.get_bit_length(val), 0);
        val = hex"0000000000000000000000000000000000000000000000000000000000000001";
        assertEq(BigNumbers.get_bit_length(val), 1);
        val = hex"f000000000000000000000000000000000000000000000000000000000000000";
        assertEq(BigNumbers.get_bit_length(val), 256);

        assertEq(BigNumbers.get_word_length(0), 0);
        assertEq(BigNumbers.get_word_length(1), 1);
        assertEq(BigNumbers.get_word_length(1 << 200), 201);
        assertEq(BigNumbers.get_word_length((1 << 200)+1), 201);
        assertEq(BigNumbers.get_word_length(1 << 255), 256);
    }

    function testShiftRight() public {
        // shift by value greater than word length
        BigNumber memory r;
        BigNumber memory bn = BigNumber({
            val: hex"1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111",
            neg: false,
            bitlen: 1024
        });
        r = bn.shr(500);
        
        assertEq(r.val, hex"000000000000000000000000000000000000000000000000000000000000011111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111");
        assertEq(r.val.length, 0x60);
        assertEq(r.bitlen, 524); 
        assertEq(r.neg, false); 

        // shift by value greater than word length and multiple of 8
        bn = BigNumber({
            val: hex"11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111",
            neg: true,
            bitlen: 512
        });
        r = bn.shr(264); // shift right by 33 bytes

        assertEq(r.val, hex"0011111111111111111111111111111111111111111111111111111111111111");
        assertEq(r.val.length, 0x20);
        assertEq(r.bitlen, 248); 
        assertEq(r.neg, true); 

        // shift by value >= bit length
        bn = BigNumber({
            val: hex"11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111",
            neg: true,
            bitlen: 512
        });
        r = bn.shr(512);

        assertEq(r.val, hex"0000000000000000000000000000000000000000000000000000000000000000");
        assertEq(r.val.length, 0x20);
        assertEq(r.bitlen, 0); 
        assertEq(r.neg, false); 

        // shift by value with a remaining leading zero word
        bn = BigNumber({
            val: hex"00000000000000000000000000000000000000000000000000000000000011111111111111111111111111111111111111111111111111111111111111111111",
            neg: true,
            bitlen: 272
        });
        r = bn.shr(17);

        assertEq(r.val, hex"0888888888888888888888888888888888888888888888888888888888888888");
        assertEq(r.val.length, 0x20);
        assertEq(r.bitlen, 255); 
        assertEq(r.neg, true); 

        r = ((hex'ffff').init(false)).shr(192);
        assertEq(r.val.length, 0x20);
        assertEq(r.bitlen, 0); 
        assertEq(r.neg, false); 
    }

    function testShiftLeft() public {
        BigNumber memory r;
        BigNumber memory bn;
        // shift by value within this word length
        bn = BigNumber({
            val: hex"00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111",
            neg: false,
            bitlen: 496
        });
        r = bn.shl(12);

        assertEq(r.val, hex"01111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111000");
        assertEq(r.val.length, 0x40);
        assertEq(r.bitlen, 508);
        assertEq(r.neg, false);

        // shift by value within this word length and multiple of 8
        bn = BigNumber({
            val: hex"00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111",
            neg: false,
            bitlen: 496
        });
        r = bn.shl(8);

        assertEq(r.val, hex"00111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100");
        assertEq(r.val.length, 0x40);
        assertEq(r.bitlen, 504);
        assertEq(r.neg, false); 

        // shift creating extra trailing word
        bn = BigNumber({
            val: hex"00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111",
            neg: false,
            bitlen: 496
        });
        r = bn.shl(268);

        assertEq(r.val, hex"011111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000");
        assertEq(r.val.length, 0x60);
        assertEq(r.bitlen, 764);
        assertEq(r.neg, false);


        // shift creating extra trailing word and multiple of 8
        bn = BigNumber({
            val: hex"00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111",
            neg: false,
            bitlen: 496
        });
        r = bn.shl(264);

        assertEq(r.val, hex"001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000");
        assertEq(r.val.length, 0x60);
        assertEq(r.bitlen, 760);
        assertEq(r.neg, false); 

        // shift creating extra leading word
        bn = BigNumber({
            val: hex"00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111",
            neg: false,
            bitlen: 496
        });
        r = bn.shl(20);

        assertEq(r.val, hex"000000000000000000000000000000000000000000000000000000000000000111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000");
        assertEq(r.val.length, 0x60);
        assertEq(r.bitlen, 516);
        assertEq(r.neg, false); 

        // shift creating extra leading word and multiple of 8
        bn = BigNumber({
            val: hex"00001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111",
            neg: false,
            bitlen: 496
        });
        r = bn.shl(24);

        assertEq(r.val, hex"000000000000000000000000000000000000000000000000000000000000001111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111000000");
        assertEq(r.val.length, 0x60);
        assertEq(r.bitlen, 520);
        assertEq(r.neg, false); 
    }

    function testDiv() public pure {
        bytes memory _a = hex"0000";
        bytes memory _b = hex"2c44bc4694d72d924e1832fbcdbb66bf8a0fd54399212d71f7e5ffda57c22bd6f0a3fa4313a6c2c21115d6abbe16e1ba84ffdeaf6d707c4f98070bbe8f2fc35b7921e2e1897515444cb64e1dc7cf38f38f90ca4ae732fc832c34528d6d2d01562c7b71";
        BigNumber memory a = _a.init(false);
        BigNumber memory b = _b.init(true);
        BigNumber memory res = BigNumber(ZERO,false,0); 

        a.div(b, res);
    }

}
