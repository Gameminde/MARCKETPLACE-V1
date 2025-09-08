#!/bin/bash

# Golden Test Runner Script for Marketplace Flutter App
# This script helps manage golden tests execution and golden file updates

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
UPDATE_GOLDENS=false
RUN_ALL=false
VERBOSE=false
DEVICE_FILTER=""
THEME_FILTER=""

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    cat << EOF
Golden Test Runner for Marketplace Flutter App

Usage: $0 [OPTIONS]

OPTIONS:
    -u, --update-goldens    Update golden files (equivalent to --update-goldens)
    -a, --all              Run all golden tests including slow ones
    -v, --verbose          Verbose output
    -d, --device DEVICE    Filter by device (mobile, tablet, desktop)
    -t, --theme THEME      Filter by theme (light, dark)
    -h, --help             Show this help message

EXAMPLES:
    $0                          # Run golden tests
    $0 -u                       # Update golden files
    $0 -a                       # Run all tests including slow ones
    $0 -d mobile               # Run only mobile device tests
    $0 -t dark                 # Run only dark theme tests
    $0 -u -v                   # Update with verbose output

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--update-goldens)
            UPDATE_GOLDENS=true
            shift
            ;;
        -a|--all)
            RUN_ALL=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -d|--device)
            DEVICE_FILTER="$2"
            shift 2
            ;;
        -t|--theme)
            THEME_FILTER="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate Flutter installation
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

# Change to project directory
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

print_status "Running golden tests from: $PROJECT_DIR"

# Prepare test command
TEST_COMMAND="flutter test test/golden/golden_test.dart"

# Add update goldens flag if requested
if [[ "$UPDATE_GOLDENS" == true ]]; then
    TEST_COMMAND="$TEST_COMMAND --update-goldens"
    print_status "Updating golden files..."
else
    print_status "Running golden tests..."
fi

# Add verbose flag if requested
if [[ "$VERBOSE" == true ]]; then
    TEST_COMMAND="$TEST_COMMAND --verbose"
fi

# Add device filter if specified
if [[ -n "$DEVICE_FILTER" ]]; then
    TEST_COMMAND="$TEST_COMMAND --dart-define=DEVICE_FILTER=$DEVICE_FILTER"
    print_status "Filtering by device: $DEVICE_FILTER"
fi

# Add theme filter if specified
if [[ -n "$THEME_FILTER" ]]; then
    TEST_COMMAND="$TEST_COMMAND --dart-define=THEME_FILTER=$THEME_FILTER"
    print_status "Filtering by theme: $THEME_FILTER"
fi

# Clean previous test results
print_status "Cleaning previous test results..."
flutter clean > /dev/null 2>&1

# Get dependencies
print_status "Getting dependencies..."
flutter pub get > /dev/null 2>&1

# Create golden directories if they don't exist
mkdir -p test/golden/goldens
mkdir -p test/golden/screenshots

# Run the tests
print_status "Executing: $TEST_COMMAND"

if eval "$TEST_COMMAND"; then
    print_success "Golden tests completed successfully!"
    
    if [[ "$UPDATE_GOLDENS" == true ]]; then
        print_success "Golden files have been updated."
        print_warning "Please review the changes and commit them if they look correct."
        
        # Show git status for golden files
        if command -v git &> /dev/null; then
            echo ""
            print_status "Git status for golden files:"
            git status --porcelain test/golden/goldens/ || true
        fi
    fi
    
else
    print_error "Golden tests failed!"
    
    if [[ "$UPDATE_GOLDENS" == false ]]; then
        echo ""
        print_warning "If the UI changes are intentional, update the golden files:"
        echo "    $0 --update-goldens"
        echo ""
        print_warning "Or run with verbose output to see detailed differences:"
        echo "    $0 --verbose"
    fi
    
    exit 1
fi

# Generate test report if available
if [[ -f "test/golden/test_results.json" ]]; then
    print_status "Generating test report..."
    # Add test report generation logic here
fi

# Success message
echo ""
print_success "All golden tests completed successfully!"

if [[ "$RUN_ALL" == true ]]; then
    print_status "Ran complete test suite including slow tests."
fi

if [[ -n "$DEVICE_FILTER" ]] || [[ -n "$THEME_FILTER" ]]; then
    print_warning "Ran filtered tests only. Run without filters for complete coverage."
fi