/*
 * Boost.Test Main Entry Point
 *
 * This file defines the Boost.Test module and automatically generates
 * the main() function. Individual test suites are defined in separate
 * files and linked into this test executable.
 *
 * Usage:
 *   ./riscv_tests                    # Run all tests
 *   ./riscv_tests --log_level=all    # Run with verbose output
 *   ./riscv_tests --run_test=SystemLevelTests/test_add_program  # Run specific
 * test
 *   ./riscv_tests --list_content     # List all test cases
 */

#define BOOST_TEST_MODULE RISCV_Core_Tests
#include <boost/test/included/unit_test.hpp>

// Boost.Test will auto-generate main()
// Individual test suites are in separate .cpp files
