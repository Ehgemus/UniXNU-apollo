#!/usr/bin/env python3
# SPDX-License-Identifier: BSD-2-Clause-Patent
"""UniXNU's emit_prelink with the iOS 16.5 (20F66) Libm constant block added to its catalogue.

emit_prelink refuses any word in a kext's __TEXT_EXEC that decodes as a PC-relative
instruction with a target outside the kernelcache, unless the word lies in a catalogued
block of inline data (complete prefix, size and SHA-256 identity). In the iOS 16.5
iPhone10,3 kernelcache (sha256 e6fa7559...fdad5), com.apple.kec.Libm __TEXT_EXEC
(va 0xfffffff005b8d000) has one such block that the catalogue does not know yet:

  offset 0x1054-0x1520 (1228 bytes): float and double constants, starting right after the
  RET at 0x1050 and ending right before the next function's stp x29, x30, [sp, #-0x10]!
  at 0x1520 (the last word, 0x151c, is zero padding). Libm's own code reads it only through
  ADR and LDR (literal) from 0xc90-0x1024; no direct branch lands in it. It holds the 8 words
  that stopped the prelink: 0x11cc, 0x11dc, 0x11ec, 0x11fc, 0x1490, 0x14a0, 0x14d4, 0x14ec.

It matches the boundary rule of UniXNU's scripts/audit-target-libm-inline-data.py (RET before,
fd7bbfa9 after) and is the iOS 16.5 counterpart of the second iPadOS pool (0xf60-0x1440,
1248 bytes). Run from the build tree as kits/apollo/prelink/emit_prelink_ios16_5.py.
"""
import os
from pathlib import Path
import sys

IOS_16_5_LIBM_POOLS = (
    ('0000807f0000004100008040db0f493f', 1228, '73df5b757c53532583e3686b7d93df11ec1f5dd8c201d05502654a7812cc385f'),
)

# kits/apollo links to this repository's package/, so find XnuPrelink through the unresolved path.
kits = Path(os.path.abspath(sys.argv[0])).parents[2]
sys.path.insert(0, str(kits / 'XnuPrelink'))
import emit_prelink  # noqa: E402

emit_prelink.MATH_LITERAL_POOLS = emit_prelink.MATH_LITERAL_POOLS + IOS_16_5_LIBM_POOLS

if __name__ == '__main__':
    emit_prelink.main()
