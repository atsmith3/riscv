/*
 * Simple Word Load/Store Test
 */

#define MAGIC_RESULT_ADDR ((volatile unsigned int *)0xDEAD0000)
#define MAGIC_PASS_VALUE 0x00000001
#define MAGIC_FAIL_VALUE 0xFFFFFFFF

int main() {
  unsigned int test_data = 0x12345678;
  unsigned int read_back;

  // Simple word store and load
  read_back = test_data;

  if (read_back == 0x12345678) {
    *MAGIC_RESULT_ADDR = MAGIC_PASS_VALUE;
  } else {
    *MAGIC_RESULT_ADDR = MAGIC_FAIL_VALUE;
  }

  while (1)
    ;
  return 0;
}
