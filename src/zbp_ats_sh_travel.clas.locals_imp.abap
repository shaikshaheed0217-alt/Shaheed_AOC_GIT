CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PUBLIC SECTION .

    TYPES : t_entity_create TYPE TABLE FOR CREATE zats_sh_travel,
            T_ENTITY_update TYPE TABLE FOR UPDATE zats_sh_travel,
            t_entity_rep    TYPE TABLE FOR REPORTED zats_sh_travel,
            t_entity_fai    TYPE TABLE FOR FAILED   zats_sh_travel.

  PRIVATE         SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Travel RESULT result.
    METHODS copyTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~copyTravel.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Travel RESULT result.
    METHODS recalctotalprice FOR MODIFY
      IMPORTING keys FOR ACTION travel~recalctotalprice.

    METHODS calculatetotalprice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR travel~calculatetotalprice.
    METHODS validateheaderdata FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel~validateheaderdata.
    METHODS precheck_create FOR PRECHECK
      IMPORTING entities FOR CREATE travel.

    METHODS precheck_update FOR PRECHECK
      IMPORTING entities FOR UPDATE travel.

    METHODS accepttravel FOR MODIFY
      IMPORTING keys FOR ACTION travel~accepttravel RESULT result.

    METHODS rejecttravel FOR MODIFY
      IMPORTING keys FOR ACTION travel~rejecttravel RESULT result.
*    METHODS precheck_create FOR PRECHECK
*      IMPORTING entities FOR CREATE travel.
*
*    METHODS precheck_update FOR PRECHECK
*      IMPORTING entities FOR UPDATE travel.
    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE Travel.

    METHODS earlynumbering_cba_Booking FOR NUMBERING
      IMPORTING entities FOR CREATE Travel\_Booking.

    METHODS Currency_conversion IMPORTING iv_amount               TYPE /dmo/total_price
                                          iv_currency_code_source TYPE /dmo/currency_code
                                          iv_currency_code_target TYPE /dmo/currency_code
                                          iv_exchange_rate_date   TYPE d
                                RETURNING VALUE(re_amount)        TYPE /dmo/total_price.

    METHODS precheck_shaheed_reuse
      IMPORTING entities_u TYPE t_entity_update OPTIONAL
                entities_c TYPE t_entity_create OPTIONAL
      EXPORTING reported   TYPE t_entity_rep
                failed     TYPE t_entity_fai.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_instance_authorizations.

    READ ENTITIES OF zats_sh_travel IN LOCAL MODE
    ENTITY travel
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel_data) .

    LOOP AT lt_travel_data ASSIGNING FIELD-SYMBOL(<fs_travel_data>).

      IF <fs_travel_data>-OverallStatus EQ 'X' .

        APPEND VALUE #( TravelId = <fs_travel_data>-travelid
*                        %is_draft = <fs_travel_data>-%is_draft
                        %update  = if_abap_behv=>auth-unauthorized
                        %action-copyTravel  = if_abap_behv=>auth-unauthorized  ) TO result .



      ENDIF .
    ENDLOOP .


  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD earlynumbering_create.

    DATA(lt_entities_with_travelid) = entities .
    DATA(lt_entities_wo_travelid)   = entities .

    DELETE lt_entities_with_travelid WHERE TravelId IS INITIAL .
    DELETE lt_entities_wo_travelid WHERE TravelId IS NOT INITIAL .

    IF lt_entities_with_travelid IS NOT INITIAL  .
      mapped-travel = CORRESPONDING #(  lt_entities_with_travelid ) .
    ENDIF .


    "Step2-->Get the Sequence no from the SNRO
    TRY .
        cl_numberrange_runtime=>number_get(
          EXPORTING
            nr_range_nr       = '01'
            object            = CONV #( '/DMO/TRAVL'   )
            quantity          = CONV #( lines( lt_entities_wo_travelid ) )
          IMPORTING
            number            = DATA(lv_number)
            returncode        = DATA(lv_return_code)
            returned_quantity = DATA(lv_returned_quantity)
        ).
      CATCH cx_nr_object_not_found.
      CATCH cx_number_ranges INTO DATA(ls_number_range).
        LOOP AT lt_entities_wo_travelid ASSIGNING FIELD-SYMBOL(<fs_entity>).
          APPEND VALUE #( %cid = <fs_entity>-%cid
                          %key = <fs_entity>-%key
                          %msg = ls_number_range ) TO reported-travel.

          APPEND VALUE #( %cid = <fs_entity>-%cid
                          %key = <fs_entity>-%key
                        ) TO failed-travel.



        ENDLOOP.
    ENDTRY .

    "Step6-->Final Check for all Number(s)

    ASSERT lv_returned_quantity = lines(  lt_entities_wo_travelid ) .

    "Step7-->Loop over incoming travel data and assign the number from number range and return
    "mapped data which will go

    lv_number = lv_number - 1  .

    LOOP AT lt_entities_wo_travelid ASSIGNING FIELD-SYMBOL(<fs_wo>) .

      lv_number = lv_number + 1 .

      <fs_wo>-TravelId = lv_number .

      APPEND VALUE #(  %cid = <fs_wo>-%cid
                       %key = <fs_wo>-%key
                       %is_draft = <fs_wo>-%is_draft ) TO mapped-travel .


    ENDLOOP .

  ENDMETHOD.

  METHOD earlynumbering_cba_Booking.

    READ ENTITIES OF zats_sh_travel IN LOCAL MODE
     ENTITY travel BY \_Booking
     FROM CORRESPONDING #( entities )
     LINK DATA(Lt_bookings) .

    "-->Getting the Hight Booking .

    SORT lt_bookings BY target-BookingId DESCENDING .

    DATA(lv_booking_no) = VALUE #(  lt_bookings[ 1 ]-target-BookingId OPTIONAL ) .

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<fs_travel>) .

      LOOP AT <fs_travel>-%target ASSIGNING FIELD-SYMBOL(<ls>) USING  KEY entity WHERE TravelId = <fs_travel>-TravelId  .

        IF sy-subrc EQ 0 .

          IF lv_booking_no IS INITIAL AND <ls>-BookingId IS INITIAL .
            lv_booking_no = 10 .
          ELSEIF  ( lv_booking_no IS INITIAL OR lv_booking_no IS NOT INITIAL ) AND <ls>-BookingId IS NOT INITIAL  .

            lv_booking_no = <ls>-BookingId.
          ELSE.
            lv_booking_no = lv_booking_no + 10 .

          ENDIF .
        ENDIF .

        APPEND CORRESPONDING #( <lS> ) TO mapped-booking ASSIGNING FIELD-SYMBOL(<fs_mp>).
        <fs_mp>-BookingId = lv_booking_no .
        <fs_mp>-%is_draft = <ls>-%is_draft.
      ENDLOOP .

    ENDLOOP.
*




  ENDMETHOD.

  METHOD copyTravel.

    DATA : lt_travels   TYPE TABLE FOR CREATE zats_sh_travel\\travel,
           lt_booking   TYPE TABLE FOR CREATE ZATS_sH_TRAVEL\\travel\_Booking,
           lt_booksuppl TYPE TABLE FOR CREATE zats_sh_travel\\Booking\_BookingSupplement.


    "Step1: Remove the Travel Instances with Initial %CID

    DATA(lv_key) = VALUE #( keys[  %cid = ' ' ] OPTIONAL ).

    ASSERT lv_key IS INITIAL .

    "Step2: Read all travel, booking, BookingSupplement using EML
    READ ENTITIES OF zats_sh_travel IN LOCAL MODE
    ENTITY travel
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel_read_data)
    FAILED DATA(lt_travel_fail_data).

    READ ENTITIES OF zats_sh_travel IN LOCAL MODE
    ENTITY travel BY \_Booking
    ALL FIELDS WITH CORRESPONDING #( lt_travel_read_data )
    RESULT DATA(lt_booking_read_data)
    FAILED DATA(lt_booking_fail_data).

    READ ENTITIES OF zats_sh_travel IN LOCAL MODE
    ENTITY booking BY \_BookingSupplement
    ALL FIELDS WITH CORRESPONDING #( lt_booking_read_data )
    RESULT DATA(lt_bookSuppl_read_data)
    FAILED DATA(lt_bookSuppl_fail_data).

    "Step3: Fill travel internal table for travel data creation - %CID

    LOOP AT lt_travel_read_data ASSIGNING FIELD-SYMBOL(<fs_travel_read_data>).

      APPEND VALUE #( %cid   = VALUE         #( keys[ %tky = <fs_travel_read_data>-%tky ]-%cid OPTIONAL )
                      %data  = CORRESPONDING #(  <fs_travel_read_data> EXCEPT travelid )
                    ) TO lt_travels ASSIGNING FIELD-SYMBOL(<fs_travels>).

      "Begin date :

      <fs_travels>-BeginDate = cl_abap_context_info=>get_system_date( ) .
      <fs_travels>-EndDate   = cl_abap_context_info=>get_system_date( ) + 30 .
      <fs_travels>-OverallStatus = 'O' .

      "Step4: Fill Booking Internal table for booking data creation - %CID_REF

      APPEND VALUE #(  %cid_ref =  VALUE         #( keys[  %tky = <fs_travel_read_data>-%tky ]-%cid OPTIONAL )
                    ) TO lt_booking ASSIGNING FIELD-SYMBOL(<fs_booking>) .

      LOOP AT lt_booking_read_data ASSIGNING FIELD-SYMBOL(<fs_booking_read_data>)   WHERE TravelId = <fs_travel_read_data>-TravelId .

        APPEND VALUE #(  %cid  =   keys[  %tky = <fs_travel_read_data>-%tky ]-%cid  && <fs_booking_read_data>-BookingId
                         %data =  CORRESPONDING #(  <fs_booking_read_data>  EXCEPT travelid )
                       ) TO <fs_booking>-%target ASSIGNING FIELD-SYMBOL(<fs_book>) .

        <fs_book>-BookingStatus = 'N' .


        "Step5: Fill Booking Supplement internal table for booking Supplement data creation

        APPEND VALUE #( %cid_ref =  keys[  %tky = <fs_travel_read_data>-%tky ]-%cid  && <fs_booking_read_data>-BookingId
                      ) TO lt_booksuppl ASSIGNING FIELD-SYMBOL(<fs_bookSuppl>) .

        LOOP AT lt_booksuppl_read_data ASSIGNING FIELD-SYMBOL(<fs_booksuppl_read_data>) WHERE TravelId = <fs_travel_read_data>-TravelId
                                                                                          AND   BookingId = <fs_booking_read_data>-BookingId.


          APPEND VALUE #(  %cid  =   keys[   %tky = <fs_travel_read_data>-%tky ]-%cid  && <fs_booking_read_data>-BookingId && <fs_booksuppl_read_data>-BookingSupplementId
                           %data  =  CORRESPONDING #(  <fs_booksuppl_read_data>  EXCEPT travelid bookingid )
                        ) TO <fs_booksuppl>-%target ASSIGNING FIELD-SYMBOL(<fs_book_suppl>) .


        ENDLOOP .
      ENDLOOP .
    ENDLOOP .
    "Step6: Modify Entity EML to create New BO instance using Existing data.
    MODIFY ENTITIES OF zats_sh_travel IN LOCAL MODE
        ENTITY Travel
        CREATE FIELDS (  AgencyId
                         BeginDate
                         BookingFee
                         CreatedAt
                         CreatedBy
                         CurrencyCode
                         CustomerId
                         Description
                         EndDate
                         OverallStatus
                         TotalPrice
                         )
        WITH lt_travels
        CREATE BY \_Booking FIELDS (  BookingId
                                      BookingStatus
                                      BookingDate
                                      CarrierId
                                      ConnectionId
                                      CurrencyCode
                                      CustomerId
                                      FlightDate
                                      FlightPrice
                                      LastChangedAt
                                    )
        WITH lt_booking
        ENTITY Booking
        CREATE BY \_BookingSupplement FIELDS ( BookingSupplementId CurrencyCode  Price SupplementId  )
        WITH lt_booksuppl
        MAPPED DATA(lt_mapped_data).

    mapped-travel = lt_mapped_data-travel .


  ENDMETHOD.

  METHOD get_instance_features.

    "Step1-->Read the Travel data :
    READ ENTITIES OF zats_sh_travel IN LOCAL MODE
     ENTITY travel
      FIELDS (  TravelId OverallStatus )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_travels)
      FAILED DATA(lt_failed) .

    "Step2-->Return the Return    :

    DATA(lv_status) = VALUE #(  lt_travels[ 1 ]-OverallStatus OPTIONAL ) .

    DATA(lv_allow)  = COND #(  WHEN lv_status EQ 'X'  THEN if_abap_behv=>fc-o-disabled
                               ELSE  if_abap_behv=>fc-o-enabled ).

    result = VALUE #(  FOR <fs> IN lt_travels
                        (  %tky = <fs>-%tky
                           %assoc-_Booking = lv_allow
                           %action-acceptTravel  = COND #(  WHEN lv_status EQ 'A' THEN
                                                            if_abap_behv=>fc-o-disabled
                                                            ELSE if_abap_behv=>fc-o-enabled

                                                          )
                          %action-rejectTravel = COND #(  WHEN lv_status EQ 'X' THEN
                                                            if_abap_behv=>fc-o-disabled
                                                            ELSE if_abap_behv=>fc-o-enabled )
                                                          )
                    ) .



  ENDMETHOD.

  METHOD reCalcTotalPrice.

    READ ENTITIES OF zats_sh_travel IN LOCAL MODE
     ENTITY travel
     ALL FIELDS WITH CORRESPONDING #( keys )
     RESULT DATA(lt_travel) .

    READ ENTITIES OF zats_sh_travel IN LOCAL MODE
    ENTITY travel BY \_Booking
    ALL FIELDS WITH CORRESPONDING #( lt_travel )
    RESULT DATA(lt_booking) .

    READ ENTITIES OF zats_sh_travel IN LOCAL MODE
    ENTITY Booking BY \_BookingSupplement
    ALL FIELDS WITH CORRESPONDING #(  lt_booking )
    RESULT DATA(lt_bookSuppl) .

    LOOP AT lt_travel ASSIGNING FIELD-SYMBOL(<fs_travel>).



      DATA(lv_booking_amount) = REDUCE /dmo/flight_price( INIT total TYPE /dmo/flight_price
                                                          FOR <fs_booking> IN lt_booking

                                                          WHERE (  TravelId = <fs_travel>-TravelId )
                                                          NEXT total = total + COND #( WHEN <fs_travel>-CurrencyCode EQ <fs_booking>-CurrencyCode THEN <fs_booking>-FlightPrice
                                                                                       ELSE currency_conversion(
                                                                                              iv_amount               = <fs_booking>-FlightPrice
                                                                                              iv_currency_code_source = <fs_booking>-CurrencyCode
                                                                                              iv_currency_code_target = <fs_travel>-CurrencyCode
                                                                                              iv_exchange_rate_date   = cl_abap_context_info=>get_system_date( )
                                                                                            ) ) ) .

      DATA(lv_booksuppl_amount) = REDUCE /dmo/supplement_price( INIT total TYPE /dmo/supplement_price
                                                                FOR <fs_bookSuppl> IN lt_booksuppl

                                                                WHERE (  TravelId = <fs_travel>-TravelId )
                                                                NEXT total = total + COND #( WHEN <fs_travel>-CurrencyCode EQ <fs_booksuppl>-CurrencyCode THEN <fs_booksuppl>-Price
                                                                                       ELSE currency_conversion(
                                                                                              iv_amount               = <fs_booksuppl>-Price
                                                                                              iv_currency_code_source = <fs_booksuppl>-CurrencyCode
                                                                                              iv_currency_code_target = <fs_travel>-CurrencyCode
                                                                                             iv_exchange_rate_date   = cl_abap_context_info=>get_system_date( )
                                                                                            ) ) ) .

      <fs_travel>-TotalPrice = <fs_travel>-BookingFee + lv_booking_amount + lv_booksuppl_amount .

    ENDLOOP .

    MODIFY ENTITIES OF zats_sh_travel IN LOCAL MODE
    ENTITY travel
    UPDATE FIELDS (  TotalPrice )
    WITH CORRESPONDING #(  lt_travel ) .

  ENDMETHOD.

  METHOD calculateTotalPrice.

    MODIFY ENTITIES OF zats_sh_travel IN LOCAL MODE
    ENTITY Travel
    EXECUTE reCalcTotalPrice
    FROM CORRESPONDING #(  keys ).

  ENDMETHOD.

  METHOD currency_conversion.

    /dmo/cl_flight_amdp=>convert_currency(
     EXPORTING
       iv_amount               = iv_amount
       iv_currency_code_source = iv_currency_code_source
       iv_currency_code_target = iv_currency_code_target
       iv_exchange_rate_date   = iv_exchange_rate_date
      IMPORTING
      ev_amount                = re_amount
     ).

  ENDMETHOD.

  METHOD validateHeaderData.

    READ ENTITIES OF zats_sh_travel IN LOCAL MODE
    ENTITY Travel
    ALL FIELDS WITH CORRESPONDING #(  keys  )
    RESULT DATA(lt_travel_data) .

    DATA : lt_customer TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id .

    lt_customer = CORRESPONDING #( lt_travel_data DISCARDING DUPLICATES
                                   MAPPING customer_id = CustomerId EXCEPT * ) .

    DELETE lt_customer WHERE customer_id IS INITIAL .

    IF lt_customer IS NOT INITIAL .

      SELECT FROM /dmo/customer FIELDS customer_id
      FOR ALL ENTRIES IN @lt_customer
      WHERE customer_id = @lt_customer-customer_id
      INTO TABLE @DATA(lt_cust) .

    ENDIF .

    LOOP AT lt_travel_data ASSIGNING FIELD-SYMBOL(<fs_travel_data>).

      IF (  <fs_travel_data>-CustomerId IS INITIAL OR
            NOT line_exists( lt_cust[ customer_id = <fs_travel_data>-CustomerId ] ) ) .

        APPEND VALUE #(  %tky = <fs_travel_data>-%tky  ) TO failed-travel .

        APPEND VALUE #(  %tky = <fs_travel_data>-%tky
                         %element-customerid = if_abap_behv=>mk-on
                         %msg = NEW /dmo/cm_flight_messages(
                                       textid                = /dmo/cm_flight_messages=>customer_unkown
                                       customer_id           = <fs_travel_data>-customerid
                                       severity              = if_abap_behv_message=>severity-error )

                       ) TO reported-travel .

      ENDIF .


    ENDLOOP .

  ENDMETHOD.

*  METHOD precheck_create.
*
**    me->precheck_shaheed_reuse(
**      EXPORTING
**       entities_c = entities
**      IMPORTING
**        reported   = reported-travel
**        failed     = failed-travel
**    ).
*
*  ENDMETHOD.
*
*  METHOD precheck_update.
*
**    me->precheck_shaheed_reuse(
**    EXPORTING
**     entities_u = entities
**    IMPORTING
**      reported   = reported-travel
**      failed     = failed-travel
**  ).
*
*  ENDMETHOD.

  METHOD precheck_shaheed_reuse.

    DATA: lt_agency   TYPE SORTED TABLE OF /dmo/agency WITH UNIQUE KEY agency_id,
          lt_customer TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id,
          lt_entites  TYPE t_entity_update.

    IF entities_c IS NOT INITIAL .
      lt_entites =  CORRESPONDING #(  entities_c )  .
      DATA(lv_operation) = 'C'.
    ELSEIF entities_u IS NOT INITIAL .
      lt_entites = CORRESPONDING #(   entities_u ).
      lv_operation = 'U'.
    ENDIF .

    DELETE lt_entites WHERE %control-AgencyId     = if_abap_behv=>mk-off AND
                            %control-CustomerId   = if_abap_behv=>mk-off .

    lt_agency    = CORRESPONDING #( lt_entites DISCARDING DUPLICATES MAPPING agency_id = AgencyId EXCEPT * ).
    lt_customer  = CORRESPONDING #(  lt_entites DISCARDING DUPLICATES MAPPING customer_id = CustomerId EXCEPT * ).

    SELECT FROM /dmo/agency FIELDS agency_id , country_code
    FOR ALL ENTRIES IN @lt_agency
    WHERE agency_id = @lt_agency-agency_id
    INTO TABLE @DATA(lt_agency_table).


    SELECT FROM /dmo/customer FIELDS customer_id , country_code
    FOR ALL ENTRIES IN @lt_customer
    WHERE customer_id = @lt_customer-customer_id
    INTO TABLE @DATA(lt_customer_table).

    LOOP AT lt_entites ASSIGNING FIELD-SYMBOL(<fs_entites>).

      DATA(ls_agency_country_code)   = VALUE #( lt_agency_table[ agency_id = <fs_entites>-AgencyId ]-country_code OPTIONAL ).
      DATA(ls_customer_country_code) = VALUE #(  lt_customer_table[ customer_id = <fs_entites>-CustomerId  ]-country_code OPTIONAL  ).
      IF ls_agency_country_code NE ls_customer_country_code .

        APPEND VALUE #(  %cid = COND #(  WHEN lv_operation = 'C' THEN <fs_entites>-%cid_ref )
                         %is_draft = <fs_entites>-%is_draft
                         %fail-cause = if_abap_behv=>cause-conflict ) TO failed .

        APPEND VALUE #(  %cid = COND #(  WHEN lv_operation = 'C' THEN <fs_entites>-%cid_ref )
                         %is_draft = <fs_entites>-%is_draft
                         %msg = NEW /dmo/cm_flight_messages(
          textid                = VALUE #(  msgid = 'SY' msgno = 499 attr1 = 'The Country Code not matched')
          agency_id             = <fs_entites>-AgencyId
          customer_id           = <fs_entites>-CustomerId
          severity              = if_abap_behv_message=>severity-error )
          %element-agencyid     = if_abap_behv=>mk-on
        ) TO reported.




      ENDIF .

    ENDLOOP.


  ENDMETHOD.

  METHOD precheck_create.
  ENDMETHOD.

  METHOD precheck_update.
  ENDMETHOD.

  METHOD acceptTravel.

    MODIFY ENTITIES OF zats_sh_travel IN LOCAL MODE
    ENTITY travel
    UPDATE FIELDS (  OverallStatus  )
    WITH VALUE #(  FOR key IN keys (    %tky = key-%tky
                                        %is_draft = key-%is_draft
                                        OverallStatus = 'A' ) )  .

    READ ENTITIES OF zats_sh_travel IN LOCAL MODE
    ENTITY travel
    ALL FIELDS WITH CORRESPONDING #(  keys )
    RESULT DATA(lt_data).

    result = VALUE #(  FOR travel IN lt_data (  %tky = travel-%tky %param = travel ) )  .

  ENDMETHOD.

  METHOD rejectTravel.

    MODIFY ENTITIES OF zats_sh_travel IN LOCAL MODE
      ENTITY travel
      UPDATE FIELDS (  OverallStatus  )
      WITH VALUE #(  FOR key IN keys (    %tky = key-%tky
                                          %is_draft = key-%is_draft
                                          OverallStatus = 'X' ) )  .

    READ ENTITIES OF zats_sh_travel IN LOCAL MODE
    ENTITY travel
    ALL FIELDS WITH CORRESPONDING #(  keys )
    RESULT DATA(lt_data).

    result = VALUE #(  FOR travel IN lt_data (  %tky = travel-%tky %param = travel ) )  .

  ENDMETHOD.

ENDCLASS.
