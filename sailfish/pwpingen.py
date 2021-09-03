#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# $ pwpingen.py $
#
# Author: Tomi Ollila -- too ät iki piste fi
#
#	Copyright (c) 2021 Tomi Ollila
#	    All rights reserved
#
# Created: Fri 30 Jul 2021 18:20:46 EEST too
# Last modified: Thu 02 Sep 2021 15:19:32 +0300 too

# SPDX-License-Identifier: BSD 2-Clause "Simplified" License

# in this particular program it might be more useful to just have the .py
from sys import dont_write_bytecode
dont_write_bytecode = True

from hashlib import blake2b

uc = 'ACDEFGHJKLMNPQRTUVWXYZ'
lc = 'abcdefghijkmnpqrstuvwxyz'
nm = '0123456789'
em = '%+,-./:='
a1l = uc + lc + nm + em
a2l = 'abcdefghijklmnopqrstuvwxyz234679'


def mkbytegen(bytez):
    seed = b'PwPiNGeN:2\n' + bytez
    while True:
        dgst = blake2b(seed).digest()
        for b in dgst[:32]: yield b
        seed = dgst
        pass
    pass


def getrandbval(bytegen, p1l, p2l, pnl):
    b = next(bytegen)
    p1l.append(a1l[b & 0x3f])
    p2l.append(a2l[b & 0x1f])
    if b < 250: pnl.append(b % 10)
    return b


def allgrps(bytegen, pnl):
    p3l = [ ]
    for r in range(5):
        while True:
            myl = [ ]
            for a in range(8):
                b = next(bytegen)
                if b < 250: pnl.append(b % 10)
                myl.append(a1l[b & 0x3f])
                pass
            t = [0] * 4
            for c in myl:
                if c in lc: t[0] = 1; continue
                if c in uc: t[1] = 1; continue
                if c in nm: t[2] = 1; continue
                if c in em: t[3] = 1; continue
                pass
            if all(t): break
            pass
        p3l.append(''.join(myl))
        pass
    return p3l


def pwpingen(bytez):
    # input: bytes, output: tuple of (7-bit) ascii strings
    bytegen = mkbytegen(bytez)
    p1l = [ ]
    p2l = [ ]
    pnl = [ ]

    for _ in range(40): getrandbval(bytegen, p1l, p2l, pnl)
    pw3s = allgrps(bytegen, pnl)

    pw1s = []
    for i in range(5):
        pw1s.append(f'{p1l[i*8+0]}{p1l[i*8+1]}{p1l[i*8+2]}{p1l[i*8+3]}'
                    f'{p1l[i*8+4]}{p1l[i*8+5]}{p1l[i*8+6]}{p1l[i*8+7]}')
        pass
    pw2s = [ ]
    for i in range(5):
        pw2s.append(f'{p2l[i*8+0]}{p2l[i*8+1]}{p2l[i*8+2]}{p2l[i*8+3]}'
                    f'{p2l[i*8+4]}{p2l[i*8+5]}{p2l[i*8+6]}{p2l[i*8+7]}')
        pass
    pins = [ ]
    for i in range(9):
        pins.append(f'{pnl[i*4]}{pnl[i*4+1]}{pnl[i*4+2]}{pnl[i*4+3]}')
        pass
    return ' '.join(pw1s), ' '.join(pw3s), ' '.join(pw2s), ' '.join(pins)


def pwpingen_call(text):
    import pyotherside
    pw, pw3, pw2, pin = pwpingen(text.encode())
    pyotherside.send('update', pw, pw3, pw2, pin)
    pass


if __name__ == '__main__':
    import sys
    if len(sys.argv) == 1:
        # as simple as possible, use stty -echo; ./pwpingen... to disable echo
        text = sys.stdin.readline().rstrip()
    else:
        text = ' '.join(sys.argv[1:])
        pass
    pw, pw3, pw2, pin = pwpingen(text.encode())
    print()
    print(pw)
    print(pw3)
    print(pw2)
    print(pin)
    print()
    pass
