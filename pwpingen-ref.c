#if 0 /* -*- mode: c; c-file-style: "stroustrup"; tab-width: 8; -*-
 set -euf; trg=${0##*''/}; trg=${trg%.c}; test ! -e "$trg" || rm "$trg"
 WARN="-Wall -Wextra -Wstrict-prototypes -Wformat=2" # -pedantic
 WARN="$WARN -Wcast-qual -Wpointer-arith" # -Wfloat-equal #-Werror
 WARN="$WARN -Wcast-align -Wwrite-strings -Wshadow" # -Wconversion
 WARN="$WARN -Waggregate-return -Wold-style-definition -Wredundant-decls"
 WARN="$WARN -Wbad-function-cast -Wnested-externs -Wmissing-include-dirs"
 WARN="$WARN -Wmissing-prototypes -Wmissing-declarations -Wlogical-op"
 WARN="$WARN -Woverlength-strings -Winline -Wundef -Wvla -Wpadded"
 case ${1-} in '') set x -O2; shift; esac
 #case ${1-} in '') set x -ggdb; shift; esac
 set -x; exec ${CC:-gcc} -std=c99 $WARN "$@" -o "$trg" "$0"
 exit $?
 */
#endif
/*
 * $ pwpingen-ref.c $
 *
 * Author: Tomi Ollila -- too ät iki piste fi
 *
 *      Copyright (c) 2021 Tomi Ollila
 *          All rights reserved
 *
 * Created: Fri 13 Aug 2021 19:20:17 EEST too
 * Last modified: Sun 15 Aug 2021 10:59:44 +0300 too
 */

/*
 * This is sample reference implementation of pwpingen in C; produces the
 * same password and pin strings as the python3 version.
 * As of such, this is not supported much. E.g. currently only little endian
 * architecture is supported (due to the blake2b implementation which is
 * very raw port -- done for self-education purposes; one could replace it
 * with one of the supported ones found around...).
 * This file (pwpingen-ref.c) is released under
 * SPDX-License-Identifier: MIT
 * mostly due to the port of blake2c code found in
 * argon2pure.py by Bas Westerbaan <bas@westerbaan.name>
 */
/*
 : compile this by executing; sh pwpingen-ref.c
*/

#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <assert.h>

// gcc -dM -E -xc /dev/null | grep ORDER // or clang...
#ifndef __BYTE_ORDER__
#include <endian.h>
#define __BYTE_ORDER__ BYTE_ORDER
#define __ORDER_LITTLE_ENDIAN__ LITTLE_ENDIAN
#endif

#if __BYTE_ORDER__ != __ORDER_LITTLE_ENDIAN__
#error Sorry, (currently) only LITTLE ENDIAN supported...
#endif

const uint64_t IV[8] = {
    0x6a09e667f3bcc908, 0xbb67ae8584caa73b,
    0x3c6ef372fe94f82b, 0xa54ff53a5f1d36f1,
    0x510e527fade682d1, 0x9b05688c2b3e6c1f,
    0x1f83d9abfb41bd6b, 0x5be0cd19137e2179
};

const uint8_t SIGMA[12][16] = {
    {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15},
    {14,10,4,8,9,15,13,6,1,12,0,2,11,7,5,3},
    {11,8,12,0,5,2,15,13,10,14,3,6,7,1,9,4},
    {7,9,3,1,13,12,11,14,2,6,5,10,4,0,15,8},
    {9,0,5,7,2,4,10,15,14,1,11,12,6,8,3,13},
    {2,12,6,10,0,11,8,3,4,13,7,5,15,14,1,9},
    {12,5,1,15,14,13,4,10,0,7,6,3,9,2,8,11},
    {13,11,7,14,12,1,3,9,5,0,15,4,8,6,2,10},
    {6,15,14,9,11,3,0,8,12,2,13,7,1,4,10,5},
    {10,2,8,4,7,6,1,5,15,11,9,14,3,12,13,0},
    {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15},
    {14,10,4,8,9,15,13,6,1,12,0,2,11,7,5,3}
};

//#pragma GCC diagnostic push
//#pragma GCC diagnostic ignored "-Wpadded"
struct blake2b_ctx {
    unsigned int digest_length;
    char buf[128];
    int buflen;
    uint64_t h[8];
    uint64_t t[2];
    uint64_t f[1];
    uint64_t N;
    //bool finalized;
};
//#pragma GCC diagnostic pop

void blake2b_init(struct blake2b_ctx * ctx, unsigned int digest_length);
void blake2b_init(struct blake2b_ctx * ctx, unsigned int digest_length)
{
    memset(ctx, 0, sizeof (*ctx));
    ctx->digest_length = digest_length;
    for (int i = 0; i < 8; i++)
        ctx->h[i] = IV[i];
    ctx->h[0] ^= (0x0000000001010000 | digest_length);
}

static void _G(uint64_t * v, const uint64_t * m, /**/ uint8_t r, uint8_t i,
               uint8_t a, uint8_t b, uint8_t c, uint8_t d)
{
    uint64_t tmp, va = v[a], vb = v[b], vc = v[c], vd = v[d];
    va = (va + vb + m[SIGMA[r][2*i]]);
    tmp = vd ^ va;
    vd = (tmp >> 32) | (tmp << 32);
    vc = (vc + vd);
    tmp = vb ^ vc;
    vb = (tmp >> 24) | (tmp << 40);
    va = (va + vb + m[SIGMA[r][2*i+1]]);
    tmp = vd ^ va;
    vd = (tmp >> 16) | (tmp << 48);
    vc = (vc + vd);
    tmp = vb ^ vc;
    vb = (tmp >> 63) | (tmp << 1);
    v[a] = va; v[b] = vb; v[c] = vc; v[d] = vd;
}

static void _compress(struct blake2b_ctx * ctx, const char * data, uint8_t len)
{
    ctx->N += len;
    if (ctx->N < len)
        ctx->t[1] += 1;
    uint64_t v[16];
    memcpy(v, ctx->h, sizeof ctx->h);
    memcpy(&v[8], IV, sizeof IV);
    v[12] ^= /*ctx->t[0]; */ ctx->N;
    v[13] ^= ctx->t[1];
    v[14] ^= ctx->f[0];
    //v[15] ^= ctx->f[1];
    __auto_type m = (const uint64_t *)data;
    //for (int i = 0; i < 16; i++) printf("%lu ", v[i]); printf("\n");
    for (int r = 0; r < 12; r++) {
        _G(v, m, r, 0, 0, 4, 8, 12);
        _G(v, m, r, 1, 1, 5, 9, 13);
        _G(v, m, r, 2, 2, 6, 10, 14);
        _G(v, m, r, 3, 3, 7, 11, 15);
        _G(v, m, r, 4, 0, 5, 10, 15);
        _G(v, m, r, 5, 1, 6, 11, 12);
        _G(v, m, r, 6, 2, 7, 8, 13);
        _G(v, m, r, 7, 3, 4, 9, 14);
    }
    for (int i = 0; i < 8; i++)
        ctx->h[i] = ctx->h[i] ^ v[i] ^ v[i+8];
}

void blake2b_update(struct blake2b_ctx * ctx,
                    const char * data, uint64_t len);
void blake2b_update(struct blake2b_ctx * ctx,
                    const char * data, uint64_t len)
{
    uint64_t l = ctx->buflen + len; // XXX may wrap... when len ~ 2**64-127+
    while (l > 128) {
        int d = 128 - ctx->buflen;
        memcpy(ctx->buf + ctx->buflen, data, d);
        ctx->buflen = 0;
        _compress(ctx, ctx->buf, 128);
        data += d;
        l -= 128;
    }
    memcpy(ctx->buf + ctx->buflen, data, l - ctx->buflen);
    ctx->buflen = l;
}

void blake2b_final(struct blake2b_ctx * ctx);
void blake2b_final(struct blake2b_ctx * ctx)
{
    memset(ctx->buf + ctx->buflen, 0, 128 - ctx->buflen);
    ctx->f[0] = 0xffffffffffffffff;
    _compress(ctx, ctx->buf, ctx->buflen);
}

static uint8_t nextbyte(struct blake2b_ctx * ctx)
{
    uint8_t * h = (uint8_t *)ctx->h;
    //for (int i = 0; i < 64; i++) { printf("%02x", h[i]); } printf("\n");
    if (ctx->buflen == 32) {
        char buf[64];
        memcpy(buf, h, 64);
        blake2b_init(ctx, 64);
        blake2b_update(ctx, buf, 64);
        blake2b_final(ctx);
        ctx->buflen = 0;
    }
    return h[ctx->buflen++];
}

const char uc[] = \
    "ACDEFGHJKLMNPQRTUVWXYZ" \
    "abcdefghijkmnpqrstuvwxyz" \
    "0123456789" "%+,-./:=";
const char * const lc = uc + 22;
const char * const nm = lc + 24;
const char * const em = nm + 10;
const char * const a1l = uc;
const char a2l[] = "abcdefghijklmnopqrstuvwxyz234679";


static int allgrps(struct blake2b_ctx * ctx, char * p3l, char * pnl, int pl)
{
    for (int i = 0; i < 5; i++) {
        while (1) {
            int z = i * 9;
            char tbl[4] = {0,0,0,0};
            for (int o = 0; o < 8; o++) {
                const unsigned char b = nextbyte(ctx);
                const unsigned char c = a1l[b & 0x3f];
                if (pl < 36 && b < 250) pnl[pl++ * 5 / 4] = nm[b % 10];
                p3l[z + o] = a1l[b & 0x3f];
                unsigned int l;
                for (l = 0; l < sizeof uc; l++) {
                    if (c == a1l[l]) break;
                }
                if (l < lc - uc) { tbl[0] = 1; continue; }
                if (l < nm - uc) { tbl[1] = 1; continue; }
                if (l < em - uc) { tbl[2] = 1; continue; }
                assert (l != sizeof uc);
                tbl[3] = 1;
            }
            if (*(uint32_t*)tbl == 0x01010101) break;
        }
    }
    return pl;
}

static void pwpingen_ref(struct blake2b_ctx * ctx)
{
    struct {
        char p1l[50];
        char p2l[50];
        char p3l[50];
        char pnl[50];
    } a;
    memset(&a, ' ', sizeof a);
    int i, j = 0;
    for (i = 0; i < 40; i++) {
        const unsigned char b = nextbyte(ctx);
        a.p1l[i * 9 / 8] = a1l[b & 0x3f];
        a.p2l[i * 9 / 8] = a2l[b & 0x1f];
        if (b < 250) a.pnl[j++ * 5 / 4] = nm[b % 10];
    }
    j = allgrps(ctx, a.p3l, a.pnl, j);
    while (j < 36) {
        const unsigned char b = nextbyte(ctx);
        if (b < 250) a.pnl[j++ * 5 / 4] = nm[b % 10];
    }
    //j = 36;
    a.p1l[44] = '\n'; a.p1l[45] = '\0';
    a.p3l[44] = '\n'; a.p3l[45] = '\0';
    a.p2l[44] = '\n'; a.p2l[45] = '\0';
    a.pnl[44] = '\n'; a.pnl[45] = '\0';
    printf("\n%s%s%s%s\n", a.p1l, a.p3l, a.p2l, a.pnl);
}

int main(int argc, char * argv[])
{
    struct blake2b_ctx ctx;
    blake2b_init(&ctx, 64);
    blake2b_update(&ctx, "PwPiNGeN:2\n", 11);
    for (int i = 1; i < argc; i++) {
        if (i != 1) blake2b_update(&ctx, " ", 1);
        blake2b_update(&ctx, argv[i], strlen(argv[i]));
    }
    blake2b_final(&ctx);
    ctx.buflen = 0;
    pwpingen_ref(&ctx);
    return 0;
}
