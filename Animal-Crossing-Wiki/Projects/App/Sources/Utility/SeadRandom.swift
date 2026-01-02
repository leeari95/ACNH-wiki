//
//  SeadRandom.swift
//  ACNH-wiki
//
//  Created by Ari on 12/28/25.
//

import Foundation

/// 동물의 숲에서 사용하는 난수 생성기 (Xorshift 알고리즘)
/// 원본: https://github.com/simontime/Resead
final class SeadRandom {
    private var context: [UInt32] = [0, 0, 0, 0]

    init() {
        initialize(seed: 42069)
    }

    init(seed: UInt32) {
        initialize(seed: seed)
    }

    init(seed1: UInt32, seed2: UInt32, seed3: UInt32, seed4: UInt32) {
        initialize(seed1: seed1, seed2: seed2, seed3: seed3, seed4: seed4)
    }

    func initialize(seed: UInt32) {
        context[0] = 0x6C078965 &* (seed ^ (seed >> 30)) &+ 1
        context[1] = 0x6C078965 &* (context[0] ^ (context[0] >> 30)) &+ 2
        context[2] = 0x6C078965 &* (context[1] ^ (context[1] >> 30)) &+ 3
        context[3] = 0x6C078965 &* (context[2] ^ (context[2] >> 30)) &+ 4
    }

    func initialize(seed1: UInt32, seed2: UInt32, seed3: UInt32, seed4: UInt32) {
        var s1 = seed1
        var s2 = seed2
        var s3 = seed3
        var s4 = seed4

        if (s1 | s2 | s3 | s4) == 0 {
            s1 = 1
            s2 = 0x6C078967
            s3 = 0x714ACB41
            s4 = 0x48077044
        }

        context[0] = s1
        context[1] = s2
        context[2] = s3
        context[3] = s4
    }

    func getU32() -> UInt32 {
        let n = context[0] ^ (context[0] << 11)

        context[0] = context[1]
        context[1] = context[2]
        context[2] = context[3]
        context[3] = n ^ (n >> 8) ^ context[3] ^ (context[3] >> 19)

        return context[3]
    }

    func getBool() -> Bool {
        return (getU32() & 0x80000000) != 0
    }

    func getInt(min: Int, max: Int) -> Int {
        let range = UInt64(max - min + 1)
        let random = UInt64(getU32())
        return Int((random &* range) >> 32) + min
    }

    func getFloat(min: Float, max: Float) -> Float {
        let val: UInt32 = 0x3F800000 | (getU32() >> 9)
        let fval = Float(bitPattern: val)
        return min + ((fval - 1.0) * (max - min))
    }
}
