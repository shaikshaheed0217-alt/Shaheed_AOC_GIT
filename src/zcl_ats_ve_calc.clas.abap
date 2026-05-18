CLASS zcl_ats_ve_calc DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_sadl_exit .
    INTERFACES if_sadl_exit_calc_element_read .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_ATS_VE_CALC IMPLEMENTATION.


  METHOD if_sadl_exit_calc_element_read~calculate.

    IF it_original_data IS NOT INITIAL .

      DATA : lt_calc_data TYPE TABLE OF zats_sh_travel_processor WITH DEFAULT KEY,
             lv_rate      TYPE p DECIMALS 2 VALUE '0.025'.

      lt_calc_data = CORRESPONDING #(  it_original_data ) .

      LOOP AT lt_calc_data ASSIGNING FIELD-SYMBOL(<FS_calc_data>).

        <fs_calc_data>-CO2Tax = <fs_calc_data>-TotalPrice * lv_rate .

        cl_scal_utils=>date_compute_day(
          EXPORTING
            iv_date           = <fs_calc_data>-BeginDate
          IMPORTING
*            ev_weekday_number =
            ev_weekday_name   = DATA(lv_name)
        ).

        <fs_calc_data>-dayOfFlight = lv_name  .

      ENDLOOP.

      ct_calculated_data = CORRESPONDING #(  lt_calc_data  ) .

    ENDIF .

  ENDMETHOD.


  METHOD if_sadl_exit_calc_element_read~get_calculation_info.
  ENDMETHOD.
ENDCLASS.
