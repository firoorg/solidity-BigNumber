// Specifically request an abstraction for BigNumber
var MockBigNumber = artifacts.require("MockBigNumber"); 
var BigNumber = artifacts.require("BigNumber"); 

const bn = require('bn.js')
const crypto = require("crypto")  
const rawtx = require("ethereumjs-tx") 
const brorand = require('brorand');
const bi = require("big-integer");

contract('MockBigNumber', function(accounts) {
  init_runs = 20; 
  for(var run=init_runs;run>0;run--){
    it("is prime function: Run " + (init_runs-run) + " - create random prime value, assert contract returns true", async function() {
        instance = await MockBigNumber.new()
        var prime_size = 128; //testing with prime value for zerocoin commitment right now.
        console.log("getting prime..")
        do {
            do {
                prime = new brorand.Rand().generate(prime_size);
                prime_bn = new bi(prime.toString('hex'), 16);
            } while(!(prime_bn.isProbablePrime())); //generate random values until we hit a probable prime (relatively fast).
        }while(!(prime_bn.isPrime())); //verifies the value is definitely prime (slow).
        console.log("Prime acquired.")

        prime_bn = new bn(prime, 16); //easier to use bn library in general apart from primality test
        //we now need to generate randomness values up to the number of bytes of the input.
        var bit_size = prime_bn.bitLength();    
        var num_randomness = bit_size >= 1300 ?  2 :
                             bit_size >=  850 ?  3 :
                             bit_size >=  650 ?  4 :
                             bit_size >=  550 ?  5 :
                             bit_size >=  450 ?  6 :
                             bit_size >=  400 ?  7 :
                             bit_size >=  350 ?  8 :
                             bit_size >=  300 ?  9 :
                             bit_size >=  250 ? 12 :
                             bit_size >=  200 ? 15 :
                             bit_size >=  150 ? 18 :
                            /* b >= 100 */ 27;

        var num_bytes = Math.ceil(prime_bn.bitLength()/8); // ceiling of bitlength / 8

        //generate 'num_randomness' random values up to bit_size-1 
        //send to contract as one value, along with num_randomness, and decode in assembly.

        var randomness = "";

        var mask = Math.pow(2,(prime_bn.bitLength()-1)%8)-1;

        for(var i=0;i<num_randomness; i++){
            n = new brorand.Rand().generate(num_bytes);
            n[0] &= mask; //remove leading zeros outside of our range
            randomness = randomness.concat(n.toString('hex'));
        }

        var prime_val = prime_bn.toString('hex')

        var prime_enc = "0x" + (((prime_val.length % 64) != 0) ? "0".repeat(64 - (prime_val.length % 64)) : "") + prime_val //add any leading zeroes (not present from BN) 

        var randomness_enc = "0x" + randomness

     let result = await instance.mock_is_prime.call(prime_enc, bit_size, randomness_enc, num_randomness)
      .then(function(actual_result) {
            assert.equal(true, actual_result, "returned prime value did not match.");
      })       


  });
it("Division function: Run " + (init_runs-run) + " - create random inputs for A and B, div to get C, pass all and assert equality from contract", async function() {
        instance = await MockBigNumber.new()

        //set values for negative.
        var a_neg = false;
        var b_neg = false;
        var result_neg = false;
        
        // grab random values for a and b, ensuring b is not 0.
        var a_zeros = "0".repeat((Math.floor(Math.random() * 31) + 1) * 2) //assuming we can have up to 31 leading zeroes.
        var a_size = ((Math.floor(Math.random() * 10) + 1) * 32) - (a_zeros.length / 2)
        var a_val = a_zeros + crypto.randomBytes(a_size).toString('hex');
        while(a_zeros.length==63 && a_val[62]=="0" && a_val[63]=="0") {
            a_val = a_val.substring(0, 62) + crypto.randomBytes(1).toString('hex') + a_val.substring(64) 
        }
        var a_bn = new bn((a_neg ? "-" : "") + a_val, 16);

        do {
            var b_zeros = "0".repeat((Math.floor(Math.random() * 31) + 1) * 2)
            var b_size = ((Math.floor(Math.random() * 10) + 1) * 32) - (b_zeros.length / 2)
            var b_val = b_zeros + crypto.randomBytes(b_size).toString('hex'); //create random hex strings with leading zeroes
            while(b_zeros.length==63 && b_val[62]=="0" && b_val[63]=="0") {
                b_val = b_val.substring(0, 62) + crypto.randomBytes(1).toString('hex') + b_val.substring(64) 
            }
        var b_bn = new bn((b_neg ? "-" : "") + b_val, 16);   
        } while(b_bn==0);

        //get result (a/b) and value as string
        var result_bn = new bn(a_bn.div(b_bn));
        var result_val = result_bn.toString('hex');

        //get msbs - encode for call.
        var a_msb = a_bn.bitLength()
        var a_msb_enc = "0".repeat(64 - a_bn.bitLength().toString(16).length) + a_bn.bitLength().toString(16)

        var b_msb = b_bn.bitLength()
        var b_msb_enc = "0".repeat(64 - b_bn.bitLength().toString(16).length) + b_bn.bitLength().toString(16)

        var result_msb = result_bn.bitLength()
        var result_msb_enc = "0".repeat(64 - result_bn.bitLength().toString(16).length) + result_bn.bitLength().toString(16)

        //encode vals for call.
        var   a_val_enc    = "0x" +   a_val
        var   b_val_enc    = "0x" +   b_val
        var result_val_enc = "0x" + ((result_val.length  % 64 != 0) ? "0".repeat(64 - (result_val.length % 64)) : "") + result_val //add any leading zeroes (not present from BN)

        //encode 'extra' as neg||msb (calling separate values not possible so we encode neg and msb into one parameter)
        var      a_extra_enc = "0x" + "0".repeat(63) +    ((  a_neg==true) ? "1" : "0") +   a_msb_enc;
        var      b_extra_enc = "0x" + "0".repeat(63) +    ((  b_neg==true) ? "1" : "0") +   b_msb_enc;
        var result_extra_enc = "0x" + "0".repeat(63) + ((result_neg==true) ? "1" : "0") + result_msb_enc;

        var expected_result_msb = result_bn.bitLength();
                   
      let result = await instance.mock_bn_div.call(a_val_enc, a_extra_enc, b_val_enc, b_extra_enc, result_val_enc, result_extra_enc)
      .then(function(actual_result) {
        assert.equal(result_val_enc, actual_result[0], "returned val did not match.\na_val: " + a_val + "\nb_val: " + b_val + "\nresult_val: " + result_val_enc + "\na_extra: " + a_extra_enc + "\nb_extra_enc: " + b_extra_enc + "\nresult_extra_enc: " + result_extra_enc + "\n");
        assert.equal(result_neg,     actual_result[1], "returned neg did not match.");
        assert.equal(expected_result_msb, actual_result[2].valueOf(), "returned msb did not match.");
      })
  });

 it("Modular inverse function: Run " + (init_runs-run) + " - create inputs for base and modulus, get result, pass all, assert contract returns user_result (base*user_result)%modulus==1", async function() {
        instance = await MockBigNumber.new()
        //get hex strings for a and m.
        var a_zeros = "0".repeat((Math.floor(Math.random() * 31) + 1) * 2) //assuming we can have up to 31 leading zeroes.
        var a_size = ((Math.floor(Math.random() * 10) + 1) * 32) - (a_zeros.length / 2)
        var a_val = a_zeros + crypto.randomBytes(a_size).toString('hex');
        while(a_zeros.length==63 && a_val[62]=="0" && a_val[63]=="0") {
            a_val = a_val.substring(0, 62) + crypto.randomBytes(1).toString('hex') + a_val.substring(64) 
        }

        var m_zeros = "0".repeat((Math.floor(Math.random() * 31) + 1) * 2)
        var m_size = ((Math.floor(Math.random() * 10) + 1) * 32) - (m_zeros.length / 2)
        var m_val = m_zeros + crypto.randomBytes(m_size).toString('hex'); //create random hex strings with leading zeroes
        while(m_zeros.length==63 && m_val[62]=="0" && m_val[63]=="0") {
            m_val = m_val.substring(0, 62) + crypto.randomBytes(1).toString('hex') + m_val.substring(64) 
        }

        //convert to bignums.
        var a_bn = new bn(a_val, 16);
        var m_bn = new bn(m_val, 16);

        //get n ((a)(n) == 1 mod m)
        var n_bn = bn(a_bn.invm(m_bn)); 

        //we're generating random values. if no modinverse exists, we have a revert case.
        console.log(a_bn.mul(n_bn).mod(m_bn));
        var valid = (a_bn.mul(n_bn).mod(m_bn) == 1);

        //get encoded values for call
        var a_val_enc = "0x" + a_val
        var m_val_enc = "0x" + m_val
        var n_val_enc = n_bn.toString('hex')        
        n_val_enc = "0x" + ((n_val_enc.length  % 64 != 0) ? "0".repeat(64 - (n_val_enc.length % 64)) : "") + n_val_enc //add any leading zeroes (not present from BN after calculation)
        
        //get msbs
        var a_msb_enc = a_bn.bitLength()
        var m_msb_enc = m_bn.bitLength()
        var n_msb_enc = n_bn.bitLength()

        var one = "0x0000000000000000000000000000000000000000000000000000000000000001";

        //set false value for result
        var n_neg_enc = false;

        if(!valid){ //if modinverse does not exist, execute this first block (ie. catch 'revert'). otherwise call as normal.
           let result = await instance.mock_modinverse.call(a_val_enc, a_msb_enc, m_val_enc, m_msb_enc, n_val_enc, n_msb_enc)
            .then(function(actual_result) {
                assert(false, 'revert encountered');
                return true;
            },
            function(e){
                assert.match(e, /VM Exception[a-zA-Z0-9 ]+: revert/, "revert caught.");
            });
        }
        else {
            let result = await instance.mock_modinverse.call(a_val_enc, a_msb_enc, m_val_enc, m_msb_enc, n_val_enc, n_msb_enc)
            .then(function(actual_result) {
                //console.log(actual_result);
                assert.equal(n_val_enc, actual_result[0], "returned val did not match. \na_val: " + a_val_enc + "\nm_val: " + m_val_enc);
                assert.equal(n_neg_enc, actual_result[1], "returned neg did not match.");
                assert.equal(n_msb_enc, actual_result[2].valueOf(), "returned msb did not match. \na_val: " + a_val_enc + "\nm_val: " + m_val_enc + "\nn_val: " + n_val_enc);
                //return true;
            });
      }
    });

it("Modmul function: Run " + (init_runs-run) + " - create random inputs for A and B, sub to get C, assert equality from contract", async function() {
        instance = await MockBigNumber.new()
        var a_zeros = "0".repeat((Math.floor(Math.random() * 31) + 1) * 2) //assuming we can have up to 31 leading zeroes.
        var a_size = ((Math.floor(Math.random() * 10) + 1) * 32) - (a_zeros.length / 2)
        var a_val = a_zeros + crypto.randomBytes(a_size).toString('hex');
        while(a_zeros.length==63 && a_val[62]=="0" && a_val[63]=="0") {
            a_val = a_val.substring(0, 62) + crypto.randomBytes(1).toString('hex') + a_val.substring(64) 
        }

        var b_zeros = "0".repeat((Math.floor(Math.random() * 31) + 1) * 2)
        var b_size = ((Math.floor(Math.random() * 10) + 1) * 32) - (b_zeros.length / 2)
        var b_val = b_zeros + crypto.randomBytes(b_size).toString('hex'); //create random hex strings with leading zeroes
        while(b_zeros.length==63 && b_val[62]=="0" && b_val[63]=="0") {
            b_val = b_val.substring(0, 62) + crypto.randomBytes(1).toString('hex') + b_val.substring(64) 
        }

        var mod_zeros = "0".repeat((Math.floor(Math.random() * 31) + 1) * 2)
        var mod_size = ((Math.floor(Math.random() * 10) + 1) * 32) - (mod_zeros.length / 2)
        var mod_val = mod_zeros + crypto.randomBytes(mod_size).toString('hex'); //create random hex strings with leading zeroes
        while(mod_zeros.length==63 && mod_val[62]=="0" && mod_val[63]=="0") {
            mod_val = mod_val.substring(0, 62) + crypto.randomBytes(1).toString('hex') + mod_val.substring(64) 
        }

        var a_neg = Math.random() >= 0.5;
        var b_neg = Math.random() >= 0.5; //generates a random boolean.
        var mod_neg = Math.random() >= 0.5; //generates a random boolean.

        var a_bn = new bn((a_neg ? "-" : "") + a_val, 16);
        var b_bn = new bn((b_neg ? "-" : "") + b_val, 16);
        var mod_bn = new bn((mod_neg ? "-" : "") + mod_val, 16);
        
        var res_bn = a_bn.mul(b_bn).mod(mod_bn);  //calculates modmul.

        expected_result_val = res_bn.toString('hex')
        if(expected_result_val[0] == '-'){
          expected_result_neg = true;
          expected_result_val = expected_result_val.substr(1)
        }else expected_result_neg = false;
      
        var a_msb = a_bn.bitLength()
        var a_msb_enc = "0".repeat(64 - a_bn.bitLength().toString(16).length) + a_bn.bitLength().toString(16)

        var b_msb = b_bn.bitLength()
        var b_msb_enc = "0".repeat(64 - b_bn.bitLength().toString(16).length) + b_bn.bitLength().toString(16)

        var mod_msb = mod_bn.bitLength()
        var mod_msb_enc = "0".repeat(64 - mod_bn.bitLength().toString(16).length) + mod_bn.bitLength().toString(16)

        var   a_val_enc = "0x" +   a_val
        var   b_val_enc = "0x" +   b_val
        var mod_val_enc = "0x" + mod_val

        var   a_extra_enc = "0x" + "0".repeat(63) + ((  a_neg==true) ? "1" : "0") +   a_msb_enc;
        var   b_extra_enc = "0x" + "0".repeat(63) + ((  b_neg==true) ? "1" : "0") +   b_msb_enc;
        var mod_extra_enc = "0x" + "0".repeat(63) + ((mod_neg==true) ? "1" : "0") + mod_msb_enc;

        
        expected_result_val = "0x" + ((expected_result_val.length  % 64 != 0) ? "0".repeat(64 - (expected_result_val.length % 64)) : "") + expected_result_val //add any leading zeroes (not present from BN)
        var expected_result_msb = res_bn.bitLength()
                   
      instance.mock_modmul.call(a_val_enc, a_extra_enc, b_val_enc, b_extra_enc, mod_val_enc, mod_extra_enc).then(function(actual_result) {
        assert.equal(expected_result_val, actual_result[0], "returned val did not match. \na_val:\n" + a_val + "\nb_val:\n" + b_val + "\nmod_val:\n" + mod_val + "\na_msb:\n" + a_msb_enc + "\nb_msb:\n" + b_msb_enc + "\nmod_msb:\n" + mod_msb_enc + "\na_neg:\n" + a_neg + "\nb_neg:\n" + b_neg + "\nmod_neg:\n" + mod_neg + "\n");
        assert.equal(expected_result_neg, actual_result[1], "returned neg did not match. \na_val:\n" + a_val + "\nb_val:\n" + b_val + "\na_msb:\n" + a_msb_enc + "\nb_msb:\n" + b_msb_enc + "\n" + "\na_neg:\n" + a_neg + "\nb_neg:\n" + b_neg + "\n");
        assert.equal(expected_result_msb, actual_result[2].valueOf(), "returned msb did not match. \nresult: " + expected_result_val + "\na_val:\n" + a_val + "\nb_val:\n" + b_val + "\nmod_val:\n" + mod_val + "\na_msb:\n" + a_msb_enc + "\nb_msb:\n" + b_msb_enc + "\nb_msb:\n" + mod_msb_enc + "\n" + "\na_neg:\n" + a_neg + "\nb_neg:\n" + b_neg + "\n");
      })
  });

  it("Modexp function: Run " + (init_runs-run) + " - create random inputs for A and B, sub to get C, assert equality from contract", async function() {
        instance = await MockBigNumber.new()
        
        a_val = "6776352c8bcd1d6e6b7f5b825a2acebb7e77abbb7cc5ef55b1913d7ce0010f6ae20886db111d14c94bc045b5f145037481d8398998af7906086fb7dc25eab544bedac235f2a7fb6c540443495791eb3fd800719f075488c66c7f5028e5cbc21c974b2d365ff35f9ea1c7209de05b4465510cf03536ae6477fab203c86e50a4db";
        b_val = "6e3b4d7e8980aba295c68e45e2f891d8e86a554185288c01f9008a86a7c96f05a7ef679958ac34d62744dd72af23212d10209cae7554c94fe5623c1b5d0af4e0d5af46cad9dc3860c2018acf16d9a7e14156cdccbf74ae93479e239292b7d04e343954b8519c61aeb4144a6d5f07c075602936a89980ae25f2d07938906d2849";
        mod_val = "dc769afd130157452b8d1c8bc5f123b1d0d4aa830a511803f201150d4f92de0b4fdecf32b15869ac4e89bae55e46425a2041395ceaa9929fcac47836ba15e9c1ab5e8d95b3b870c18403159e2db34fc282ad9b997ee95d268f3c4725256fa09c6872a970a338c35d682894dabe0f80eac0526d5133015c4be5a0f27120da5093";
        
        a_bn = new bn(a_val,16)
        b_bn = new bn(b_val,16)
        mod_bn = new bn(mod_val,16)

        a_neg = false
        b_neg = false
        mod_neg = false

        var res_bn = a_bn.toRed(bn.red(mod_bn)).redPow(b_bn).fromRed(); //calculates modexp.

        expected_result_val = res_bn.toString('hex')
        if(expected_result_val[0] == '-'){
          expected_result_neg = true;
          expected_result_val = expected_result_val.substr(1)
        }else expected_result_neg = false;
      
        var a_msb = a_bn.bitLength()
        var a_msb_enc = "0".repeat(64 - a_bn.bitLength().toString(16).length) + a_bn.bitLength().toString(16)

        var b_msb = b_bn.bitLength()
        var b_msb_enc = "0".repeat(64 - b_bn.bitLength().toString(16).length) + b_bn.bitLength().toString(16)

        var mod_msb = mod_bn.bitLength()
        var mod_msb_enc = "0".repeat(64 - mod_bn.bitLength().toString(16).length) + mod_bn.bitLength().toString(16)

        var   a_val_enc = "0x" + a_val
        var   b_val_enc = "0x" + b_val
        var mod_val_enc = "0x" + mod_val

        var   a_extra_enc = "0x" + "0".repeat(63) + ((  a_neg==true) ? "1" : "0") +   a_msb_enc;
        var   b_extra_enc = "0x" + "0".repeat(63) + ((  b_neg==true) ? "1" : "0") +   b_msb_enc;
        var mod_extra_enc = "0x" + "0".repeat(63) + ((mod_neg==true) ? "1" : "0") + mod_msb_enc;

        console.log("a_val_enc:" + a_val_enc);
        console.log("b_val_enc:" + b_val_enc);
        console.log("mod_val_enc:" + mod_val_enc);

        
        expected_result_val = "0x" + ((expected_result_val.length  % 64 != 0) ? "0".repeat(64 - (expected_result_val.length % 64)) : "") + expected_result_val //add any leading zeroes (not present from BN)
        var expected_result_msb = res_bn.bitLength()
                   
      instance.mock_modexp.call(a_val_enc, a_extra_enc, b_val_enc, b_extra_enc, mod_val_enc, mod_extra_enc).then(function(actual_result) {
        assert.equal(expected_result_val, actual_result[0], "returned val did not match. \na_val:\n" + a_val + "\nb_val:\n" + b_val + "\nmod_val:\n" + mod_val + "\na_msb:\n" + a_msb_enc + "\nb_msb:\n" + b_msb_enc + "\nmod_msb:\n" + mod_msb_enc + "\na_neg:\n" + a_neg + "\nb_neg:\n" + b_neg + "\nmod_neg:\n" + mod_neg + "\n");
        assert.equal(expected_result_neg, actual_result[1], "returned neg did not match. \na_val:\n" + a_val + "\nb_val:\n" + b_val + "\na_msb:\n" + a_msb_enc + "\nb_msb:\n" + b_msb_enc + "\n" + "\na_neg:\n" + a_neg + "\nb_neg:\n" + b_neg + "\n");
        assert.equal(expected_result_msb, actual_result[2].valueOf(), "returned msb did not match. \nresult: " + expected_result_val + "\na_val:\n" + a_val + "\nb_val:\n" + b_val + "\nmod_val:\n" + b_val + "\na_msb:\n" + a_msb_enc + "\nb_msb:\n" + b_msb_enc + "\n" + "\na_neg:\n" + a_neg + "\nb_neg:\n" + b_neg + "\n");
      })
  });

  it("Modexp function: Run " + (init_runs-run) + " - create random inputs for A and B, sub to get C, assert equality from contract", async function() {
        instance = await MockBigNumber.new()
        var a_zeros = "0".repeat((Math.floor(Math.random() * 31) + 1) * 2) //assuming we can have up to 31 leading zeroes.
        var a_size = ((Math.floor(Math.random() * 6) + 1) * 32) - (a_zeros.length / 2)
        var a_val = a_zeros + crypto.randomBytes(a_size).toString('hex');
        while(a_zeros.length==63 && a_val[62]=="0" && a_val[63]=="0") {
            a_val = a_val.substring(0, 62) + crypto.randomBytes(1).toString('hex') + a_val.substring(64) 
        }

        var b_zeros = "0".repeat((Math.floor(Math.random() * 31) + 1) * 2)
        var b_size = ((Math.floor(Math.random() * 6) + 1) * 32) - (b_zeros.length / 2)
        var b_val = b_zeros + crypto.randomBytes(b_size).toString('hex'); //create random hex strings with leading zeroes
        while(b_zeros.length==63 && b_val[62]=="0" && b_val[63]=="0") {
            b_val = b_val.substring(0, 62) + crypto.randomBytes(1).toString('hex') + b_val.substring(64) 
        }

        var mod_zeros = "0".repeat((Math.floor(Math.random() * 31) + 1) * 2)
        var mod_size = ((Math.floor(Math.random() * 6) + 1) * 32) - (mod_zeros.length / 2)
        var mod_val = mod_zeros + crypto.randomBytes(mod_size).toString('hex'); //create random hex strings with leading zeroes
        while(mod_zeros.length==63 && mod_val[62]=="0" && mod_val[63]=="0") {
            mod_val = mod_val.substring(0, 62) + crypto.randomBytes(1).toString('hex') + mod_val.substring(64) 
        }
        // var a_neg = Math.random() >= 0.5;
        // var b_neg = Math.random() >= 0.5;
        // var mod_neg = Math.random() >= 0.5; //generates a random boolean.

        var a_neg = false;
        var b_neg = false;
        var mod_neg = false; //TODO all positive for now - need to implement inverse function to deal with negative exponent.

        var a_bn = new bn((a_neg ? "-" : "") + a_val, 16);
        var b_bn = new bn((b_neg ? "-" : "") + b_val, 16);
        var mod_bn = new bn((mod_neg ? "-" : "") + mod_val, 16);
        
        var res_bn = a_bn.toRed(bn.red(mod_bn)).redPow(b_bn).fromRed(); //calculates modexp.

        expected_result_val = res_bn.toString('hex')
        if(expected_result_val[0] == '-'){
          expected_result_neg = true;
          expected_result_val = expected_result_val.substr(1)
        }else expected_result_neg = false;
      
        var a_msb = a_bn.bitLength()
        var a_msb_enc = "0".repeat(64 - a_bn.bitLength().toString(16).length) + a_bn.bitLength().toString(16)

        var b_msb = b_bn.bitLength()
        var b_msb_enc = "0".repeat(64 - b_bn.bitLength().toString(16).length) + b_bn.bitLength().toString(16)

        var mod_msb = mod_bn.bitLength()
        var mod_msb_enc = "0".repeat(64 - mod_bn.bitLength().toString(16).length) + mod_bn.bitLength().toString(16)

        var   a_val_enc = "0x" +   a_val
        var   b_val_enc = "0x" +   b_val
        var mod_val_enc = "0x" + mod_val

        var   a_extra_enc = "0x" + "0".repeat(63) + ((  a_neg==true) ? "1" : "0") +   a_msb_enc;
        var   b_extra_enc = "0x" + "0".repeat(63) + ((  b_neg==true) ? "1" : "0") +   b_msb_enc;
        var mod_extra_enc = "0x" + "0".repeat(63) + ((mod_neg==true) ? "1" : "0") + mod_msb_enc;

        console.log("a_val_enc:" + a_val_enc);
        console.log("b_val_enc:" + b_val_enc);
        console.log("mod_val_enc:" + mod_val_enc);

        
        expected_result_val = "0x" + ((expected_result_val.length  % 64 != 0) ? "0".repeat(64 - (expected_result_val.length % 64)) : "") + expected_result_val //add any leading zeroes (not present from BN)
        var expected_result_msb = res_bn.bitLength()
                   
      instance.mock_modexp.call(a_val_enc, a_extra_enc, b_val_enc, b_extra_enc, mod_val_enc, mod_extra_enc).then(function(actual_result) {
        assert.equal(expected_result_val, actual_result[0], "returned val did not match. \na_val:\n" + a_val + "\nb_val:\n" + b_val + "\nmod_val:\n" + mod_val + "\na_msb:\n" + a_msb_enc + "\nb_msb:\n" + b_msb_enc + "\nmod_msb:\n" + mod_msb_enc + "\na_neg:\n" + a_neg + "\nb_neg:\n" + b_neg + "\nmod_neg:\n" + mod_neg + "\n");
        assert.equal(expected_result_neg, actual_result[1], "returned neg did not match. \na_val:\n" + a_val + "\nb_val:\n" + b_val + "\na_msb:\n" + a_msb_enc + "\nb_msb:\n" + b_msb_enc + "\n" + "\na_neg:\n" + a_neg + "\nb_neg:\n" + b_neg + "\n");
        assert.equal(expected_result_msb, actual_result[2].valueOf(), "returned msb did not match. \nresult: " + expected_result_val + "\na_val:\n" + a_val + "\nb_val:\n" + b_val + "\nmod_val:\n" + b_val + "\na_msb:\n" + a_msb_enc + "\nb_msb:\n" + b_msb_enc + "\n" + "\na_neg:\n" + a_neg + "\nb_neg:\n" + b_neg + "\n");
      })
  });
  
  it("Multiplication function: Run " + (init_runs-run) + " - create random inputs for A and B, sub to get C, assert equality from contract", async function() {
        instance = await MockBigNumber.new()
        var a_zeros = "0".repeat((Math.floor(Math.random() * 31) + 1) * 2) //assuming we can have up to 31 leading zeroes.
        var a_size = ((Math.floor(Math.random() * 10) + 1) * 32) - (a_zeros.length / 2)
        var a_val = a_zeros + crypto.randomBytes(a_size).toString('hex');
        while(a_zeros.length==63 && a_val[62]=="0" && a_val[63]=="0") {
            a_val = a_val.substring(0, 62) + crypto.randomBytes(1).toString('hex') + a_val.substring(64) 
        }

        var b_zeros = "0".repeat((Math.floor(Math.random() * 31) + 1) * 2)
        var b_size = ((Math.floor(Math.random() * 10) + 1) * 32) - (b_zeros.length / 2)
        var b_val = b_zeros + crypto.randomBytes(b_size).toString('hex'); //create random hex strings with leading zeroes
        while(b_zeros.length==63 && b_val[62]=="0" && b_val[63]=="0") {
            b_val = b_val.substring(0, 62) + crypto.randomBytes(1).toString('hex') + b_val.substring(64) 
        }

        var a_neg = Math.random() >= 0.5;
        var b_neg = Math.random() >= 0.5; //generates a random boolean.  

        var a_bn = new bn((a_neg ? "-" : "") + a_val, 16);
        var b_bn = new bn((b_neg ? "-" : "") + b_val, 16);

        var res_bn = a_bn.mul(a_bn);

        var a_val_enc = "0x" + a_val
        var b_val_enc = "0x" + b_val

        expected_result_val = res_bn.toString('hex')
        if(expected_result_val[0] == '-'){
          expected_result_neg = true;
          expected_result_val = expected_result_val.substr(1)
        }else expected_result_neg = false;
      
        var a_msb_enc = a_bn.bitLength()
        var b_msb_enc = b_bn.bitLength()
        var expected_result_msb = res_bn.bitLength()
        
        expected_result_val = "0x" + ((expected_result_val.length  % 64 != 0) ? "0".repeat(64 - (expected_result_val.length % 64)) : "") + expected_result_val //add any leading zeroes (not present from BN)
                   
      await instance.mock_bn_mul.call(a_val_enc, a_neg, a_msb_enc, a_val_enc, a_neg, a_msb_enc).then(function(actual_result) {
        assert.equal(expected_result_val, actual_result[0], "returned val did not match. \na_val:\n" + a_val + "\nb_val:\n" + b_val + "\na_msb:\n" + a_msb_enc + "\nb_msb:\n" + b_msb_enc + "\na_neg:\n" + a_neg + "\nb_neg:\n" + b_neg  );
        assert.equal(expected_result_neg, actual_result[1], "returned neg did not match. \na_val:\n" + a_val + "\nb_val:\n" + b_val + "\na_msb:\n" + a_msb_enc + "\nb_msb:\n" + b_msb_enc + "\n" + "\na_neg:\n" + a_neg + "\nb_neg:\n" + b_neg + "\n");
        assert.equal(expected_result_msb, actual_result[2].valueOf(), "returned msb did not match. \nresult: " + expected_result_val + "\na_val:\n" + a_val + "\nb_val:\n" + b_val + "\na_msb:\n" + a_msb_enc + "\nb_msb:\n" + b_msb_enc + "\n" + "\na_neg:\n" + a_neg + "\nb_neg:\n" + b_neg + "\n");
      })
    });

    it("Addition function: Run " + (init_runs-run) + " - create random inputs for A and B, add to get C, assert equality from contract", async function() {
        instance = await MockBigNumber.new()
        var a_zeros = "0".repeat((Math.floor(Math.random() * 31) + 1) * 2) //assuming we can have up to 31 leading zeroes.
        var a_size = ((Math.floor(Math.random() * 10) + 1) * 32) - (a_zeros.length / 2)
        var a_val = a_zeros + crypto.randomBytes(a_size).toString('hex');
        while(a_zeros.length==63 && a_val[62]=="0" && a_val[63]=="0") {
            a_val = a_val.substring(0, 62) + crypto.randomBytes(1).toString('hex') + a_val.substring(64) 
        }

        var b_zeros = "0".repeat((Math.floor(Math.random() * 31) + 1) * 2)
        var b_size = ((Math.floor(Math.random() * 10) + 1) * 32) - (b_zeros.length / 2)
        var b_val = b_zeros + crypto.randomBytes(b_size).toString('hex'); //create random hex strings with leading zeroes
        while(b_zeros.length==63 && b_val[62]=="0" && b_val[63]=="0") {
            b_val = b_val.substring(0, 62) + crypto.randomBytes(1).toString('hex') + b_val.substring(64) 
        }

        var a_neg = Math.random() >= 0.5;
        var b_neg = Math.random() >= 0.5; //generates a random boolean.  

        var a_bn = new bn((a_neg ? "-" : "") + a_val, 16);
        var b_bn = new bn((b_neg ? "-" : "") + b_val, 16);

        var res_bn = a_bn.add(b_bn);

        var a_val_enc = "0x" + a_val
        var b_val_enc = "0x" + b_val

        expected_result_val = res_bn.toString('hex')
        if(expected_result_val[0] == '-'){
          expected_result_neg = true;
          expected_result_val = expected_result_val.substr(1)
        }else expected_result_neg = false;
      
        var a_msb_enc = a_bn.bitLength()
        var b_msb_enc = b_bn.bitLength()
        var expected_result_msb = res_bn.bitLength()
        
        expected_result_val = "0x" + ((expected_result_val.length  % 64 != 0) ? "0".repeat(64 - (expected_result_val.length % 64)) : "") + expected_result_val //add any leading zeroes (not present from BN)
                   
      instance.mock_bn_add.call(a_val_enc, a_neg, a_msb_enc, b_val_enc, b_neg, b_msb_enc).then(function(actual_result) {
        assert.equal(expected_result_val, actual_result[0], "returned val did not match. \na_val:\n" + a_val + "\nb_val:\n" + b_val + "\na_msb:\n" + a_msb_enc + "\nb_msb:\n" + b_msb_enc + "\na_neg:\n" + a_neg + "\nb_neg:\n" + b_neg  );
        assert.equal(expected_result_neg, actual_result[1], "returned neg did not match. \na_val:\n" + a_val + "\nb_val:\n" + b_val + "\na_msb:\n" + a_msb_enc + "\nb_msb:\n" + b_msb_enc + "\n" + "\na_neg:\n" + a_neg + "\nb_neg:\n" + b_neg + "\n");
        assert.equal(expected_result_msb, actual_result[2].valueOf(), "returned msb did not match. \nresult: " + expected_result_val + "\na_val:\n" + a_val + "\nb_val:\n" + b_val + "\na_msb:\n" + a_msb_enc + "\nb_msb:\n" + b_msb_enc + "\n" + "\na_neg:\n" + a_neg + "\nb_neg:\n" + b_neg + "\n");
      })
    });

  it("Subtraction function: Run " + (init_runs-run) + " - create random inputs for A and B, sub to get C, assert equality from contract", async function() {
        instance = await MockBigNumber.new()
        var a_zeros = "0".repeat((Math.floor(Math.random() * 31) + 1) * 2) //assuming we can have up to 31 leading zeroes.
        var a_size = ((Math.floor(Math.random() * 10) + 1) * 32) - (a_zeros.length / 2)
        var a_val = a_zeros + crypto.randomBytes(a_size).toString('hex');
        while(a_zeros.length==63 && a_val[62]=="0" && a_val[63]=="0") {
            a_val = a_val.substring(0, 62) + crypto.randomBytes(1).toString('hex') + a_val.substring(64) 
        }

        var b_zeros = "0".repeat((Math.floor(Math.random() * 31) + 1) * 2)
        var b_size = ((Math.floor(Math.random() * 10) + 1) * 32) - (b_zeros.length / 2)
        var b_val = b_zeros + crypto.randomBytes(b_size).toString('hex'); //create random hex strings with leading zeroes
        while(b_zeros.length==63 && b_val[62]=="0" && b_val[63]=="0") {
            b_val = b_val.substring(0, 62) + crypto.randomBytes(1).toString('hex') + b_val.substring(64) 
        }

        var a_neg = Math.random() >= 0.5;
        var b_neg = Math.random() >= 0.5; //generates a random boolean.  

        var a_bn = new bn((a_neg ? "-" : "") + a_val, 16);
        var b_bn = new bn((b_neg ? "-" : "") + b_val, 16);

        var res_bn = a_bn.sub(b_bn);

        var a_val_enc = "0x" + a_val
        var b_val_enc = "0x" + b_val

        expected_result_val = res_bn.toString('hex')
        if(expected_result_val[0] == '-'){
          expected_result_neg = true;
          expected_result_val = expected_result_val.substr(1)
        }else expected_result_neg = false;
      
        var a_msb_enc = a_bn.bitLength()
        var b_msb_enc = b_bn.bitLength()
        var expected_result_msb = res_bn.bitLength()
        
        expected_result_val = "0x" + ((expected_result_val.length  % 64 != 0) ? "0".repeat(64 - (expected_result_val.length % 64)) : "") + expected_result_val //add any leading zeroes (not present from BN)

                   
      instance.mock_bn_sub.call(a_val_enc, a_neg, a_msb_enc, b_val_enc, b_neg, b_msb_enc).then(function(actual_result) {
        assert.equal(expected_result_val, actual_result[0], "returned val did not match. \na_val:\n" + a_val + "\nb_val:\n" + b_val + "\na_msb:\n" + a_msb_enc + "\nb_msb:\n" + b_msb_enc + "\na_neg:\n" + a_neg + "\nb_neg:\n" + b_neg  );
        assert.equal(expected_result_neg, actual_result[1], "returned neg did not match. \na_val:\n" + a_val + "\nb_val:\n" + b_val + "\na_msb:\n" + a_msb_enc + "\nb_msb:\n" + b_msb_enc + "\n" + "\na_neg:\n" + a_neg + "\nb_neg:\n" + b_neg + "\n");
        assert.equal(expected_result_msb, actual_result[2].valueOf(), "returned msb did not match. \nresult: " + expected_result_val + "\na_val:\n" + a_val + "\nb_val:\n" + b_val + "\na_msb:\n" + a_msb_enc + "\nb_msb:\n" + b_msb_enc + "\n" + "\na_neg:\n" + a_neg + "\nb_neg:\n" + b_neg + "\n");
      })
     });
     }
});