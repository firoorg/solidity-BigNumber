// Specifically request an abstraction for BigNumber
var MockBigNumber = artifacts.require("MockBigNumber"); 
var BigNumber = artifacts.require("BigNumber"); 

const bn = require('bn.js')
const crypto = require("crypto")  
const rawtx = require("ethereumjs-tx") 
const brorand = require('brorand');
const bi = require("big-integer");

contract('MockBigNumber', function(accounts) {
  init_runs = 10; 
  for(var run=init_runs;run>0;run--){

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