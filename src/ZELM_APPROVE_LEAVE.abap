*&---------------------------------------------------------------------*
*& Report ZELM_APPROVE_LEAVE
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*

REPORT zelm_approve_leave.

PARAMETERS:
  p_lid TYPE zelm_leave-leave_id OBLIGATORY.

PARAMETERS:
  p_app RADIOBUTTON GROUP act DEFAULT 'X',
  p_rej RADIOBUTTON GROUP act.

DATA:
  ls_leave    TYPE zelm_leave,
  ls_employee TYPE zelm_employee,
  lv_balance  TYPE i,
  lv_approver TYPE syuname,
  lv_empid    TYPE zelm_employee-emp_id.

START-OF-SELECTION.

  "Read request to identify employee
  SELECT SINGLE *
    FROM zelm_leave
    WHERE leave_id = @p_lid
    INTO @ls_leave.

  IF sy-subrc <> 0.
    MESSAGE 'Leave request not found' TYPE 'E'.
  ENDIF.

  lv_empid = ls_leave-emp_id.

  "Acquire exclusive employee lock
  CALL FUNCTION 'ENQUEUE_EZELM_EMPLOYEE'
    EXPORTING
      mode_zelm_employee = 'E'
      mandt              = sy-mandt
      emp_id             = lv_empid
      _wait              = 'X'
    EXCEPTIONS
      foreign_lock       = 1
      system_failure     = 2
      OTHERS             = 3.

  IF sy-subrc <> 0.
    MESSAGE 'Employee is locked by another user' TYPE 'E'.
  ENDIF.

  "Re-read request after acquiring lock
  SELECT SINGLE *
    FROM zelm_leave
    WHERE leave_id = @p_lid
    INTO @ls_leave.

  IF sy-subrc <> 0 OR ls_leave-emp_id <> lv_empid.
    PERFORM release_lock.
    MESSAGE 'Leave request changed or not found' TYPE 'E'.
  ENDIF.

  IF ls_leave-status <> 'PENDING'.
    PERFORM release_lock.
    MESSAGE 'Leave request already processed' TYPE 'E'.
  ENDIF.

  "Read latest employee balance
  SELECT SINGLE *
    FROM zelm_employee
    WHERE emp_id = @lv_empid
    INTO @ls_employee.

  IF sy-subrc <> 0.
    PERFORM release_lock.
    MESSAGE 'Employee not found' TYPE 'E'.
  ENDIF.

  lv_approver = sy-uname.

  IF p_app = 'X'.

    lv_balance = ls_employee-total_leave
               - ls_employee-used_leave.

    IF ls_leave-leave_days > lv_balance
       OR ls_leave-leave_days <= 0.
      PERFORM release_lock.
      MESSAGE 'Invalid days or insufficient balance' TYPE 'E'.
    ENDIF.

    ls_employee-used_leave =
      ls_employee-used_leave + ls_leave-leave_days.

    UPDATE zelm_employee FROM @ls_employee.

    IF sy-subrc <> 0.
      ROLLBACK WORK.
      PERFORM release_lock.
      MESSAGE 'Balance update failed' TYPE 'E'.
    ENDIF.

    ls_leave-status = 'APPROVED'.

  ELSE.
    ls_leave-status = 'REJECTED'.
  ENDIF.

  ls_leave-approved_by = lv_approver.

  UPDATE zelm_leave FROM @ls_leave.

  IF sy-subrc = 0.

    COMMIT WORK.

    PERFORM release_lock.

    WRITE: / 'Leave request processed successfully',
           / 'Leave ID:', p_lid,
           / 'Employee ID:', lv_empid,
           / 'Status:', ls_leave-status,
           / 'Leave Days:', ls_leave-leave_days.

  ELSE.

    ROLLBACK WORK.
    PERFORM release_lock.
    MESSAGE 'Leave update failed' TYPE 'E'.

  ENDIF.

FORM release_lock.
  CALL FUNCTION 'DEQUEUE_EZELM_EMPLOYEE'
    EXPORTING
      mandt  = sy-mandt
      emp_id = lv_empid.
ENDFORM.