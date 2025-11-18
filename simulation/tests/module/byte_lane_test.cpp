/*
 * Byte Lane Module Test
 *
 * Tests the byte_lane module for correct byte/halfword extraction,
 * sign/zero extension, data replication, and byte enable generation.
 */

#include "Vbyte_lane.h"
#include <boost/test/unit_test.hpp>
#include <cstdint>

BOOST_AUTO_TEST_SUITE(ByteLaneTests)

// Helper function to create test DUT
Vbyte_lane *create_dut() { return new Vbyte_lane(); }

// Helper function to cleanup DUT
void cleanup_dut(Vbyte_lane *dut) { delete dut; }

// Test byte load unsigned from all 4 positions
BOOST_AUTO_TEST_CASE(test_load_byte_unsigned_all_positions) {
  Vbyte_lane *dut = create_dut();

  // Test data: 0xDEADBEEF
  uint32_t test_data = 0xDEADBEEF;
  dut->mem_data_in = test_data;
  dut->load_size = 0;     // MEM_SIZE_BYTE
  dut->load_unsigned = 1; // Unsigned

  // Position 0: Extract byte [7:0] = 0xEF
  dut->addr_low = 0;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->load_data_out, 0x000000EF);

  // Position 1: Extract byte [15:8] = 0xBE
  dut->addr_low = 1;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->load_data_out, 0x000000BE);

  // Position 2: Extract byte [23:16] = 0xAD
  dut->addr_low = 2;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->load_data_out, 0x000000AD);

  // Position 3: Extract byte [31:24] = 0xDE
  dut->addr_low = 3;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->load_data_out, 0x000000DE);

  cleanup_dut(dut);
}

// Test byte load signed with positive values
BOOST_AUTO_TEST_CASE(test_load_byte_signed_positive) {
  Vbyte_lane *dut = create_dut();

  // Test data with positive bytes (MSB = 0)
  uint32_t test_data = 0x01234567;
  dut->mem_data_in = test_data;
  dut->load_size = 0;     // MEM_SIZE_BYTE
  dut->load_unsigned = 0; // Signed

  // Position 0: Extract byte [7:0] = 0x67 (positive, MSB=0)
  dut->addr_low = 0;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->load_data_out, 0x00000067);

  // Position 1: Extract byte [15:8] = 0x45 (positive, MSB=0)
  dut->addr_low = 1;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->load_data_out, 0x00000045);

  cleanup_dut(dut);
}

// Test byte load signed with negative values (sign extension)
BOOST_AUTO_TEST_CASE(test_load_byte_signed_negative) {
  Vbyte_lane *dut = create_dut();

  // Test data with negative bytes (MSB = 1)
  uint32_t test_data = 0xDEADBEEF;
  dut->mem_data_in = test_data;
  dut->load_size = 0;     // MEM_SIZE_BYTE
  dut->load_unsigned = 0; // Signed

  // Position 0: Extract byte [7:0] = 0xEF (negative, MSB=1)
  // Should sign extend to 0xFFFFFFEF
  dut->addr_low = 0;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->load_data_out, 0xFFFFFFEF);

  // Position 1: Extract byte [15:8] = 0xBE (negative, MSB=1)
  // Should sign extend to 0xFFFFFFBE
  dut->addr_low = 1;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->load_data_out, 0xFFFFFFBE);

  // Position 2: Extract byte [23:16] = 0xAD (negative, MSB=1)
  // Should sign extend to 0xFFFFFFAD
  dut->addr_low = 2;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->load_data_out, 0xFFFFFFAD);

  // Position 3: Extract byte [31:24] = 0xDE (negative, MSB=1)
  // Should sign extend to 0xFFFFFFDE
  dut->addr_low = 3;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->load_data_out, 0xFFFFFFDE);

  cleanup_dut(dut);
}

// Test halfword load unsigned from both positions
BOOST_AUTO_TEST_CASE(test_load_halfword_unsigned) {
  Vbyte_lane *dut = create_dut();

  // Test data: 0xDEADBEEF
  uint32_t test_data = 0xDEADBEEF;
  dut->mem_data_in = test_data;
  dut->load_size = 1;     // MEM_SIZE_HALF
  dut->load_unsigned = 1; // Unsigned

  // Position 0 (addr[1]=0): Extract halfword [15:0] = 0xBEEF
  dut->addr_low = 0;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->load_data_out, 0x0000BEEF);

  // Position 1 (addr[1]=1): Extract halfword [31:16] = 0xDEAD
  dut->addr_low = 2; // addr[1] = 1
  dut->eval();
  BOOST_CHECK_EQUAL(dut->load_data_out, 0x0000DEAD);

  cleanup_dut(dut);
}

// Test halfword load signed with negative values
BOOST_AUTO_TEST_CASE(test_load_halfword_signed_negative) {
  Vbyte_lane *dut = create_dut();

  // Test data with negative halfwords (MSB = 1)
  uint32_t test_data = 0xDEADBEEF;
  dut->mem_data_in = test_data;
  dut->load_size = 1;     // MEM_SIZE_HALF
  dut->load_unsigned = 0; // Signed

  // Position 0: Extract halfword [15:0] = 0xBEEF (negative, MSB=1)
  // Should sign extend to 0xFFFFBEEF
  dut->addr_low = 0;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->load_data_out, 0xFFFFBEEF);

  // Position 1: Extract halfword [31:16] = 0xDEAD (negative, MSB=1)
  // Should sign extend to 0xFFFFDEAD
  dut->addr_low = 2;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->load_data_out, 0xFFFFDEAD);

  cleanup_dut(dut);
}

// Test word load (pass-through)
BOOST_AUTO_TEST_CASE(test_load_word) {
  Vbyte_lane *dut = create_dut();

  // Test data
  uint32_t test_data = 0x12345678;
  dut->mem_data_in = test_data;
  dut->load_size = 2;     // MEM_SIZE_WORD
  dut->load_unsigned = 0; // Don't care for word
  dut->addr_low = 0;

  dut->eval();
  BOOST_CHECK_EQUAL(dut->load_data_out, 0x12345678);

  cleanup_dut(dut);
}

// Test byte enable generation for byte stores
BOOST_AUTO_TEST_CASE(test_byte_enable_byte_stores) {
  Vbyte_lane *dut = create_dut();

  dut->store_size = 0; // MEM_SIZE_BYTE

  // Position 0: byte_enable = 0001
  dut->addr_low = 0;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->byte_enable, 0x1);

  // Position 1: byte_enable = 0010
  dut->addr_low = 1;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->byte_enable, 0x2);

  // Position 2: byte_enable = 0100
  dut->addr_low = 2;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->byte_enable, 0x4);

  // Position 3: byte_enable = 1000
  dut->addr_low = 3;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->byte_enable, 0x8);

  cleanup_dut(dut);
}

// Test byte enable generation for halfword stores
BOOST_AUTO_TEST_CASE(test_byte_enable_halfword_stores) {
  Vbyte_lane *dut = create_dut();

  dut->store_size = 1; // MEM_SIZE_HALF

  // Position 0 (addr[1]=0): byte_enable = 0011
  dut->addr_low = 0;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->byte_enable, 0x3);

  // Position 1 (addr[1]=1): byte_enable = 1100
  dut->addr_low = 2;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->byte_enable, 0xC);

  cleanup_dut(dut);
}

// Test byte enable generation for word stores
BOOST_AUTO_TEST_CASE(test_byte_enable_word_stores) {
  Vbyte_lane *dut = create_dut();

  dut->store_size = 2; // MEM_SIZE_WORD
  dut->addr_low = 0;

  dut->eval();
  BOOST_CHECK_EQUAL(dut->byte_enable, 0xF);

  cleanup_dut(dut);
}

// Test store data replication for byte stores
BOOST_AUTO_TEST_CASE(test_store_byte_replication) {
  Vbyte_lane *dut = create_dut();

  uint32_t test_byte = 0x000000AB;
  dut->store_data_in = test_byte;
  dut->store_size = 0; // MEM_SIZE_BYTE
  dut->addr_low = 0;   // Don't care for replication

  dut->eval();
  // Byte should be replicated to all 4 positions
  BOOST_CHECK_EQUAL(dut->mem_data_out, 0xABABABAB);

  cleanup_dut(dut);
}

// Test store data replication for halfword stores
BOOST_AUTO_TEST_CASE(test_store_halfword_replication) {
  Vbyte_lane *dut = create_dut();

  uint32_t test_half = 0x00001234;
  dut->store_data_in = test_half;
  dut->store_size = 1; // MEM_SIZE_HALF
  dut->addr_low = 0;   // Don't care for replication

  dut->eval();
  // Halfword should be replicated to both positions
  BOOST_CHECK_EQUAL(dut->mem_data_out, 0x12341234);

  cleanup_dut(dut);
}

// Test store word (pass-through)
BOOST_AUTO_TEST_CASE(test_store_word_passthrough) {
  Vbyte_lane *dut = create_dut();

  uint32_t test_word = 0xDEADBEEF;
  dut->store_data_in = test_word;
  dut->store_size = 2; // MEM_SIZE_WORD
  dut->addr_low = 0;

  dut->eval();
  // Word should pass through unchanged
  BOOST_CHECK_EQUAL(dut->mem_data_out, 0xDEADBEEF);

  cleanup_dut(dut);
}

// Edge case: Load NULL byte (for strlen testing)
BOOST_AUTO_TEST_CASE(test_load_null_byte) {
  Vbyte_lane *dut = create_dut();

  // String data with null terminator at position 3
  uint32_t test_data = 0x00636261; // "abc\0" in little-endian
  dut->mem_data_in = test_data;
  dut->load_size = 0;     // MEM_SIZE_BYTE
  dut->load_unsigned = 1; // LBU

  // Load byte at position 3 (should be 0x00)
  dut->addr_low = 3;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->load_data_out, 0x00000000);

  cleanup_dut(dut);
}

BOOST_AUTO_TEST_SUITE_END()
