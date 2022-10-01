"use strict";
exports.__esModule = true;
var ethers_1 = require("ethers");
var func = process.argv[2];
switch (func) {
    case "add": {
        var a_val = process.argv[3];
        var b_val = process.argv[4];
        var a_neg = process.argv[5];
        var b_neg = process.argv[6];
        var a = ethers_1.ethers.BigNumber.from(a_val);
        var b = ethers_1.ethers.BigNumber.from(b_val);
        if (a_neg)
            a = a.mul(-1);
        if (b_neg)
            b = b.mul(-1);
        var res = a.add(b);
        var neg = res.isNegative();
        if (neg)
            res = res.mul(-1);
        process.stdout.write(ethers_1.ethers.utils.defaultAbiCoder.encode(['bool', 'bytes'], [neg, res]));
    }
}
