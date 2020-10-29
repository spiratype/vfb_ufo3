// sha512.cpp

#pragma once

/*
Original conversion from C to C++ by zedwood.com 2012
http://www.zedwood.com/article/cpp-sha512-function

Additional modifications, including changes to standard library integer
types and conversion of macros to functions by Jameson R Spires

https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.180-4.pdf

FIPS 180-2 SHA-224/256/384/512 implementation
Last update: 02/02/2007
Issue date:  04/30/2005
http://www.ouah.org/ogay/sha2

Copyright (C) 2005, 2007 Olivier Gay <olivier.gay@a3.epfl.ch>
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
3. Neither the name of the project nor the names of its contributors
   may be used to endorse or promote products derived from this software
   without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE PROJECT AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL THE PROJECT OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.
*/

namespace sha512 {

typedef unsigned char u_char;

static const int BLOCK_SIZE = 128;
static const int DIGEST_SIZE = 64;
static const std::array<std::uint8_t, 8> M = {56, 48, 40, 32, 24, 16, 8, 0};
static const std::array<std::uint64_t, 80> K = {
  0x428a2f98d728ae22, 0x7137449123ef65cd, 0xb5c0fbcfec4d3b2f, 0xe9b5dba58189dbbc,
  0x3956c25bf348b538, 0x59f111f1b605d019, 0x923f82a4af194f9b, 0xab1c5ed5da6d8118,
  0xd807aa98a3030242, 0x12835b0145706fbe, 0x243185be4ee4b28c, 0x550c7dc3d5ffb4e2,
  0x72be5d74f27b896f, 0x80deb1fe3b1696b1, 0x9bdc06a725c71235, 0xc19bf174cf692694,
  0xe49b69c19ef14ad2, 0xefbe4786384f25e3, 0x0fc19dc68b8cd5b5, 0x240ca1cc77ac9c65,
  0x2de92c6f592b0275, 0x4a7484aa6ea6e483, 0x5cb0a9dcbd41fbd4, 0x76f988da831153b5,
  0x983e5152ee66dfab, 0xa831c66d2db43210, 0xb00327c898fb213f, 0xbf597fc7beef0ee4,
  0xc6e00bf33da88fc2, 0xd5a79147930aa725, 0x06ca6351e003826f, 0x142929670a0e6e70,
  0x27b70a8546d22ffc, 0x2e1b21385c26c926, 0x4d2c6dfc5ac42aed, 0x53380d139d95b3df,
  0x650a73548baf63de, 0x766a0abb3c77b2a8, 0x81c2c92e47edaee6, 0x92722c851482353b,
  0xa2bfe8a14cf10364, 0xa81a664bbc423001, 0xc24b8b70d0f89791, 0xc76c51a30654be30,
  0xd192e819d6ef5218, 0xd69906245565a910, 0xf40e35855771202a, 0x106aa07032bbd1b8,
  0x19a4c116b8d2d0c8, 0x1e376c085141ab53, 0x2748774cdf8eeb99, 0x34b0bcb5e19b48a8,
  0x391c0cb3c5c95a63, 0x4ed8aa4ae3418acb, 0x5b9cca4f7763e373, 0x682e6ff3d6b2b8a3,
  0x748f82ee5defb2fc, 0x78a5636f43172f60, 0x84c87814a1f0ab72, 0x8cc702081a6439ec,
  0x90befffa23631e28, 0xa4506cebde82bde9, 0xbef9a3f7b2c67915, 0xc67178f2e372532b,
  0xca273eceea26619c, 0xd186b8c721c0c207, 0xeada7dd6cde0eb1e, 0xf57d4f7fee6ed178,
  0x06f067aa72176fba, 0x0a637dc5a2c898a6, 0x113f9804bef90dae, 0x1b710b35131c471b,
  0x28db77f523047d84, 0x32caab7b40c72493, 0x3c9ebe0a15c9bebc, 0x431d67c49c100d4c,
  0x4cc5d4becb3e42b6, 0x597f299cfc657e2a, 0x5fcb6fab3ad6faec, 0x6c44198c4a475817
  };

static inline auto ch(auto x, auto y, auto z) {
  return (x & y) ^ (~x & z);
  }
static inline auto maj(auto x, auto y, auto z) {
  return (x & y) ^ (x & z) ^ (y & z);
  }
static inline auto rotr(auto x, auto n) {
  return (x >> n) | (x << ((sizeof(x) << 3) - n));
  }
static inline auto Sigma_0(auto x) {
  return rotr(x, 28) ^ rotr(x, 34) ^ rotr(x, 39);
  }
static inline auto Sigma_1(auto x) {
  return rotr(x, 14) ^ rotr(x, 18) ^ rotr(x, 41);
  }
static inline auto sigma_0(auto x) {
  return rotr(x,  1) ^ rotr(x,  8) ^ (x >> 7);
  }
static inline auto sigma_1(auto x) {
  return rotr(x, 19) ^ rotr(x, 61) ^ (x >> 6);
  }
static inline void pack64(auto x, auto y) {
  *y = (std::uint64_t) *(x + 7);
  for (int i = 0; i < 7; i++)
    *y |= (std::uint64_t) *(x + i) << M[i];
  }
static inline void unpack32(auto x, auto y) {
  for (int i = 0; i < 4; i++)
    y[i] = std::uint32_t(x >> M[i]);
  }

struct sha512 {
  std::uint32_t tot_len = 0;
  std::uint32_t len = 0;
  u_char block[256] = {};
  std::array<std::uint64_t, 8> h = {
    0x6a09e667f3bcc908, 0xbb67ae8584caa73b, 0x3c6ef372fe94f82b, 0xa54ff53a5f1d36f1,
    0x510e527fade682d1, 0x9b05688c2b3e6c1f, 0x1f83d9abfb41bd6b, 0x5be0cd19137e2179
    };
  void transform(const u_char* message, std::uint32_t block_nb);
  void update(const u_char* message, std::uint32_t len);
  void finish();
  std::string str() {
    std::string out;
    out.reserve(130);
    for (size_t i = 0; i < 8; i++)
      out += fmt::format(FMT_COMPILE("{:016x}"), this->h[i]);
    return out;
    }
  };

void sha512::transform(const u_char* message, std::uint32_t block_nb) {
  std::array<std::uint64_t, 8> h = {};
  std::array<std::uint64_t, 80> k = {};
  std::uint64_t t1 = 0, t2 = 0;
  size_t j = 0;
  const u_char* sub_block;

  for (size_t i = 0; i < block_nb; i++) {
    sub_block = message + (i << 7);
    for (j = 0; j < 16; j++)
      pack64(&sub_block[j << 3], &k[j]);

    for (j = 16; j < 80; j++)
      k[j] =  sigma_1(k[j - 2]) + k[j - 7] + sigma_0(k[j - 15]) + k[j - 16];

    for (j = 0; j < 8; j++)
      h[j] = this->h[j];

    for (j = 0; j < 80; j++) {
      t1 = h[7] + Sigma_1(h[4]) + ch(h[4], h[5], h[6]) + K[j] + k[j];
      t2 = Sigma_0(h[0]) + maj(h[0], h[1], h[2]);
      h[7] = h[6];
      h[6] = h[5];
      h[5] = h[4];
      h[4] = h[3] + t1;
      h[3] = h[2];
      h[2] = h[1];
      h[1] = h[0];
      h[0] = t1 + t2;
      }

    for (j = 0; j < 8; j++)
      this->h[j] += h[j];
    }
  }

void sha512::update(const u_char* message, std::uint32_t len) {
  std::uint32_t tmp_len = BLOCK_SIZE - this->len;
  std::uint32_t rem_len = len < tmp_len ? len : tmp_len;

  std::memcpy(&this->block[this->len], message, rem_len);

  if (this->len + len < BLOCK_SIZE) {
    this->len += len;
    return;
    }

  std::uint32_t new_len = len - rem_len;
  std::uint32_t block_nb = new_len / BLOCK_SIZE;
  const u_char* shifted_message = message + rem_len;
  rem_len = new_len % BLOCK_SIZE;

  this->transform(this->block, 1);
  this->transform(shifted_message, block_nb);

  std::memcpy(this->block, &shifted_message[block_nb << 7], rem_len);
  this->len = rem_len;
  this->tot_len += (block_nb + 1) << 7;
  }

void sha512::finish() {
  std::uint32_t block_nb = 1 + ((BLOCK_SIZE - 17) < (this->len % BLOCK_SIZE));
  std::uint32_t len = block_nb << 7;
  std::uint32_t len_b = (this->tot_len + this->len) << 3;

  std::memset(this->block + this->len, 0, len - this->len);
  this->block[this->len] = 0x80;
  unpack32(len_b, this->block + len - 4);
  this->transform(this->block, block_nb);
  }

std::string sha512_hash(const std::string &input) {
  sha512 context;

  context.update((u_char*)input.c_str(), input.size());
  context.finish();
  return context.str();
  }

} // namespace sha512
