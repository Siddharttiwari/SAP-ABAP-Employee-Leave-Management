*&---------------------------------------------------------------------*
*& Report ZELM_APPLY_LEAVE
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*


REPORT zelm_apply_leave.

"========================================
" Selection Screen
"========================================
PARAMETERS:
  p_empid TYPE zelm_leave-emp_id OBLIGATORY,
  p_start TYPE zelm_leave-start_date OBLIGATORY,
  p_end   TYPE zelm_leave-end_date OBLIGATORY,
  p_reasn TYPE zelm_leave-reason OBLIGATORY.

"========================================
" Data Declarations
"========================================
DATA:
  ls_employee TYPE zelm_employee,
  ls_leave    TYPE zelm_leave,
  lv_days     TYPE i,
  lv_balance  TYPE i,
  lv_overlap  TYPE zelm_leave-leave_id,
  lv_number   TYPE n LENGTH 10,
  lv_existing TYPE zelm_leave-leave_id,
  lv_found    TYPE abap_bool.

START-OF-SELECTION.

  "======================================
  " 1. Validate Employee
  "======================================
  SELECT SINGLE *
    FROM zelm_employee
    WHERE emp_id = @p_empid
    INTO @ls_employee.

  IF sy-subrc <> 0.
    MESSAGE 'Employee does not exist' TYPE 'E'.
  ENDIF.

  "======================================
  " 2. Validate Dates
  "======================================
  IF p_start > p_end.
    MESSAGE 'Start date cannot exceed end date' TYPE 'E'.
  ENDIF.

  IF p_start < sy-datum.
    MESSAGE 'Leave start date cannot be in the past' TYPE 'E'.
  ENDIF.

  "======================================
  " 3. Calculate Leave Days
  "======================================
  lv_days = p_end - p_start + 1.

  IF lv_days <= 0.
    MESSAGE 'Invalid leave duration' TYPE 'E'.
  ENDIF.

  "======================================
  " 4. Check Available Balance
  "======================================
  lv_balance = ls_employee-total_leave
             - ls_employee-used_leave.

  IF lv_days > lv_balance.
    MESSAGE 'Insufficient leave balance' TYPE 'E'.
  ENDIF.

  "======================================
  " 5. Check Overlapping Leave Requests
  "======================================
  SELECT SINGLE leave_id
    FROM zelm_leave
    WHERE emp_id = @p_empid
      AND status IN ( 'PENDING', 'APPROVED' )
      AND start_date <= @p_end
      AND end_date >= @p_start
    INTO @lv_overlap.

  IF sy-subrc = 0.
    MESSAGE 'Overlapping leave request exists' TYPE 'E'.
  ENDIF.

  "======================================
  " 6. Generate Leave ID using SNRO
  "======================================
  lv_found = abap_false.

  DO 10 TIMES.

    CLEAR lv_number.

    CALL FUNCTION 'NUMBER_GET_NEXT'
      EXPORTING
        nr_range_nr = '01'
        object      = 'ZELM_LVNR'
        quantity    = '1'
      IMPORTING
        number      = lv_number
      EXCEPTIONS
        interval_not_found        = 1
        number_range_not_intern   = 2
        object_not_found         = 3
        quantity_is_0            = 4
        quantity_is_not_1        = 5
        interval_overflow        = 6
        buffer_overflow          = 7
        OTHERS                   = 8.

    IF sy-subrc <> 0.
      MESSAGE 'Number range allocation failed' TYPE 'E'.
    ENDIF.

    ls_leave-leave_id = lv_number.

    CLEAR lv_existing.

    SELECT SINGLE leave_id
      FROM zelm_leave
      WHERE leave_id = @ls_leave-leave_id
      INTO @lv_existing.

    IF sy-subrc <> 0.
      lv_found = abap_true.
      EXIT.
    ENDIF.

  ENDDO.

  IF lv_found = abap_false.
    MESSAGE 'Could not allocate unique Leave ID' TYPE 'E'.
  ENDIF.

  "======================================
  " 7. Prepare Leave Request
  "======================================
  ls_leave-mandt       = sy-mandt.
  ls_leave-emp_id      = p_empid.
  ls_leave-start_date  = p_start.
  ls_leave-end_date    = p_end.
  ls_leave-leave_days  = lv_days.
  ls_leave-reason      = p_reasn.
  ls_leave-status      = 'PENDING'.

  "======================================
  " 8. Insert Leave Request
  "======================================
  INSERT zelm_leave FROM @ls_leave.

  IF sy-subrc = 0.

    COMMIT WORK.

    WRITE: / 'Leave application submitted!',
           / 'Leave ID:', ls_leave-leave_id,
           / 'Employee ID:', p_empid,
           / 'Start Date:', p_start,
           / 'End Date:', p_end,
           / 'Leave Days:', lv_days,
           / 'Status: PENDING',
           / 'Available Balance:', lv_balance.

  ELSE.

    ROLLBACK WORK.
    MESSAGE 'Leave request could not be saved' TYPE 'E'.

  ENDIF.