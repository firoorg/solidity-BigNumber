## Differential Testing
Differential testing is used to compare solidity-BigNumber's implementation to reference implementations in other languages. This directory contains the scripts needed to support this testing, as well as the differential tests themselves.

Currently, the only reference implementation is adapted from the [indutny/bn.js](https://github.com/indutny/bn.js/) implementation (The same BigNumber library used in the popular Ethereum TypeScript utilities library, [ethers.js](https://docs.ethers.io/v5/)). It is written in javascript.


### Node Version
`>=14.17`

### Setup
From the [scripts directory](./scripts/), run
```sh
npm install
npm run compile
```

### Run the differential test using foundry
Now you can run the tests.  
From the root of the solidity-BigNumber repo, run:
```sh
forge test -vvvv --ffi --mc BigNumbersDifferentialTest
```




