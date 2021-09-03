#!/bin/sh
''':' '-*- python -*-'
exec python3 -B "$0" "$@"
exit not reached
'''
# $ test-distrib.py
#
# Author: Tomi Ollila -- too ät iki piste fi
#
#	Copyright (c) 2021 Tomi Ollila
#	    All rights reserved
#
# Created: Mon 09 Aug 2021 19:57:29 EEST too
# Last modified: Fri 03 Sep 2021 21:07:12 +0300 too

# executes pwpingen.pwpingen() 65536 times a bit changing parameter,
# expects "even" distribution of the characters, except in the second
# line (where distribution expectation differs a bit...)


import pwpingen

td = { x: 0 if x in pwpingen.lc
       else 1 if x in pwpingen.uc
       else 2 if x in pwpingen.nm
       else 3 for x in pwpingen.a1l }
td[' '] = 4 # space in returned string 4 per pw* line, 8 per pin line
td['l'] = 0 # a2l has 'l' (no 0 nor 1) -- in pw2 lines
td['o'] = 0 # a2l has 'o' (no 0 nor 1) -- in pw2 lines
#print(td)

def print_tbl(n, l, g, dd):
    l = l[33:]
    z = 0
    for c, v in enumerate(l):
        if v == 0: continue
        z += 1
        print(n, chr(c + 33), v, sep='  ', end=("\t" if (z % 5) else "\n"))
        pass
    d = g[2] // dd // 10
    g.extend(('', g[0] // d, g[1] // d, g[2] // d, g[3] // d, '', g[4] // d))
    print("\n" if (z % 5) else "", "aA0% :", g)
    pass


def test():
    pw1a = [0] * 256; pw1g = [0] * 5
    pw3a = [0] * 256; pw3g = [0] * 5
    pw2a = [0] * 256; pw2g = [0] * 5
    pina = [0] * 256; ping = [0] * 5
    for _ in range(65536):
        pw, pw3, pw2, pin = pwpingen.pwpingen(f'testoo{_}'.encode())
        for c in pw:  pw1a[ord(c)] += 1; pw1g[td[c]] += 1
        for c in pw3: pw3a[ord(c)] += 1; pw3g[td[c]] += 1
        for c in pw2: pw2a[ord(c)] += 1; pw2g[td[c]] += 1
        for c in pin: pina[ord(c)] += 1; ping[td[c]] += 1
        pass
    print_tbl(1, pw1a, pw1g, 10) # 24 22 10 8  (* 10 in aA0% output)
    print_tbl(2, pw3a, pw3g, 10)
    print_tbl(3, pw2a, pw2g, 6)  # 26 (a-z) 6 (234 679) (* 10 in aA0% output)
    print_tbl(4, pina, ping, 10)
    pass


if __name__ == '__main__':
    test()
    pass  # pylint: disable=W0107
