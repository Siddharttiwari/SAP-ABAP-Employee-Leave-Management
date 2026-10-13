
# Test Cases — SAP ABAP Employee Leave Management System

## 1. Testing Overview

This document describes the manual functional and negative testing performed on the Employee Leave Management System developed using SAP ABAP.

The objective is to verify leave application validation, approval and rejection workflows, duplicate processing prevention, and database consistency.

### Test Environment

| Property | Value |
|---|---|
| Platform | SAP ABAP |
| Interface | SAP GUI |
| Development Package | ZEMP_LEAVE_MGMT |
| Application Report | ZELM_APPLY_LEAVE |
| Approval Report | ZELM_APPROVE_LEAVE |
| Dashboard Report | ZELM_LEAVE_DASHBOARD |
| Database Verification | SE16N |
| Testing Type | Manual Functional Testing |

## 2. Test Data

The following employee record was used for testing.

| Field | Value |
|---|---|
| Employee ID | E001 |
| Employee Name | Rahul Sharma |
| Department | IT |
| Total Leave | 24 |
| Used Leave | 5 |
| Available Leave | 19 |

**Note:** The balance values represent the verified final state after successful approval and rejection tests.

## 3. Functional Test Cases

### TC01 — Successful Leave Application

**Objective:** Verify that a valid leave request can be submitted.

**Input:**

| Field | Value |
|---|---|
| Employee ID | E001 |
| Start Date | 26.11.2026 |
| End Date | 27.11.2026 |
| Reason | FAMILY FUNCTION |

**Expected Result:**
- Request is saved successfully.
- A unique leave ID is generated.
- Initial status is PENDING.
- Used leave balance remains unchanged at submission.

**Actual Result:**
- Leave ID `0000000001` was generated.
- Request was submitted successfully.

**Status:** PASS

### TC02 — Successful Leave Approval

**Objective:** Verify that approving a pending request updates the employee's leave balance.

**Test Record:** `0000000001`

**Expected Result:**
- Status changes from PENDING to APPROVED.
- USED_LEAVE increases by 2.
- Processing SAP username is recorded.

**Actual Result:**
- Request status changed to APPROVED.
- The approved leave days were reflected in the employee balance.

**Status:** PASS

### TC03 — Successful Leave Rejection

**Objective:** Verify that rejected requests do not affect the leave balance.

**Test Record:** `0000000002`

**Leave Days:** 3

**Expected Result:**
- Status changes to REJECTED.
- USED_LEAVE remains unchanged.
- Processing SAP username is recorded.

**Actual Result:**
- Request status changed to REJECTED.
- No additional leave days were deducted.

**Status:** PASS

### TC04 — ALV Dashboard Functionality

**Objective:** Verify interactive dashboard operations.

**Expected Result:**
- Employee and leave details are displayed.
- Pending and All Requests filters work.
- Approve and Reject buttons process selected requests.
- Dashboard refreshes after processing.

**Actual Result:**
- Dashboard functionality was successfully tested.

**Status:** PASS

## 4. Negative Test Cases

### TC05 — Overlapping Leave Request

**Objective:** Prevent overlapping pending or approved leave requests.

| Field | Input |
|---|---|
| Employee ID | E001 |
| Start Date | 26.11.2026 |
| End Date | 28.11.2026 |
| Reason | TEST OVERLAP |

**Expected Message:**

```text
Overlapping leave request exists
```

**Actual Result:** Expected validation message displayed.

**Status:** PASS

### TC06 — Insufficient Leave Balance

**Objective:** Prevent requests exceeding available leave balance.

| Field | Input |
|---|---|
| Employee ID | E001 |
| Start Date | 01.01.2027 |
| End Date | 20.01.2027 |
| Requested Days | 20 |
| Available Balance | 19 |

**Expected Message:**

```text
Insufficient leave balance
```

**Actual Result:** Expected validation message displayed.

**Status:** PASS

### TC07 — Invalid Date Range

**Objective:** Prevent requests with a start date later than the end date.

| Field | Input |
|---|---|
| Employee ID | E001 |
| Start Date | 15.12.2026 |
| End Date | 10.12.2026 |

**Expected Message:**

```text
Start date cannot exceed end date
```

**Actual Result:** Expected validation message displayed.

**Status:** PASS

### TC08 — Past Leave Date

**Objective:** Prevent leave requests starting in the past.

| Field | Input |
|---|---|
| Employee ID | E001 |
| Start Date | 01.10.2026 |
| End Date | 03.10.2026 |

**Expected Message:**

```text
Leave start date cannot be in the past
```

**Actual Result:** Expected validation message displayed.

**Status:** PASS

### TC09 — Duplicate Approval Prevention

**Objective:** Prevent an already approved request from being approved again.

**Test Record:** `0000000001`

**Expected Result:**
- The system refuses duplicate processing.
- The request remains APPROVED.
- Employee leave balance remains unchanged.

**Expected Dashboard Message:**

```text
Only pending requests can be processed
```

**Actual Result:** Duplicate approval protection was exercised during testing. The unchanged balance was subsequently verified.

**Status:** PASS

## 5. Database Consistency Testing

### TC10 — Employee Leave Balance Verification

**Transaction:** SE16N

**Table:** ZELM_EMPLOYEE

| Field | Verified Value |
|---|---|
| EMP_ID | E001 |
| TOTAL_LEAVE | 24 |
| USED_LEAVE | 5 |
| AVAILABLE_LEAVE | 19 |

**Status:** PASS

### TC11 — Leave Request Status Verification

**Transaction:** SE16N

**Table:** ZELM_LEAVE

| Leave ID | Leave Days | Status |
|---|---|---|
| F31A940A6B | 3 | APPROVED |
| 0000000001 | 2 | APPROVED |
| 0000000002 | 3 | REJECTED |

Approved leave days:

```text
3 + 2 = 5
```

Available balance:

```text
24 - 5 = 19
```

Rejected leave requests are excluded from used leave calculations.

**Status:** PASS

## 6. Test Summary

| Test ID | Test Scenario | Result |
|---|---|---|
| TC01 | Valid leave application | PASS |
| TC02 | Leave approval | PASS |
| TC03 | Leave rejection | PASS |
| TC04 | Interactive ALV dashboard | PASS |
| TC05 | Overlapping leave | PASS |
| TC06 | Insufficient balance | PASS |
| TC07 | Invalid date range | PASS |
| TC08 | Past leave date | PASS |
| TC09 | Duplicate approval | PASS |
| TC10 | Employee balance consistency | PASS |
| TC11 | Leave request status consistency | PASS |

**Total Test Cases:** 11

**Passed:** 11

**Failed:** 0

## 7. Additional Testing Recommended

The following scenarios are planned for further testing:

- Invalid or nonexistent employee ID.
- Invalid leave request ID.
- Simultaneous approval attempts by multiple SAP users.
- Number range exhaustion or allocation failure.
- Database update failure and rollback behavior.
- Authorization checks for approval operations.
- High-volume ALV performance.
- Concurrent leave application submissions.

## 8. Conclusion

The Employee Leave Management System successfully passed the documented manual functional and negative tests.

The verified implementation supports leave application, approval, rejection, leave balance management, and interactive ALV processing.

Additional security, concurrency, and automated tests are recommended before production deployment.
