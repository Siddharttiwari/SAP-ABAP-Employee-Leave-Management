
# SAP Technical Configuration

## 1. Development Package

| Property | Value |
|---|---|
| Package | `ZEMP_LEAVE_MGMT` |
| Platform | SAP ABAP |
| Application | Employee Leave Management System |

## 2. ABAP Dictionary Objects (SE11)

| Object Type | Object Name | Description |
|---|---|---|
| Transparent Table | `ZELM_EMPLOYEE` | Employee master data and leave balances |
| Transparent Table | `ZELM_LEAVE` | Leave request records |
| Data Element | `ZELM_EMP_ID` | Employee identification number |
| Lock Object | `EZELM_EMPLOYEE` | Employee-level processing lock |

### Table Relationship

`ZELM_LEAVE-EMP_ID` has a foreign-key relationship with check table `ZELM_EMPLOYEE`.

## 3. Lock Object Configuration

| Property | Value |
|---|---|
| Lock Object | `EZELM_EMPLOYEE` |
| Primary Table | `ZELM_EMPLOYEE` |
| Lock Mode | Exclusive, not cumulative |
| Status | Active |

Generated function modules:

- `ENQUEUE_EZELM_EMPLOYEE`
- `DEQUEUE_EZELM_EMPLOYEE`

The approval programs acquire an employee-level lock before processing a pending leave request and release it after transaction handling.

## 4. Number Range Configuration (SNRO)

| Property | Value |
|---|---|
| Object | `ZELM_LVNR` |
| Number Length Domain | `NUMC10` |
| Interval | `01` |
| From Number | `0000000001` |
| To Number | `9999999999` |
| Assignment | Internal |
| Warning Percentage | 10% |

The leave application program uses `NUMBER_GET_NEXT` to allocate request IDs.

**Note:** Number range status may advance independently of the number of successfully saved leave requests.

## 5. ABAP Reports (SE38)

| Report | Purpose |
|---|---|
| `ZELM_APPLY_LEAVE` | Create and validate leave requests |
| `ZELM_APPROVE_LEAVE` | Approve or reject requests |
| `ZELM_LEAVE_DASHBOARD` | Interactive ALV processing |

## 6. GUI Status Configuration

| Property | Value |
|---|---|
| Program | `ZELM_LEAVE_DASHBOARD` |
| GUI Status | `ZLEAVE_STATUS` |
| Function Code | `ZAPPROVE` — Approve |
| Function Code | `ZREJECT` — Reject |

The dashboard handles these custom functions through the `ADDED_FUNCTION` event of `CL_SALV_EVENTS_TABLE`.

## 7. Transaction Management

The approval workflow uses:

- `COMMIT WORK` or `COMMIT WORK AND WAIT` for successful transactions.
- `ROLLBACK WORK` for failed updates.
- SAP enqueue/dequeue functions for employee-level locking.

## 8. Deployment Notes

The ABAP source files alone are not sufficient to recreate the application. The DDIC objects, foreign key, lock object, number range interval, and custom GUI status must also be configured in the target SAP system.

## 9. Current Limitations

- Approval authorization checks are not yet implemented.
- Leave submission does not currently acquire an employee lock.
- Working-day and holiday-calendar calculations are not implemented.
- Approval-time overlap revalidation is a planned enhancement.
