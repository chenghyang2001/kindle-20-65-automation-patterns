# code-reviewer Test Scenarios

## TC-01: Security Issue Detection
Input: Code that builds a query with SQL string concatenation
Expected: SQL injection flagged with a suggested fix
Pass Criteria: Response contains "SQL injection"

## TC-02: No Over-Flagging of Good Code
Input: Code with standard error handling
Expected: No critical issues reported
Pass Criteria: Response does not contain "Critical"

## TC-03: Priority Classification
Input: Code with multiple issues
Expected: Issues classified as Critical / Warning / Suggestion
Pass Criteria: Response contains at least one classification label
