#!/bin/bash
# parallel-review.sh

# Run security, performance, and test reviews in parallel
claude -w review-security -p "Review from a security perspective" \
  --allowedTools "Read,Grep,Glob" &
PID1=$!

claude -w review-perf -p "Identify performance issues" \
  --allowedTools "Read,Grep,Glob" &
PID2=$!

claude -w review-tests -p "Identify gaps in test coverage" \
  --allowedTools "Read,Grep,Glob" &
PID3=$!

wait $PID1 $PID2 $PID3
echo "Parallel review complete"
