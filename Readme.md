\# Employee Leave Management System | SAP ABAP



An SAP ABAP-based Employee Leave Management System that automates leave applications, approvals, rejections, and leave balance tracking using SAP Dictionary, Open SQL, number ranges, lock objects, and an interactive ALV dashboard.



\## Project Overview



This project demonstrates the development of an employee leave management application in SAP GUI. It provides a structured workflow for submitting leave requests, validating business rules, processing approvals, and maintaining employee leave balances.



The application uses custom SAP database tables and an interactive ALV report to manage leave requests efficiently.



\## Technologies Used



\- SAP ABAP

\- ABAP Dictionary (SE11)

\- Open SQL

\- Object-Oriented ABAP

\- CL\_SALV\_TABLE

\- SAP Lock Objects

\- SAP Number Range Objects (SNRO)

\- Custom GUI Status (PF-STATUS)

\- Database Transaction Management



\## Key Features



\### Employee Leave Application

\- Submit leave requests with employee ID, dates, and reason.

\- Validate employee existence.

\- Prevent invalid and past leave dates.

\- Detect overlapping pending or approved requests.

\- Check available leave balance.

\- Generate leave request IDs using SAP number ranges.

\- Store new applications with PENDING status.



\### Leave Approval and Rejection

\- Approve or reject pending requests.

\- Prevent duplicate processing.

\- Update employee leave balances after approval.

\- Preserve leave balances when requests are rejected.

\- Record the processing SAP username.

\- Use exclusive employee locks and database transactions.



\### Interactive ALV Dashboard

\- Display employee and leave request details.

\- Filter by employee ID.

\- Display pending requests or all requests.

\- Approve or reject requests using custom toolbar buttons.

\- Refresh the dashboard after successful processing.

\- Calculate and display available leave balances.



\## SAP Development Objects



| Object | Name | Purpose |

|---|---|---|

| Package | ZEMP\_LEAVE\_MGMT | Development package |

| Transparent Table | ZELM\_EMPLOYEE | Employee master data |

| Transparent Table | ZELM\_LEAVE | Leave request records |

| Data Element | ZELM\_EMP\_ID | Employee identification |

| Lock Object | EZELM\_EMPLOYEE | Employee-level exclusive locking |

| Number Range | ZELM\_LVNR | Leave request ID generation |

| ABAP Report | ZELM\_APPLY\_LEAVE | Submit leave applications |

| ABAP Report | ZELM\_APPROVE\_LEAVE | Approve or reject requests |

| ABAP Report | ZELM\_LEAVE\_DASHBOARD | Interactive ALV dashboard |

| GUI Status | ZLEAVE\_STATUS | Custom approval and rejection actions |



\## Database Design



\### ZELM\_EMPLOYEE



Stores employee information and leave entitlements.



| Field | Type |

|---|---|

| MANDT | CLNT(3) |

| EMP\_ID | CHAR(10) |

| EMP\_NAME | CHAR(50) |

| DEPARTMENT | CHAR(30) |

| EMAIL | CHAR(60) |

| TOTAL\_LEAVE | INT4 |

| USED\_LEAVE | INT4 |



Primary Key: MANDT + EMP\_ID



\### ZELM\_LEAVE



Stores leave requests and approval information.



| Field | Type |

|---|---|

| MANDT | CLNT(3) |

| LEAVE\_ID | CHAR(10) |

| EMP\_ID | CHAR(10) |

| START\_DATE | DATS |

| END\_DATE | DATS |

| LEAVE\_DAYS | INT4 |

| REASON | CHAR(100) |

| STATUS | CHAR(10) |

| APPROVED\_BY | CHAR(12) |



Primary Key: MANDT + LEAVE\_ID



Foreign Key: EMP\_ID references ZELM\_EMPLOYEE.



\*\*Relationship:\*\* One employee can have multiple leave requests.



\## Application Workflow



1\. An employee submits a leave request.

2\. The application validates the employee, dates, leave balance, and overlapping requests.

3\. SAP generates a leave ID through `NUMBER\_GET\_NEXT`.

4\. The request is saved with PENDING status.

5\. The request appears in the ALV dashboard.

6\. A user selects the request and chooses Approve or Reject.

7\. The system acquires an exclusive employee lock and revalidates the request.

8\. Approval updates used leave days; rejection leaves the balance unchanged.

9\. The database transaction is committed and the dashboard refreshed.



\## Business Rules



\- Start date must not exceed end date.

\- Leave applications cannot start in the past.

\- Requested days cannot exceed available leave balance at submission.

\- Requests cannot overlap existing PENDING or APPROVED leave requests.

\- Only PENDING requests can be approved or rejected.

\- Approved leave increases USED\_LEAVE.

\- Rejected leave does not affect USED\_LEAVE.



Available Leave = Total Leave − Used Leave



Leave duration is calculated using inclusive calendar days.



\## Testing



The following functional and negative scenarios were tested in SAP GUI.



| Test Case | Result |

|---|---|

| Successful leave submission | Passed |

| Successful leave approval | Passed |

| Successful leave rejection | Passed |

| Overlapping leave validation | Passed |

| Insufficient balance validation | Passed |

| Invalid date range validation | Passed |

| Past date validation | Passed |

| Duplicate approval prevention | Passed |

| Employee leave balance consistency | Passed |

| ALV dashboard display and processing | Passed |



\### Verified Example



An employee with 24 total leave days and 5 approved leave days has an available balance of 19 days.



The system correctly excludes rejected leave requests from the used leave balance.



\## Number Range Configuration



Number Range Object: `ZELM\_LVNR`



\- Interval: 01

\- Starting Number: 0000000001

\- Ending Number: 9999999999

\- Domain: NUMC10

\- Assignment: Internal



\## Concurrency and Transaction Handling



The approval programs use the `EZELM\_EMPLOYEE` lock object to coordinate concurrent updates to employee leave balances.



They also use `COMMIT WORK` or `COMMIT WORK AND WAIT` and `ROLLBACK WORK` to handle database transactions.



\## Project Screenshots



Add the following screenshots to the `screenshots` directory:



\- Employee master table structure

\- Leave request table structure

\- Foreign key relationship

\- Employee lock object

\- Number range configuration

\- Leave application screen

\- Interactive ALV dashboard

\- Successful approval and rejection results



\## Setup Requirements



The application requires access to an SAP ABAP development environment with authorization to create and activate custom Dictionary objects, ABAP reports, number range configuration, and GUI statuses.



To recreate the application:



1\. Create the custom package and DDIC objects.

2\. Configure the employee-to-leave foreign key.

3\. Create and activate the lock object.

4\. Configure number range object `ZELM\_LVNR` and interval 01.

5\. Create and activate the three ABAP reports.

6\. Create GUI status `ZLEAVE\_STATUS` with function codes `ZAPPROVE` and `ZREJECT`.

7\. Maintain sample employee master records.

8\. Execute the reports and perform functional tests.



\## Current Limitations and Future Enhancements



\- Add role-based authorization checks for approval actions.

\- Lock employee records during leave submission to strengthen concurrent-request handling.

\- Add approval-time overlap checks.

\- Introduce holiday calendars and working-day leave calculations.

\- Add leave categories and entitlement policies.

\- Add approval timestamps and detailed audit history.

\- Introduce automated ABAP Unit tests.

\- Develop an SAP Fiori interface.



\## Learning Outcomes



This project demonstrates practical experience with SAP ABAP report development, SAP Dictionary objects, Open SQL, object-oriented event handling, interactive ALV, SAP locking mechanisms, number ranges, and transaction management.



\## Project Status



Core implementation and functional testing completed. Further security, concurrency, and automated testing improvements are planned before production use.

