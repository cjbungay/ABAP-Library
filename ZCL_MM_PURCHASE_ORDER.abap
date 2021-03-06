CLASS zcl_mm_purchase_order DEFINITION PUBLIC FINAL CREATE PRIVATE.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF t_key,
        ebeln TYPE ebeln,
      END OF t_key.

    CONSTANTS: BEGIN OF c_procstat,
                 approved         TYPE ekko-procstat VALUE '05',
                 waiting_approval type ekko-procstat value '03',
               END OF c_procstat.

    DATA gv_ebeln TYPE ebeln READ-ONLY.

    CLASS-METHODS:
      get_instance
        IMPORTING !is_key       TYPE t_key
        RETURNING VALUE(ro_obj) TYPE REF TO zcl_mm_purchase_order
        RAISING   cx_no_entry_in_table.

    methods:
      cancel_old_active_Workflows.

  PROTECTED SECTION.

  PRIVATE SECTION.

    TYPES:
      BEGIN OF t_multiton,
        key TYPE t_key,
        obj TYPE REF TO zcl_mm_purchase_order,
        cx  TYPE REF TO cx_no_entry_in_table,
      END OF t_multiton,

      tt_multiton
        TYPE HASHED TABLE OF t_multiton
        WITH UNIQUE KEY primary_key COMPONENTS key.

    CONSTANTS:
      begin of c_catid,
        business_object type sww_wi2obj-catid value 'BO',
      end of c_Catid,

      BEGIN OF c_tabname,
        def TYPE tabname VALUE 'EKKO',
      END OF c_tabname,

      begin of c_typeid,
        purchase_order type sww_wi2obj-typeid value 'BUS2012',
      end of c_typeid.

    CLASS-DATA gt_multiton TYPE tt_multiton.

    METHODS:
      constructor
        IMPORTING !is_key TYPE t_key
        RAISING   cx_no_entry_in_table.

ENDCLASS.

CLASS zcl_mm_purchase_order IMPLEMENTATION.

  method cancel_old_active_Workflows.

    zcl_bc_wf_Toolkit=>cancel_old_active_workflows(
        iv_catid  = c_Catid-business_object
        iv_instid = conv #( gv_ebeln )
        iv_typeid = c_typeid-purchase_order ).

  endmethod.

  METHOD constructor.

    SELECT SINGLE ebeln FROM ekko WHERE ebeln EQ @is_key-ebeln INTO @gv_ebeln.

    IF sy-subrc NE 0.
      RAISE EXCEPTION TYPE cx_no_entry_in_table
        EXPORTING
          table_name = CONV #( c_tabname-def )
          entry_name = |{ is_key-ebeln }|.
    ENDIF.

  ENDMETHOD.

  METHOD get_instance.

    ASSIGN gt_multiton[
        KEY primary_key COMPONENTS key = is_key
      ] TO FIELD-SYMBOL(<ls_multiton>).

    IF sy-subrc NE 0.
      DATA(ls_multiton) = VALUE t_multiton( key = is_key ).

      TRY.
          ls_multiton-obj = NEW #( ls_multiton-key ).
        CATCH cx_no_entry_in_table INTO ls_multiton-cx ##NO_HANDLER.
      ENDTRY.

      INSERT ls_multiton INTO TABLE gt_multiton ASSIGNING <ls_multiton>.
    ENDIF.

    IF <ls_multiton>-cx IS NOT INITIAL.
      RAISE EXCEPTION <ls_multiton>-cx.
    ENDIF.

    ro_obj = <ls_multiton>-obj.

  ENDMETHOD.

ENDCLASS.
