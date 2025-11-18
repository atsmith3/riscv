/*
 * Simple Byte Load Test
 *
 * Minimal test to verify LBU (load byte unsigned) works correctly.
 */

#define MAGIC_RESULT_ADDR ((volatile unsigned int *)0xDEAD0000)
#define MAGIC_PASS_VALUE 0x00000001
#define MAGIC_FAIL_VALUE 0xFFFFFFFF

int main() {
  // Test data array with known values
  unsigned char test_data[4] = {0xAB, 0xCD, 0xEF, 0x12};

  // Load each byte and verify
  unsigned char byte0 = test_data[0]; // Should load 0xAB
  unsigned char byte1 = test_data[1]; // Should load 0xCD
  unsigned char byte2 = test_data[2]; // Should load 0xEF
  unsigned char byte3 = test_data[3]; // Should load 0x12

  // Verify all bytes loaded correctly
  if (byte0 == 0xAB && byte1 == 0xCD && byte2 == 0xEF && byte3 == 0x12) {
    *MAGIC_RESULT_ADDR = MAGIC_PASS_VALUE;
  } else {
    *MAGIC_RESULT_ADDR = MAGIC_FAIL_VALUE;
  }

  while (1)
    ;
  return 0;
}
