FUNCTION z_suppl_1940.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(IT_SUPPLEMENTS) TYPE  ZTT_SUPPL_1940
*"     REFERENCE(IV_OP_TYPE) TYPE  ZDE_FLAG_1940
*"  EXPORTING
*"     REFERENCE(EV_UPDATE) TYPE  ZDE_FLAG_1940
*"----------------------------------------------------------------------
  CHECK NOT it_supplements IS INITIAL.

  CASE iv_op_type.
    WHEN 'C'.
      INSERT zbooksuppl_1940 FROM TABLE @it_supplements.
    WHEN 'U'.
      UPDATE zbooksuppl_1940 FROM TABLE @it_supplements.
    WHEN 'D'.
      DELETE zbooksuppl_1940 FROM TABLE @it_supplements.
  ENDCASE.

  IF sy-subrc EQ 0.
    ev_update = abap_true.
  ENDIF.

ENDFUNCTION.
