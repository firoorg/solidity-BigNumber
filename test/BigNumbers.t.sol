// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/BigNumbers.sol";
import "../src/utils/Crypto.sol";

contract BigNumbersTest is Test {
    using BigNumbers for *;
    using Crypto for *;

    function testRSA() public {
        bytes memory message = hex'68656c6c6f20776f726c64'; // "hello world" in hex

        BigNumber memory signature = hex"079bed733b48d69bdb03076cb17d9809072a5a765460bc72072d687dba492afe951d75b814f561f253ee5cc0f3d703b6eab5b5df635b03a5437c0a5c179309812f5b5c97650361c645bc99f806054de21eb187bc0a704ed38d3d4c2871a117c19b6da7e9a3d808481c46b22652d15b899ad3792da5419e50ee38759560002388".init(false);

        BigNumber memory exponent = hex"010001".init(false);

        BigNumber memory  modulus = hex"df3edde009b96bc5b03b48bd73fe70a3ad20eaf624d0dc1ba121a45cc739893741b7cf82acf1c91573ec8266538997c6699760148de57e54983191eca0176f518e547b85fe0bb7d9e150df19eee734cf5338219c7f8f7b13b39f5384179f62c135e544cb70be7505751f34568e06981095aeec4f3a887639718a3e11d48c240d".init(false);

        assertEq(Crypto.pkcs1Sha256VerifyRaw(message, signature, exponent, modulus), 0);
    }

    function testInit() public {
        bytes memory val;
        BigNumber memory bn;

        val = hex"ffffffff";
        bn = BigNumbers.init(val, false, 36);
        assertEq(bn.val.length,  0x20);
        assertEq(bn.val,  hex"00000000000000000000000000000000000000000000000000000000ffffffff");
        assertEq(bn.neg,  false);
        assertEq(bn.bitlen,  36);

        val = hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
        bn = BigNumbers.init(val, true);
        assertEq(bn.val.length,  0x20);
        assertEq(bn.val,  hex"00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");
        assertEq(bn.neg,  true);
        assertEq(bn.bitlen,  248);

        val = hex"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
        bn = BigNumbers.init(val, false);
        assertEq(bn.val.length,  0x20);
        assertEq(bn.val,  hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");
        assertEq(bn.neg,  false);
        assertEq(bn.bitlen,  256);
    }

    function testVerify() public pure {
        BigNumber memory bn;
        bn = BigNumber({
            val: hex"00000000000000000000000000000000000000000000bccc69e47d98498430b725f7ff5af5be936fb1ccde3fdcda3b0882a9082eab761e75b34da18d8923d70b481d89e2e936eecec248b3d456b580900a18bcd39b3948bc956139367b89dde7",
            neg: false,
            bitlen: 592
        });
        bn.verify();

        bn = BigNumber({
            val: hex"8000000000000000000000000000000000000000000000000000000000000000",
            neg: false,
            bitlen: 256
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
        BigNumber memory val = hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff".init(false);
        assertEq(BigNumbers.bitLength(val), 256);
        val = hex"0000000000000000000000000000000000000000000000000000000000000000".init(false);
        assertEq(BigNumbers.bitLength(val), 0);
        val = hex"0000000000000000000000000000000000000000000000000000000000000001".init(false);
        assertEq(BigNumbers.bitLength(val), 1);
        val = hex"f000000000000000000000000000000000000000000000000000000000000000".init(false);
        assertEq(BigNumbers.bitLength(val), 256);

        assertEq(BigNumbers.bitLength(0), 0);
        assertEq(BigNumbers.bitLength(1), 1);
        assertEq(BigNumbers.bitLength(1 << 200), 201);
        assertEq(BigNumbers.bitLength((1 << 200)+1), 201);
        assertEq(BigNumbers.bitLength(1 << 255), 256);
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
            neg: false,
            bitlen: 512
        });
        r = bn.shr(264); // shift right by 33 bytes

        assertEq(r.val, hex"0011111111111111111111111111111111111111111111111111111111111111");
        assertEq(r.val.length, 0x20);
        assertEq(r.bitlen, 248); 
        assertEq(r.neg, false); 

        // shift by value >= bit length
        bn = BigNumber({
            val: hex"11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111",
            neg: false,
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
            neg: false,
            bitlen: 272
        });
        r = bn.shr(17);

        assertEq(r.val, hex"0888888888888888888888888888888888888888888888888888888888888888");
        assertEq(r.val.length, 0x20);
        assertEq(r.bitlen, 255); 
        assertEq(r.neg, false); 

        r = ((hex'ffff').init(false)).shr(192);
        assertEq(r.val.length, 0x20);
        assertEq(r.bitlen, 0); 
        assertEq(r.neg, false); 
    }

    function testShiftLeft() public {

        // fails: [0x8000000000000000000000000000000000000000000000000000000000000000, 0]
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

    function testDiv() public view {
        bytes memory _a = hex"c44185bd565bf73657762992dd9825b34c44c95f3845fa188bf98d3f36db0b38cdad5a8be77f36baf8467826c4574b2e3cbdc1a4d4b0fc4ff667434a6ac644e7d8349833f80b82e901";
        bytes memory _b = hex"4807722751c4327f377e03";
        bytes memory _res = hex"02b98463de4a24865849566e8398b60d2596843283dbff493f37f0efb8f738cd9f06dedf61a7b6177f41732cfb722c585edab0e6bfcdaf7a0f7df79756732a";
        BigNumber memory a = _a.init(true);
        BigNumber memory b = _b.init(false);
        BigNumber memory res = _res.init(true); 

        a.divVerify(b, res);
    }

    function testModMul() public {
        bytes memory _a = hex"1f78";
        bytes memory _b = hex"0309";
        bytes memory _m = hex"3178";
        BigNumber memory a = _a.init(false);
        BigNumber memory b = _b.init(false);
        BigNumber memory m = _m.init(false);
        BigNumber memory res = a.modmul(b, m);
    
        bytes memory _g = hex"04";
        bytes memory _x = hex"03";
        bytes memory _p = hex"0800";
        BigNumber memory g = _g.init(false);
        BigNumber memory x = _x.init(false);
        BigNumber memory p = _p.init(false);
    
        BigNumber memory newRes = g.modmul(x, p);

        assertEq(newRes.val, hex"0c");
        assertEq(newRes.bitlen, 4);
        assertEq(newRes.neg, false);
    }

    function testMul() public {
        BigNumber memory a = hex"00000000000000000000000000000000000000000000000000000000000000003a1eb8ecccb55eb177961acd4c55f91ef6c4170e945167941c74977784dd6b9e2487c70e96fac3618a421b447ad1ab9374a860c6abba75a084894be7d4effb1921608b187b7cfc65e5daa562e66b3567668c5411cf8646c44e3794834d81e259fb0ab419e7f3b8604a0cfbe2e4e7a7e54b0cf98fb04741796f8be7a63f56f827fa8f321e0cb7a81ae02c3c9093ba34db4c65b8f41bfca39ccf0d421c281688ff18463d09bff3aec8ea60bd8e98773afe513d5aec79a11ab4b668315ec11cbf36a8cc2ef9c06b2e7aaa52c009b1f75e2bbf3e695bb5d026fbdca56622bb7d8427ce9158666fec53a5409de3f1c774c1c6a47a64c715b85038169e49970e224cbf98e1ef4d6c0577b887820a1ed7226739efdfc8f21520e1561e23f6596d4bbfc3b558c1d8bf06ada55b649a33a1f9e034cb9885c93dc1d0d8c58d98214087da1ada5a83ef4e59fe5bc718347af72d0f7438fffe17f45177876e51df89e7cb9bd93e928002920dc45366b4b68dab6ef6665b6bbae5aa81a49559434ebe16ddc1249ded47867fb779fe464c2234cb4c89275a2c6bc735e623e678de4ae5d3e87b3aff5b5c85bc7139addefff6f39af790f75be6a14d85cd34976429b81b9428272976bf55a590dc7c25b4576846fbd1b8121820a7284e580de9012f6d8aee2a0700d26664cb92c0cf00d0509bf5406d122d69a01746031ef3a34f36ecbf1d9e3acd24c01b0b9273cf8d5b8561b4d2b03b66de8d630a02422cbb4449d4bb14c6a03777a3c9333c9e190da63372dc586c12add8cf77924a8e76143e6d1be24165d05f05e0796f24dbfaa48bcbadf424db7d8b37b73aec5d9cbda41a7f202ed16508fad952219514419dca7067fda497d2c6d274fb60c5578eb3a493ae3ca0e4e5e3d8e4e6e6b7ad1c70e4897e2631f223f45bfc154a1c9c9c4e5d803473ee26b56fa45bd58358a6e86bc9e138d1a608a398939977899db7a4f17e9a176626e7f33e6a5420b1b4bf056d9f7422b020d75833a728b8496256b599a5634e4f29b52660795a778dace7cb3aeec09e6dbf972f2803a008314e3cf18230579200e390bb04e7".init(false, 6142);

        BigNumber memory b = hex"00000000000000000000000000000000000000000000000000000000000000004cff437bbe7c242e9254ce4fb0191d1b64586f79c7504f2447713f2408a797740f535e74854c4e64bdbf7040e5831c776892698e30ab990060e541e00462a58d6c42e4b066006939975f17251b7779460c00306c68af3530458d04df217a659055dfe61bcfee8d5da8b6d20832bbd87f7a35c4ed709f65609562eff75cfe1cd4944fd6a12c7224852123cce3775e13ea9baeb72d0fb2b742af5ea6de5cad0b40f5f62dd4d6a26eaf135e9c96a3f812856117d61379e0a6f468e76af8707cbc67a2e35a75c0cf750d823aac4a45bdd9831c9d62978727f009b96d0c14ba7b66c43a8d1419df0f9a7218495f0fca6ab02a2517c4f3e56aa840c20b56e90007a46b4f80ba2ebf11b01bf4a1b43c4a0d7b6418ff29f025802ef84642232fbb78a6ff53bb2f5b237a26a2d26ff4eb2c8511674b029101c0a3972c8e71fb67008a004b0005a045b4c2ff1641682cded289719b955c46ec39710c103a477565f70ea2663402320a04c0eebf84069bc7b166df8618635fdb9ece51760eb05c5888cdf34c46f7bfde13d9a32887e1a814d79c835e758ffd7b0d657f1d52f049ccb0b0827bb407b59d918028c50c8f882611f68107423e232dfb6534ad54861cc35e42d22ed4e204364642cc4984735e58e4ed31b10056a28be2a033bec4c6137cd8b99a865bfdb804efeabd3ca5ee8aa0dda14722c2dc5b8081b32b135a62980170c1ae5c5efc5126987632d7b6e089c7d9bf9f625324e8996ac4ec53316d263406d58f6c9830d6a47fb2ee8fb548a224d776e7dc4e3099fbfdc296e4924d48aa18813910d6e6d3d953aee65c9fe906ae2c544bb6354a57c3f4851daebedafad128942956c4073cb781b0e9d9d97e195b71ed310b8e71e4d56e4df8aa3eafda6cec80e4c29556aee87de93a55ee47b6994181072699c9498247d1b93c69b6d87b00b5de1b08167122f7f2c9b2057b8a4e3f8dd41d7961a25456d14117b9776dd1eaf65aaa2b2243014e413f5931fd470f0953b956e37a8f3561b10b207c09f7d77bfa7eb46e5b5ebe2527003b7828f72337ffbf84f02c45c35fd640b79ed6d8dacbe44531".init(false, 6143);
    
        BigNumber memory res = a.mul(b);

        BigNumber memory expectedRes = hex"117b12d2a30d90780c94b1e4cca184946ce13f68a1efe8c5fc57e5d253cf1ddde4e13c8a17830c20caa12395de287187f19da2cbf9579cbcbad81cbcd390f3e0711894551edd48a855b134e007e09c48f9e53f9a97b84c11079c41b3408554f9c5b870420bf82deb10f841e3d9c7966962b7c8889a99484438ea7f294736da2bd9cf952fbf737a160b1fcee9d6c13ee28eba7cc8358fca401ab095a4317d9f2f7c3ae17979cd96995efae9f0f9b2b2f9e766233d983faca337b2c7e0942ffb456c1506edf3fed40d8ee9d41f0b7c6560c3c0ef017466ade93e8ea5d11492b6064d0aeb704041d0c051b804dadababb8a890055171423c5a1a7e61d7bece23ba9e8f9cbbff2685c1db5fe12471bc73ab8d5268935fd6d05990244c652cc7f9777777884fa0a5943fac2225ee9666a4b892553f8fe25d94bf36a3f8d119cbc93a5e016c9a76822473e2cf0ca32644730bc72164532731b3e3cd2b8aa425430d9c91aa9b2017158f1fbef0b7e7a27dc6107bdbdb3c46b4e10f21a79c06fa15df20568eaeaaba4ecb61e93fd5bddbe46cc4ad41fe6348efd1ce4c896ac1fff3bd8f8277e5640737719ff1358ee6b3bb2e0617a986d9155f0ec7c059ef29f04eeb3d81396d95ce97f96d6545884ae3e09df97118602726ba3bf58291fc840555f98cb1c72175277201201f0f3f98a8d46a75995aef560ce9c707364fc89e58a2a65c37ff4cc317506281593c25874fd35b7336f2166d4e94e888bad7e94ae1c9e0f26b9fcfb4c4eebbfa3462e0acf71ef43382a0233560411b5add36accbfb1662fe0226eeca0650f291cfd39228f14c6ac33d32b2ffdb7267b83423c224f52ea998bcdec0e52b4356797be39042f867f862ce5447dbbec7db58d765be145c6cc8e1f29d3cca962e05bcf5e56be33c99e4cfcca3a1710f607ae908f0d5c173b7f3958c50f5ec914d19402296a60ad55603e1c981c6b00d70e0c89ad3c73c826b7d7ab2e45c4af7bc19a51e1cf0fcb2081f9f03fb3bc2e9cdd59ff99914073b75d416b5102e0b4228101febed8b61c756c8dd2eb20642cd0fb3cf107d5d5b6e04abb7b8531f25db68cffa90d406cda5aa9a9f70ed54cb835d59c1bbd99a23e1535cfeaa42dd89bec3f76b909548fce40d2f8bf903551d4f1d0248c122bb33e199c21c7e9364a86347e49a1d5305399be8e75218c1ce40477dfac74414218c7042dea15a48ebb8ef6d03368c0d66c32b2ffc121c3b6067a82b62c3c34ecf20ae5e919452eac400e3c4cafc7e322d6ae5e22dc618eae5b1efb69f9292eb32c61a213f826aefb1b2d50a3eaa95bf0074caa96df0dccbf0cfc15a09f6aa7cf086338a8099881d690a213442121a522ce1badd08445883af37f020efbbe24a532b3e4d096e9b431cd7290223f9bb45b3c5946ccf3b1bf017d27ae36b82e3426107f67b44bd0ae4aac8ae4dcdfa3617e899b21c4210e388c4b095255f3ba7fa1e44ea0ca647c1896858a94a552e09ea2bf1dacb5a336f32ab6d2e8fceda3cbe85255907c7a06ecfdda11a8db2d6d4733a19779ea87035aa3009d3b25c4ed31ec9ce57668f6ec15a4ec7c6718c0703410d9c7fad5a75bdfe9f8bd5890a04965a5d2393ea80b9508490dbb18b0c5c1fe90a252c6c6c4d75a010f02531e8dd40cc7f375fce800b3d83cff2baaf433eefd6baf8cc78e6eae8302d94dad8e9cc527e19cbc6b0445626a2641485280e9e2bc5f9b25ba4f22ac06518b99262baff360ac34bc705e9be26b7d79024c6e0f0ef5a3b73f249a0320aa617728d9143950dca21bd5b8e2f34e7e98cd77bb2ba0856e4442a6e455de6543ae079466e65bc8f79df2962e0f75fad039180062142c493354576a21405623126c41f41bbbc2c0824a4a5998035d79fe846a5627d29a25631de5a1730c9aa13736448e40699370606d349d84022eb2fb1cc09f7304a08434c771201f0bbcf847872868e97e8465a5a1d4e57b92f47f86351f7d11b00341b3208ec5ca02e5dd1c5e95041c1e60f2f5b989fad8febe8ff99b409347a45f64651694fc94640c494e366fb69f486f96511e7dd06771203b02b9b85904863ab8576eddd1dccfbc7d8c2e5c27ec5081b0d0025d6296b369a4cba650a10d86284c81e94a80ca114a8879d7305a087725fd121fc9baa6da3337".init(false);

        assertEq(res.eq(expectedRes), true);
    }
}
