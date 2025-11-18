/*
 * Bubble Sort Test
 *
 * Sorts an array using bubble sort algorithm.
 * Tests: LW, SW, BLT, BGE, nested loops, complex memory addressing
 */

#ifdef HOST_COMPILE
#include <stdio.h>
#endif

#define MAGIC_RESULT_ADDR ((volatile unsigned int *)0xDEAD0000)
#define MAGIC_PASS_VALUE 0x00000001
#define MAGIC_FAIL_VALUE 0xFFFFFFFF

#define ARRAY_SIZE 8

// Bubble sort implementation
void bubble_sort(int arr[], int n) {
  for (int i = 0; i < n - 1; i++) {
    for (int j = 0; j < n - i - 1; j++) {
      if (arr[j] > arr[j + 1]) {
        // Swap
        int temp = arr[j];
        arr[j] = arr[j + 1];
        arr[j + 1] = temp;
      }
    }
  }
}

// Check if array is sorted
int is_sorted(const int arr[], int n) {
  for (int i = 0; i < n - 1; i++) {
    if (arr[i] > arr[i + 1]) {
      return 0;
    }
  }
  return 1;
}

int main() {
  // Test array: unsorted
  int test_array[ARRAY_SIZE] = {64, 34, 25, 12, 22, 11, 90, 88};

  // Expected sorted result
  const int expected[ARRAY_SIZE] = {11, 12, 22, 25, 34, 64, 88, 90};

  // Sort the array
  bubble_sort(test_array, ARRAY_SIZE);

  // Verify sorting
  int all_pass = 1;

  // Check if sorted
  if (!is_sorted(test_array, ARRAY_SIZE)) {
    all_pass = 0;
  }

  // Check against expected values
  for (int i = 0; i < ARRAY_SIZE; i++) {
    if (test_array[i] != expected[i]) {
      all_pass = 0;
    }
  }

#ifdef HOST_COMPILE
  if (all_pass) {
    printf("PASS\n");
  } else {
    printf("FAIL\n");
  }
  return 0;
#endif
  if (all_pass) {
    *MAGIC_RESULT_ADDR = MAGIC_PASS_VALUE;
  } else {
    *MAGIC_RESULT_ADDR = MAGIC_FAIL_VALUE;
  }

  while (1)
    ;

  return 0;
}
