*&---------------------------------------------------------------------*
*& Report ZELM_LEAVE_DASHBOARD
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*



REPORT zelm_leave_dashboard.

TABLES: zelm_leave.

"====================================================
" ALV STRUCTURE
"====================================================
TYPES: BEGIN OF ty_leave,
         leave_id    TYPE zelm_leave-leave_id,
         emp_id      TYPE zelm_leave-emp_id,
         emp_name    TYPE zelm_employee-emp_name,
         department  TYPE zelm_employee-department,
         start_date  TYPE zelm_leave-start_date,
         end_date    TYPE zelm_leave-end_date,
         leave_days  TYPE zelm_leave-leave_days,
         reason      TYPE zelm_leave-reason,
         status      TYPE zelm_leave-status,
         approved_by TYPE zelm_leave-approved_by,
         total_leave TYPE zelm_employee-total_leave,
         used_leave  TYPE zelm_employee-used_leave,
         balance     TYPE i,
       END OF ty_leave.

"====================================================
" GLOBAL DATA
"====================================================
DATA:
  lt_leave      TYPE STANDARD TABLE OF ty_leave,
  lo_alv        TYPE REF TO cl_salv_table,
  lo_columns    TYPE REF TO cl_salv_columns_table,
  lo_column     TYPE REF TO cl_salv_column_table,
  lo_selections TYPE REF TO cl_salv_selections,
  lo_events     TYPE REF TO cl_salv_events_table.

"====================================================
" EVENT HANDLER
"====================================================
CLASS lcl_event_handler DEFINITION.
  PUBLIC SECTION.
    METHODS on_user_command
      FOR EVENT added_function OF cl_salv_events_table
      IMPORTING e_salv_function.
ENDCLASS.

DATA lo_handler TYPE REF TO lcl_event_handler.

"====================================================
" SELECTION SCREEN
"====================================================
SELECT-OPTIONS:
  s_emp FOR zelm_leave-emp_id.

PARAMETERS:
  p_pend RADIOBUTTON GROUP sts DEFAULT 'X',
  p_all  RADIOBUTTON GROUP sts.

"====================================================
" EVENT HANDLER IMPLEMENTATION
"====================================================
CLASS lcl_event_handler IMPLEMENTATION.

  METHOD on_user_command.

    DATA:
      lt_rows TYPE salv_t_row,
      lv_row  TYPE i,
      ls_row  TYPE ty_leave,
      lv_act  TYPE c LENGTH 1.

    CASE e_salv_function.
      WHEN 'ZAPPROVE'.
        lv_act = 'A'.
      WHEN 'ZREJECT'.
        lv_act = 'R'.
      WHEN OTHERS.
        RETURN.
    ENDCASE.

    "Get selected ALV row
    lt_rows = lo_selections->get_selected_rows( ).

    IF lines( lt_rows ) <> 1.
      MESSAGE 'Please select exactly one leave request'
        TYPE 'I'.
      RETURN.
    ENDIF.

    READ TABLE lt_rows INTO lv_row INDEX 1.
    READ TABLE lt_leave INTO ls_row INDEX lv_row.

    IF sy-subrc <> 0.
      MESSAGE 'Selected row could not be read'
        TYPE 'I'.
      RETURN.
    ENDIF.

    IF ls_row-status <> 'PENDING'.
      MESSAGE 'Only pending requests can be processed'
        TYPE 'I'.
      RETURN.
    ENDIF.

    PERFORM process_leave
      USING ls_row-leave_id lv_act.

  ENDMETHOD.

ENDCLASS.

"====================================================
" MAIN PROGRAM
"====================================================
START-OF-SELECTION.

  PERFORM load_data.

  IF lt_leave IS INITIAL.
    MESSAGE 'No leave applications found' TYPE 'I'.
    RETURN.
  ENDIF.

  PERFORM display_alv.

"====================================================
" LOAD DATA
"====================================================
FORM load_data.

  CLEAR lt_leave.

  SELECT
    l~leave_id,
    l~emp_id,
    e~emp_name,
    e~department,
    l~start_date,
    l~end_date,
    l~leave_days,
    l~reason,
    l~status,
    l~approved_by,
    e~total_leave,
    e~used_leave
    FROM zelm_leave AS l
    INNER JOIN zelm_employee AS e
      ON l~emp_id = e~emp_id
    WHERE l~emp_id IN @s_emp
    INTO CORRESPONDING FIELDS OF TABLE @lt_leave.

  IF p_pend = 'X'.
    DELETE lt_leave WHERE status <> 'PENDING'.
  ENDIF.

  LOOP AT lt_leave ASSIGNING FIELD-SYMBOL(<ls_leave>).
    <ls_leave>-balance =
      <ls_leave>-total_leave -
      <ls_leave>-used_leave.
  ENDLOOP.

ENDFORM.

"====================================================
" PROCESS APPROVAL OR REJECTION
"====================================================
FORM process_leave
  USING p_leave_id TYPE zelm_leave-leave_id
        p_action   TYPE c.

  DATA:
    ls_request  TYPE zelm_leave,
    ls_employee TYPE zelm_employee,
    lv_empid    TYPE zelm_employee-emp_id,
    lv_balance  TYPE i,
    lv_error    TYPE string.

  "Read request before locking
  SELECT SINGLE *
    FROM zelm_leave
    WHERE leave_id = @p_leave_id
    INTO @ls_request.

  IF sy-subrc <> 0.
    MESSAGE 'Leave request not found' TYPE 'I'.
    RETURN.
  ENDIF.

  lv_empid = ls_request-emp_id.

  "Lock employee
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
    MESSAGE 'Employee locked by another user'
      TYPE 'I'.
    RETURN.
  ENDIF.

  "Re-read request after acquiring lock
  CLEAR ls_request.

  SELECT SINGLE *
    FROM zelm_leave
    WHERE leave_id = @p_leave_id
    INTO @ls_request.

  IF sy-subrc <> 0 OR ls_request-emp_id <> lv_empid.
    lv_error = 'Leave request changed or not found'.
  ELSEIF ls_request-status <> 'PENDING'.
    lv_error = 'Leave request already processed'.
  ENDIF.

  IF lv_error IS INITIAL.

    SELECT SINGLE *
      FROM zelm_employee
      WHERE emp_id = @lv_empid
      INTO @ls_employee.

    IF sy-subrc <> 0.
      lv_error = 'Employee not found'.
    ENDIF.

  ENDIF.

  "Approval logic
  IF lv_error IS INITIAL AND p_action = 'A'.

    lv_balance = ls_employee-total_leave -
                 ls_employee-used_leave.

    IF ls_request-leave_days <= 0 OR
       ls_request-leave_days > lv_balance.

      lv_error = 'Insufficient balance or invalid days'.

    ELSE.

      ls_employee-used_leave =
        ls_employee-used_leave +
        ls_request-leave_days.

      UPDATE zelm_employee FROM @ls_employee.

      IF sy-subrc <> 0.
        lv_error = 'Employee balance update failed'.
      ELSE.
        ls_request-status = 'APPROVED'.
      ENDIF.

    ENDIF.

  ELSEIF lv_error IS INITIAL AND p_action = 'R'.

    ls_request-status = 'REJECTED'.

  ELSEIF lv_error IS INITIAL.

    lv_error = 'Invalid action'.

  ENDIF.

  "Update request
  IF lv_error IS INITIAL.

    ls_request-approved_by = sy-uname.

    UPDATE zelm_leave FROM @ls_request.

    IF sy-subrc <> 0.
      lv_error = 'Leave status update failed'.
    ENDIF.

  ENDIF.

  IF lv_error IS INITIAL.
    COMMIT WORK AND WAIT.
  ELSE.
    ROLLBACK WORK.
  ENDIF.

  "Release employee lock
  CALL FUNCTION 'DEQUEUE_EZELM_EMPLOYEE'
    EXPORTING
      mandt  = sy-mandt
      emp_id = lv_empid.

  IF lv_error IS NOT INITIAL.
    MESSAGE lv_error TYPE 'I'.
    RETURN.
  ENDIF.

  "Refresh dashboard
  PERFORM load_data.

  lo_alv->refresh(
    refresh_mode = if_salv_c_refresh=>full ).

  IF p_action = 'A'.
    MESSAGE 'Leave approved successfully' TYPE 'S'.
  ELSE.
    MESSAGE 'Leave rejected successfully' TYPE 'S'.
  ENDIF.

ENDFORM.

"====================================================
" DISPLAY ALV
"====================================================
FORM display_alv.

  TRY.

      cl_salv_table=>factory(
        IMPORTING
          r_salv_table = lo_alv
        CHANGING
          t_table      = lt_leave ).

      lo_alv->get_functions( )->set_all( abap_true ).

      lo_selections = lo_alv->get_selections( ).

      lo_selections->set_selection_mode(
        if_salv_c_selection_mode=>single ).

      lo_alv->set_screen_status(
        pfstatus      = 'ZLEAVE_STATUS'
        report        = sy-repid
        set_functions = lo_alv->c_functions_all ).

      lo_columns = lo_alv->get_columns( ).
      lo_columns->set_optimize( abap_true ).

      lo_alv->get_display_settings(
        )->set_striped_pattern( abap_true ).

      "Column headings
      PERFORM set_columns.

      lo_events = lo_alv->get_event( ).

      CREATE OBJECT lo_handler.

      SET HANDLER lo_handler->on_user_command
        FOR lo_events.

      lo_alv->display( ).

    CATCH cx_salv_msg INTO DATA(lx_msg).
      MESSAGE lx_msg->get_text( ) TYPE 'E'.

    CATCH cx_salv_not_found.
      MESSAGE 'ALV column not found' TYPE 'E'.

  ENDTRY.

ENDFORM.

"====================================================
" CUSTOM COLUMN HEADINGS
"====================================================
FORM set_columns.

  lo_column ?= lo_columns->get_column( 'LEAVE_ID' ).
  lo_column->set_short_text( 'Leave ID' ).
  lo_column->set_medium_text( 'Leave ID' ).
  lo_column->set_long_text( 'Leave Request ID' ).

  lo_column ?= lo_columns->get_column( 'EMP_ID' ).
  lo_column->set_short_text( 'Emp ID' ).
  lo_column->set_medium_text( 'Employee ID' ).
  lo_column->set_long_text( 'Employee ID' ).

  lo_column ?= lo_columns->get_column( 'EMP_NAME' ).
  lo_column->set_short_text( 'Emp Name' ).
  lo_column->set_medium_text( 'Employee Name' ).
  lo_column->set_long_text( 'Employee Name' ).

  lo_column ?= lo_columns->get_column( 'DEPARTMENT' ).
  lo_column->set_short_text( 'Dept' ).
  lo_column->set_medium_text( 'Department' ).
  lo_column->set_long_text( 'Employee Department' ).

  lo_column ?= lo_columns->get_column( 'START_DATE' ).
  lo_column->set_short_text( 'Start Date' ).
  lo_column->set_medium_text( 'Start Date' ).
  lo_column->set_long_text( 'Leave Start Date' ).

  lo_column ?= lo_columns->get_column( 'END_DATE' ).
  lo_column->set_short_text( 'End Date' ).
  lo_column->set_medium_text( 'End Date' ).
  lo_column->set_long_text( 'Leave End Date' ).

  lo_column ?= lo_columns->get_column( 'LEAVE_DAYS' ).
  lo_column->set_short_text( 'Days' ).
  lo_column->set_medium_text( 'Leave Days' ).
  lo_column->set_long_text( 'Number of Leave Days' ).

  lo_column ?= lo_columns->get_column( 'REASON' ).
  lo_column->set_short_text( 'Reason' ).
  lo_column->set_medium_text( 'Leave Reason' ).
  lo_column->set_long_text( 'Reason for Leave' ).

  lo_column ?= lo_columns->get_column( 'STATUS' ).
  lo_column->set_short_text( 'Status' ).
  lo_column->set_medium_text( 'Status' ).
  lo_column->set_long_text( 'Approval Status' ).

  lo_column ?= lo_columns->get_column( 'APPROVED_BY' ).
  lo_column->set_short_text( 'Approver' ).
  lo_column->set_medium_text( 'Approved By' ).
  lo_column->set_long_text( 'Approved By User' ).

  lo_column ?= lo_columns->get_column( 'TOTAL_LEAVE' ).
  lo_column->set_short_text( 'Total' ).
  lo_column->set_medium_text( 'Total Leave' ).
  lo_column->set_long_text( 'Total Leave Entitlement' ).

  lo_column ?= lo_columns->get_column( 'USED_LEAVE' ).
  lo_column->set_short_text( 'Used' ).
  lo_column->set_medium_text( 'Used Leave' ).
  lo_column->set_long_text( 'Used Leave Days' ).

  lo_column ?= lo_columns->get_column( 'BALANCE' ).
  lo_column->set_short_text( 'Balance' ).
  lo_column->set_medium_text( 'Balance' ).
  lo_column->set_long_text( 'Available Leave Balance' ).

ENDFORM.