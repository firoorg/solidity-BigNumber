pragma solidity >=0.4.20 <0.6;

import "./BigNumber.sol";

/* 
 * mock contract to access BigNumber library for testing.
 * Library is mostly internal functions and tf. requires a contract to instantiate it to be used.
 * js file in ../test directory instantiates and uses this contract.
 */

contract MockBigNumber {
  using BigNumber for *; 
  
  //use these for printing in remix when using local node.
  event result_instance(bytes, bool, uint); 

  event result_bool(bool a);     

  event result_string(string a);

  event result_multi(bytes a, uint a_bitlen, bytes b, uint b_bitlen, bytes c, uint c_bitlen);


  function js_call() public returns(bytes,bool,uint){
    //** add hard-coded values as neccessary here ***//

    bytes memory a_val = hex"00000000000000000000000000000000000000000000bccc69e47d98498430b725f7ff5af5be936fb1ccde3fdcda3b0882a9082eab761e75b34da18d8923d70b481d89e2e936eecec248b3d456b580900a18bcd39b3948bc956139367b89dde7";
    bytes memory b_val = hex"000000000000000056a961a7c9c8b9c835ce0d5734838ad4117f92ec12646db52d5e4b5eaebd78924180a3b9378729b9a37b6705c277f1092d63605a584632f8fa3df6e85521a2d811978ddc24234a106334c55e95017705628bc89f6674a4c38e2955cc2c11092b86a12bdb250be70f90a652fb0ebe35efc3da0ad0f7142c861a4c304f2c1449caa730808b6ca7aa99d12034f6acbcbaa4a219750fdc6807e4";
    bool a_neg = false;
    bool b_neg = false;
    uint a_bitlen = 592;
    uint b_bitlen = 1215;
    (a_val,a_neg,a_bitlen) = mock_bn_add(a_val,a_neg, a_bitlen, b_val, b_neg, b_bitlen);
    result_instance(a_val,a_neg,a_bitlen);
    return(a_val,a_neg,a_bitlen);
  }

  //calls prepare_add, and by extension bn_add and bn_sub
  function mock_bn_add(bytes a_val, bool a_neg, uint a_bitlen,  bytes b_val, bool b_neg, uint b_bitlen) public returns (bytes, bool, uint){
    BigNumber.instance memory a = BigNumber.instance(a_val, a_neg, a_bitlen);
    BigNumber.instance memory b = BigNumber.instance(b_val, b_neg, b_bitlen);
    BigNumber.instance memory res = a.prepare_add(b);

    return (res.val, res.neg, res.bitlen);
  }

  //calls prepare_sub, and by extension bn_add and bn_sub
  function mock_bn_sub(bytes a_val, bool a_neg, uint a_bitlen,  bytes b_val, bool b_neg, uint b_bitlen) public returns (bytes, bool, uint){
    BigNumber.instance memory a = BigNumber.instance(a_val, a_neg, a_bitlen);
    BigNumber.instance memory b = BigNumber.instance(b_val, b_neg, b_bitlen);
    BigNumber.instance memory res = a.prepare_sub(b);

    return (res.val, res.neg, res.bitlen);
  }
  
  //calls bn_mul, and by extension add, sub and right_shift.
  function mock_bn_mul(bytes a_val, bool a_neg, uint a_bitlen,  bytes b_val, bool b_neg, uint b_bitlen) public returns(bytes, bool, uint){
    BigNumber.instance memory a = BigNumber.instance(a_val, a_neg, a_bitlen);
    BigNumber.instance memory b = BigNumber.instance(b_val, b_neg, b_bitlen);
    BigNumber.instance memory res = a.bn_mul(b);

    return (res.val, res.neg, res.bitlen);
  }

  //stack too deep error when passing in 9 distinct variables as arguments where 3 bignums are expected.
  //instead we encode each msb/neg value in a bytes array and decode.
 function mock_is_prime(bytes prime_val, uint prime_msb, bytes randomness_vals, uint count_randomness) public returns(bool){ 

      BigNumber.instance memory prime;
      BigNumber.instance[3] memory randomness;

      prime.val = prime_val;
      prime.bitlen = prime_msb;
      prime.neg = false;

      //now decode randomness vals into count_randomness chucks.
      uint randomness_ptr;
      assembly {randomness_ptr := add(randomness_vals,0x20) } //start of randomness vals

      uint randomness_length_base = randomness_vals.length/count_randomness;
      uint offset = (0x20 - ((randomness_length%0x20)==0 ? 0x20 : (randomness_length%0x20)));
      uint randomness_length = randomness_length_base + offset;

      bytes memory val;
      for(uint i=0;i<count_randomness;i++){
        assembly { 
          val := mload(0x40)
          let success := call(450, 0x4, 0, randomness_ptr, randomness_length_base, add(add(val,0x20), offset), randomness_length_base) //copy to new mem location.       
          mstore(val, randomness_length_base) //store length of chunk.
          mstore(0x40, add(add(val,0x20),randomness_length)) //deref mem pointer.
          randomness_ptr :=add(randomness_ptr,randomness_length_base)
        }
        randomness[i].val = val; //assign val to randomness.
        randomness[i].bitlen = BigNumber.get_bit_length(val); 
        randomness[i].neg = false;
      }

      bool res = BigNumber.is_prime(prime, randomness);
      result_bool(res);
      return res;
  }

  //stack too deep error when passing in 9 distinct variables as arguments where 3 bignums are expected.
  //instead we encode each bitlen/neg value in a bytes array and decode.
  function mock_modexp(bytes a_val, bytes a_extra, bytes b_val, bytes b_extra, bytes mod_val, bytes mod_extra) public returns(bytes, bool, uint){    
      BigNumber.instance memory a;
      BigNumber.instance memory b;
      BigNumber.instance memory mod;
    
      uint neg;
      uint bitlen;
      
      assembly {
         neg := mload(add(a_extra,0x20))
         bitlen := mload(add(a_extra,0x40))
      }
      
      a.val = a_val;
      a.bitlen = bitlen;
      a.neg = (neg==1) ? true : false;
      
      assembly {
         neg := mload(add(b_extra,0x20))
         bitlen := mload(add(b_extra,0x40))
      }
      
      b.val = b_val;
      b.bitlen = bitlen;
      b.neg = (neg==1) ? true : false;
      
      assembly {
         neg := mload(add(mod_extra,0x20))
         bitlen := mload(add(mod_extra,0x40))
      }
      
      mod.val = mod_val;
      mod.bitlen = bitlen;
      mod.neg = (neg==1) ? true : false;
    
      BigNumber.instance memory res = a.prepare_modexp(b,mod);
      
      return (res.val, res.neg, res.bitlen);
  }

  //stack too deep error when passing in 9 distinct variables as arguments where 3 bignums are expected.
  //instead we encode each bitlen/neg value in a bytes array and decode.
  function mock_bn_div(bytes a_val, bytes a_extra, bytes b_val, bytes b_extra, bytes res_val, bytes res_extra) public returns(bytes, bool, uint){    
      BigNumber.instance memory a;
      BigNumber.instance memory b;
      BigNumber.instance memory expected;
    
      uint neg;
      uint bitlen;
      
      assembly {
         neg := mload(add(a_extra,0x20))
         bitlen := mload(add(a_extra,0x40))
      }
      
      a.val = a_val;
      a.bitlen = bitlen;
      a.neg = (neg==1) ? true : false;
      
      assembly {
         neg := mload(add(b_extra,0x20))
         bitlen := mload(add(b_extra,0x40))
      }
      
      b.val = b_val;
      b.bitlen = bitlen;
      b.neg = (neg==1) ? true : false;
      
      assembly {
         neg := mload(add(res_extra,0x20))
         bitlen := mload(add(res_extra,0x40))
      }
      
      expected.val = res_val;
      expected.bitlen = bitlen;
      expected.neg = (neg==1) ? true : false;
    
      BigNumber.instance memory res = a.bn_div(b,expected);
      
      return (res.val, res.neg, res.bitlen);
  }

  //stack too deep error when passing in 9 distinct variables as arguments where 3 bignums are expected.
  //instead we encode each bitlen/neg value in a bytes array and decode.
  function mock_modinverse(bytes a_val, uint a_bitlen, bytes m_val, uint m_bitlen, bytes n_val, uint n_bitlen) public returns(bytes, bool, uint){    
      BigNumber.instance memory a;
      BigNumber.instance memory m;
      BigNumber.instance memory n;

      a.val = a_val;
      a.bitlen = a_bitlen;
      a.neg = false;

      m.val = m_val;
      m.bitlen = m_bitlen;
      m.neg = false;

      n.val = n_val;
      n.bitlen = n_bitlen;
      n.neg = false;
    
      BigNumber.instance memory res = a.mod_inverse(m,n);
      
      return (res.val, res.neg, res.bitlen);
  }

  //stack too deep error when passing in 9 distinct variables as arguments where 3 bignums are expected.
  //instead we encode each bitlen/neg value in a bytes array and decode.
  function mock_modmul(bytes a_val, bytes a_extra, bytes b_val, bytes b_extra, bytes mod_val, bytes mod_extra) public returns(bytes, bool, uint){    
      BigNumber.instance memory a;
      BigNumber.instance memory b;
      BigNumber.instance memory mod;
    
      uint neg;
      uint bitlen;
      
      assembly {
         neg := mload(add(a_extra,0x20))
         bitlen := mload(add(a_extra,0x40))
      }
      
      a.val = a_val;
      a.bitlen = bitlen;
      a.neg = (neg==1) ? true : false;
      
      assembly {
         neg := mload(add(b_extra,0x20))
         bitlen := mload(add(b_extra,0x40))
      }
      
      b.val = b_val;
      b.bitlen = bitlen;
      b.neg = (neg==1) ? true : false;
      
      assembly {
         neg := mload(add(mod_extra,0x20))
         bitlen := mload(add(mod_extra,0x40))
      }
      
      mod.val = mod_val;
      mod.bitlen = bitlen;
      mod.neg = (neg==1) ? true : false;
    
      BigNumber.instance memory res = a.modmul(b,mod);
      
      return (res.val, res.neg, res.bitlen);
  }
}