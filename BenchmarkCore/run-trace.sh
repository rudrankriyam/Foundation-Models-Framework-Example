#!/bin/bash

# BenchmarkCLI - Automated xctrace workflow for Foundation Models benchmarking
# This script records a benchmark run with xctrace and exports the data

set -e

TRACE_FILE="token-test.trace"
EXPORT_FILE="token-export.xml"
CLI_PATH="./.build/debug/BenchmarkCLI"

echo "BenchmarkCLI - xctrace Foundation Models Workflow"
echo "================================================================================"
echo ""

# Check if CLI is built
if [ ! -f "$CLI_PATH" ]; then
    echo "CLI not built. Building now..."
    swift build
    echo ""
fi

# Remove old trace files if they exist
if [ -f "$TRACE_FILE" ]; then
    echo "Cleaning up old trace file: $TRACE_FILE"
    rm -f "$TRACE_FILE"
fi

if [ -f "$EXPORT_FILE" ]; then
    echo "Cleaning up old export file: $EXPORT_FILE"
    rm -f "$EXPORT_FILE"
fi

echo "Recording benchmark with Foundation Models instrument..."
echo "   xctrace record --instrument 'Foundation Models' --output $TRACE_FILE --launch -- $CLI_PATH -- token-test"
echo ""

# Record with xctrace
xctrace record --instrument 'Foundation Models' --output "$TRACE_FILE" --launch -- "$CLI_PATH" -- token-test

echo ""
echo "Recording complete!"
echo ""

# Export the data
echo "Exporting trace data..."
echo "   xctrace export --input $TRACE_FILE --xpath '/trace-toc/run[@number=\"1\"]/data/table[@schema=\"FoundationModelsTable\"]' > $EXPORT_FILE"
echo ""

xctrace export \
    --input "$TRACE_FILE" \
    --xpath '/trace-toc/run[@number="1"]/data/table[@schema="FoundationModelsTable"]' \
    > "$EXPORT_FILE"

echo "Export complete!"
echo ""

# Display the export
echo "Exported XML content:"
echo "================================================================================"
cat "$EXPORT_FILE"
echo ""
echo "================================================================================"
echo ""

# Parse XML using BenchmarkCLI
echo "Parsing XML data..."
echo "(XML parsing is now integrated into BenchmarkCLI - run with: swift run BenchmarkCLI parse-xml $EXPORT_FILE)"

echo ""
echo "Done! Files created:"
echo "   - $TRACE_FILE (trace data)"
echo "   - $EXPORT_FILE (exported XML)"
