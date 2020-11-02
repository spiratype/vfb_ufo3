// tests/sha512.cpp

// https://csrc.nist.gov/CSRC/media/Projects/Cryptographic-Standards-and-Guidelines/documents/examples/SHA512.pdf

#define FMT_HEADER_ONLY
#include <fmt/format.h>
#include <fmt/compile.h>

#include <cstdint>
#include <cstring>
#include <iostream>
#include <string>

#include "../sha512.cpp"

const std::string abc1( "ddaf35a1" "93617aba" "cc417349" "ae204131"
  "12e6fa4e" "89a97ea2" "0a9eeee6" "4b55d39a" "2192992a" "274fc1a8"
  "36ba3c23" "a3feebbd" "454d4423" "643ce80e" "2a9ac94f" "a54ca49f"
  );
const std::string abc2( "8e959b75" "dae313da" "8cf4f728" "14fc143f"
  "8f7779c6" "eb9f7fa1" "7299aead" "b6889018" "501d289e" "4900f7e4"
  "331b99de" "c4b5433a" "c7d329ee" "b6dd2654" "5e96e55b" "874be909"
  );
const std::string qfox( "07e547d9" "586f6a73" "f73fbac0" "435ed769"
  "51218fb7" "d0c8d788" "a309d785" "436bbb64" "2e93a252" "a954f239"
  "12547d1e" "8a3b5ed6" "e1bfd709" "7821233f" "a0538f3d" "b854fee6"
  );

int main() {
  auto test_abc1 = sha512::sha512_hash("abc");
  auto test_abc2 = sha512::sha512_hash("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu");
  auto test_qfox = sha512::sha512_hash("The quick brown fox jumps over the lazy dog");

  std::cout << "sha512::sha512_hash(\"abc\")" << '\n';
  if (test_abc1 == abc1)
    std::cout << "pass\n";
  else
    std::cout << "fail\n";

  std::cout << "sha512::sha512_hash(\"abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu\")\n";
  if (test_abc2 == abc2)
    std::cout << "pass\n";
  else
    std::cout << "fail\n";

  std::cout << "sha512::sha512_hash(\"The quick brown fox jumps over the lazy dog\")\n";
  if (test_qfox == qfox)
    std::cout << "pass\n";
  else
    std::cout << "fail\n";
  }
