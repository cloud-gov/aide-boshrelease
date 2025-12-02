#!/bin/bash

# Source the function
source ./calculate-changes

# Create test directory structure
TEST_DIR="./test_scenarios"
mkdir -p "$TEST_DIR"

# Test counters
TOTAL_TESTS=0
FAILED_TESTS=0
PASSED_TESTS=0

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to create a test scenario
create_test_scenario() {
    local scenario_name=$1
    local scenario_dir="${TEST_DIR}/${scenario_name}"
    mkdir -p "$scenario_dir"
    
    # Create log file for this scenario
    local log_file="${scenario_dir}/test.log"
    > "$log_file"
    
    echo "=== Testing scenario: $scenario_name ===" | tee -a "$log_file"
}

# Function to check test result
check_test_result() {
    local test_name=$1
    local actual=$2
    local expected=$3
    local log_file=$4
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$actual" -eq "$expected" ]; then
        echo -e "${GREEN}✓ PASS${NC}: $test_name - Result: $actual (expected: $expected)" | tee -a "$log_file"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}: $test_name - Result: $actual (expected: $expected)" | tee -a "$log_file"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# ######################################################################################
# Scenario 1: Test with only bosh_ changes, changed files are in the allowed list only
# ######################################################################################

test_scenario_1() {
    local scenario="scenario1_bosh_changes_only"
    create_test_scenario "$scenario"
    local scenario_dir="${TEST_DIR}/${scenario}"
    local log_file="${scenario_dir}/test.log"
    
    # Create test report.txt
    cat > "${scenario_dir}/report.txt" << 'EOF'
Changed entries:     2

---------------------------------------------------
Changed entries:
---------------------------------------------------

f > .: ./test_scenarios/scenario1_bosh_changes_only/passwd
f > .: ./test_scenarios/scenario1_bosh_changes_only/group

---------------------------------------------------
EOF
    
    # Create test files with bosh_ changes
    echo "root:x:0:0:root:/root:/bin/bash" > "${scenario_dir}/passwd-"
    echo "bosh_user1:x:1001:1001::/home/bosh_user1:/bin/bash" >> "${scenario_dir}/passwd-"
    
    echo "root:x:0:0:root:/root:/bin/bash" > "${scenario_dir}/passwd"
    echo "bosh_user1:x:1001:1001::/home/bosh_user1:/bin/bash" >> "${scenario_dir}/passwd"
    echo "bosh_user2:x:1002:1002::/home/bosh_user2:/bin/bash" >> "${scenario_dir}/passwd"
    
    echo "root:x:0:" > "${scenario_dir}/group-"
    echo "bosh_group1:x:1001:" >> "${scenario_dir}/group-"
    
    echo "root:x:0:" > "${scenario_dir}/group"
    echo "bosh_group1:x:1001:" >> "${scenario_dir}/group"
    echo "bosh_group2:x:1002:" >> "${scenario_dir}/group"
    
    # Run the test
    local result=$(calculate_changes "$log_file" "${scenario_dir}/report.txt" "true" "$scenario_dir")
    check_test_result "Scenario 1: bosh_ changes only" "$result" "0" "$log_file"
}


# ######################################################################################
# Scenario 2: Test with non-bosh changes, changed file is in allowed list
# ######################################################################################
test_scenario_2() {
    local scenario="scenario2_non_bosh_changes"
    create_test_scenario "$scenario"
    local scenario_dir="${TEST_DIR}/${scenario}"
    local log_file="${scenario_dir}/test.log"
    
    # Create test report.txt
    cat > "${scenario_dir}/report.txt" << 'EOF'
Changed entries:     1

---------------------------------------------------
Changed entries:
---------------------------------------------------

f > .: ./test_scenarios/scenario2_non_bosh_changes/passwd

---------------------------------------------------
EOF
    
    # Create test files with non-bosh changes
    echo "root:x:0:0:root:/root:/bin/bash" > "${scenario_dir}/passwd-"
    echo "user1:x:1001:1001::/home/user1:/bin/bash" >> "${scenario_dir}/passwd-"
    
    echo "root:x:0:0:root:/root:/bin/bash" > "${scenario_dir}/passwd"
    echo "user1:x:1001:1001::/home/user1:/bin/bash" >> "${scenario_dir}/passwd"
    echo "user2:x:1002:1002::/home/user2:/bin/bash" >> "${scenario_dir}/passwd"
    
    # Run the test
    local result=$(calculate_changes "$log_file" "${scenario_dir}/report.txt" "true" "$scenario_dir")
    check_test_result "Scenario 2: non-bosh changes" "$result" "1" "$log_file"
}

# ######################################################################################
# Scenario 3: Test with mixed files inside and outside allowed list
# ######################################################################################
test_scenario_3() {
    local scenario="scenario3_outside_allowed_list"
    create_test_scenario "$scenario"
    local scenario_dir="${TEST_DIR}/${scenario}"
    local log_file="${scenario_dir}/test.log"
    
    # Create test report.txt
    cat > "${scenario_dir}/report.txt" << 'EOF'
Changed entries:     3

---------------------------------------------------
Changed entries:
---------------------------------------------------

f > .: /etc/hosts
f > .: ./test_scenarios/scenario3_outside_allowed_list/passwd
f > .: /var/log/syslog

---------------------------------------------------
EOF
    
    # Run the test
    local result=$(calculate_changes "$log_file" "${scenario_dir}/report.txt" "true" "$scenario_dir")
    check_test_result "Scenario 3: files outside allowed list" "$result" "3" "$log_file"
}

# ######################################################################################
# Scenario 4: Test with zero changes
# ######################################################################################
test_scenario_4() {
    local scenario="scenario4_zero_changes"
    create_test_scenario "$scenario"
    local scenario_dir="${TEST_DIR}/${scenario}"
    local log_file="${scenario_dir}/test.log"
    
    # Create test report.txt
    cat > "${scenario_dir}/report.txt" << 'EOF'
Changed entries:     0

---------------------------------------------------
EOF
    
    # Run the test
    local result=$(calculate_changes "$log_file" "${scenario_dir}/report.txt" "true" "$scenario_dir")
    check_test_result "Scenario 4: zero changes" "$result" "0" "$log_file"
}

# ######################################################################################
# Scenario 5: Test with invalid report format
# ######################################################################################
test_scenario_5() {
    local scenario="scenario5_invalid_report"
    create_test_scenario "$scenario"
    local scenario_dir="${TEST_DIR}/${scenario}"
    local log_file="${scenario_dir}/test.log"
    
    # Create test report.txt with invalid format
    cat > "${scenario_dir}/report.txt" << 'EOF'
This is not a valid AIDE report
EOF
    
    # Run the test
    local result=$(calculate_changes "$log_file" "${scenario_dir}/report.txt" "true" "$scenario_dir")
    check_test_result "Scenario 5: invalid report format" "$result" "0" "$log_file"
}

# ######################################################################################
# Scenario 6: Test with mixed bosh_ and non-bosh_ changes, files are all in allowed list
# ######################################################################################
test_scenario_6() {
    local scenario="scenario6_mixed_changes"
    create_test_scenario "$scenario"
    local scenario_dir="${TEST_DIR}/${scenario}"
    local log_file="${scenario_dir}/test.log"
    
    # Create test report.txt
    cat > "${scenario_dir}/report.txt" << 'EOF'
Changed entries:     2

---------------------------------------------------
Changed entries:
---------------------------------------------------

f > .: ./test_scenarios/scenario6_mixed_changes/passwd
f > .: ./test_scenarios/scenario6_mixed_changes/group

---------------------------------------------------
EOF
    
    # Create passwd files with non-bosh changes
    echo "root:x:0:0:root:/root:/bin/bash" > "${scenario_dir}/passwd-"
    echo "user1:x:1001:1001::/home/user1:/bin/bash" >> "${scenario_dir}/passwd-"
    
    echo "root:x:0:0:root:/root:/bin/bash" > "${scenario_dir}/passwd"
    echo "user1:x:1001:1001::/home/user1:/bin/bash" >> "${scenario_dir}/passwd"
    echo "user2:x:1002:1002::/home/user2:/bin/bash" >> "${scenario_dir}/passwd"
    
    # Create group files with bosh_ changes only
    echo "root:x:0:" > "${scenario_dir}/group-"
    echo "bosh_group1:x:1001:" >> "${scenario_dir}/group-"
    
    echo "root:x:0:" > "${scenario_dir}/group"
    echo "bosh_group1:x:1001:" >> "${scenario_dir}/group"
    echo "bosh_group2:x:1002:" >> "${scenario_dir}/group"
    
    # Run the test
    local result=$(calculate_changes "$log_file" "${scenario_dir}/report.txt" "true" "$scenario_dir")
    check_test_result "Scenario 6: mixed bosh_ and non-bosh_ changes" "$result" "1" "$log_file"
}

# Function to print test summary
print_test_summary() {
    echo ""
    echo "======================================"
    echo "         TEST SUMMARY"
    echo "======================================"
    echo -e "Total tests:  ${YELLOW}$TOTAL_TESTS${NC}"
    echo -e "Passed:       ${GREEN}$PASSED_TESTS${NC}"
    echo -e "Failed:       ${RED}$FAILED_TESTS${NC}"
    echo ""
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}$FAILED_TESTS test(s) failed!${NC}"
        echo ""
        echo "Check individual test logs in ${TEST_DIR} for details."
        return 1
    fi
}

# Main test runner
main() {
    echo "Running calculate_changes tests..."
    echo "======================================"
    
    # Run all test scenarios
    test_scenario_1
    echo ""
    test_scenario_2
    echo ""
    test_scenario_3
    echo ""
    test_scenario_4
    echo ""
    test_scenario_5
    echo ""
    test_scenario_6
    
    # Print summary
    print_test_summary
    
    # Exit with appropriate code
    if [ $FAILED_TESTS -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# Run the tests
main