import { BN } from 'bn.js';
import { ethers } from 'ethers';

const func = process.argv[2];
switch(func){
    case "add": {
        const a_val = process.argv[3].substring(2);
        const b_val = process.argv[4].substring(2);
        const a_neg = (process.argv[5] === 'true');
        const b_neg = (process.argv[6] === 'true');
        let a = new BN(a_val, 16)
        let b = new BN(b_val, 16)
        if(a_neg) a = a.mul(new BN(-1));
        if(b_neg) b = b.mul(new BN(-1));
        let res = a.add(b)
        const neg = res.isNeg()
        if(neg) res = res.abs()
        process.stdout.write(ethers.utils.defaultAbiCoder.encode(['bool', 'bytes'], [neg, ethers.BigNumber.from(res.toString())]));
        break;
    }
    case "sub": {
        const a_val = process.argv[3].substring(2);
        const b_val = process.argv[4].substring(2);
        const a_neg = (process.argv[5] === 'true');
        const b_neg = (process.argv[6] === 'true');
        let a = new BN(a_val, 16)
        let b = new BN(b_val, 16)
        if(a_neg) a = a.mul(new BN(-1));
        if(b_neg) b = b.mul(new BN(-1));
        let res = a.sub(b)
        const neg = res.isNeg()
        if(neg) res = res.abs()
        process.stdout.write(ethers.utils.defaultAbiCoder.encode(['bool', 'bytes'], [neg, ethers.BigNumber.from(res.toString())]));
        break;
    }
    case "mul": {
        const a_val = process.argv[3].substring(2);
        const b_val = process.argv[4].substring(2);
        const a_neg = (process.argv[5] === 'true');
        const b_neg = (process.argv[6] === 'true');
        let a = new BN(a_val, 16)
        let b = new BN(b_val, 16)
        if(a_neg) a = a.mul(new BN(-1));
        if(b_neg) b = b.mul(new BN(-1));
        let res = a.mul(b)
        const neg = res.isNeg()
        if(neg) res = res.abs()
        process.stdout.write(ethers.utils.defaultAbiCoder.encode(['bool', 'bytes'], [neg, ethers.BigNumber.from(res.toString())]));
        break;
    }
    case "div": {
        const a_val = process.argv[3].substring(2);
        const b_val = process.argv[4].substring(2);
        const a_neg = (process.argv[5] === 'true');
        const b_neg = (process.argv[6] === 'true');
        let a = new BN(a_val, 16)
        let b = new BN(b_val, 16)
        if(a_neg) a = a.mul(new BN(-1));
        if(b_neg) b = b.mul(new BN(-1));
        let res = a.div(b)
        const neg = res.isNeg()
        if(neg) res = res.abs()
        process.stdout.write(ethers.utils.defaultAbiCoder.encode(['bool', 'bytes'], [neg, ethers.BigNumber.from(res.toString())]));
        break;
    }
    case "invmod": {
        const a_val = process.argv[3].substring(2);
        const m_val = process.argv[4].substring(2);
        let a = new BN(a_val, 16)
        let m = new BN(m_val, 16)
        let res = a.invm(m)
        const neg = res.isNeg()
        if(neg) res = res.mul(new BN(-1))
        let valid = a.mul(res).mod(m).eq(new BN(1));
        process.stdout.write(ethers.utils.defaultAbiCoder.encode(['bool', 'bool', 'bytes'], [valid, neg, ethers.BigNumber.from(res.toString())]));
        break;
    }
    case "mod": {
        const a_val = process.argv[3].substring(2);
        const n_val = process.argv[4].substring(2);
        const a_neg = (process.argv[5] === 'true');
        let a = new BN(a_val, 16)
        let n = new BN(n_val, 16)
        if(a_neg) a = a.mul(new BN(-1));
        let res = a.umod(n)
        const neg = res.isNeg()
        if(neg) res = res.abs()
        process.stdout.write(ethers.utils.defaultAbiCoder.encode(['bool', 'bytes'], [neg, ethers.BigNumber.from(res.toString())]));
        break;
    }
    case "shl": {
        const a_val = process.argv[3].substring(2);
        const bits = Number(process.argv[4]);
        let a = new BN(a_val, 16);
        let res = a.shln(bits)
        const neg = res.isNeg()
        process.stdout.write(ethers.utils.defaultAbiCoder.encode(['bool', 'bytes'], [neg, ethers.BigNumber.from(res.toString())]));
        break;
    }
    case "shr": {
        const a_val = process.argv[3].substring(2);
        const bits = Number(process.argv[4]);
        let a = new BN(a_val, 16);
        let res = a.shrn(bits)
        const neg = res.isNeg()
        process.stdout.write(ethers.utils.defaultAbiCoder.encode(['bool', 'bytes'], [neg, ethers.BigNumber.from(res.toString())]));
        break;
    }
    case "cmp": {
        const a_val  = process.argv[3].substring(2);
        const b_val  = process.argv[4].substring(2);
        const a_neg  = (process.argv[5] === 'true');
        const b_neg  = (process.argv[6] === 'true');
        const signed = (process.argv[7] === 'true');

        let a = new BN(a_val, 16);
        let b = new BN(b_val, 16);
        if(signed){
            if(a_neg) a = a.mul(new BN(-1));
            if(b_neg) b = b.mul(new BN(-1));
        }
        let res = 0;
        if(a.gt(b)) res = 1;
        else if(a.lt(b)) res = -1;
        process.stdout.write(ethers.utils.defaultAbiCoder.encode(['int'], [res]));
        break;
    }
    case "modmul": {
        const a_val = process.argv[3].substring(2);
        const b_val = process.argv[4].substring(2);
        const n_val = process.argv[5].substring(2);
        const a_neg = (process.argv[6] === 'true');
        const b_neg = (process.argv[7] === 'true');
        let a = new BN(a_val, 16)
        let b = new BN(b_val, 16)
        let n = new BN(n_val, 16)
        if(a_neg) a = a.mul(new BN(-1));
        if(b_neg) b = b.mul(new BN(-1));
        let res = a.mul(b).umod(n)
        const neg = res.isNeg()
        if(neg) res = res.abs()
        process.stdout.write(ethers.utils.defaultAbiCoder.encode(['bool', 'bytes'], [neg, ethers.BigNumber.from(res.toString())]));
        break;
    }
    case "modexp": {
        const a_val = process.argv[3].substring(2);
        const e_val = process.argv[4].substring(2);
        const m_val = process.argv[5].substring(2);
        let a = new BN(a_val, 16)
        let e = new BN(e_val, 16)
        let m = new BN(m_val, 16)
        var reducedA = a.toRed(BN.red(m));
        var reducedRes = reducedA.redPow(e);
        var res = reducedRes.fromRed();
        const neg = res.isNeg()
        if(neg) res = res.abs()
        process.stdout.write(ethers.utils.defaultAbiCoder.encode(['bool', 'bytes'], [neg, ethers.BigNumber.from(res.toString())]));
        break;
    }
    case "iszero": {
        const a_val = process.argv[3];
        const a_neg = (process.argv[4] === 'true');
        let a = new BN(a_val, 16)
        if(a_neg) a = a.mul(new BN(-1));
        let res = a.isZero()
        process.stdout.write(ethers.utils.defaultAbiCoder.encode(['bool'], [ethers.BigNumber.from(res.toString())]));
        break;
    }
}
