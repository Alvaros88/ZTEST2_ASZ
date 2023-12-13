CLASS lhc_Booking DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS calculateTotalFlightPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Booking~calculateTotalFlightPrice.

    METHODS validateStatus FOR VALIDATE ON SAVE
      IMPORTING keys FOR Booking~validateStatus.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Booking RESULT result.

ENDCLASS.

CLASS lhc_Booking IMPLEMENTATION.

  METHOD calculateTotalFlightPrice.

    IF keys IS NOT INITIAL.
      " Se llama al método de la clase auxiliar creada previamente
      " Se recoore la tabla interna KEYS agrupando la información por el TravelId
      zcl_aux_travel_det_1940=>calculate_price( it_travel_id =
                                        VALUE #( FOR GROUPS <fs_booking> OF booking_key IN keys
                                                     GROUP BY booking_key-TravelId WITHOUT MEMBERS ( <fs_booking> )  )  ).
    ENDIF.

  ENDMETHOD.

  METHOD validateStatus.


    READ ENTITY z_i_travel_1940\\Booking
      FIELDS ( BookingStatus )
      WITH VALUE #( FOR <row_key> IN keys ( %key = <row_key>-%key ) )
      RESULT DATA(lt_booking_result).

    LOOP AT lt_booking_result INTO DATA(ls_booking_result).
      CASE ls_booking_result-BookingStatus.
        WHEN 'N'. " New
        WHEN 'X'. " Cancelled
        WHEN 'B'. " Booked
        WHEN OTHERS.

          " Si el estado no está permitido devolvemos un error
          APPEND VALUE #( %key = ls_booking_result-%key ) TO failed-booking.

          " Añadimos los valores que vamos a reportar en la tabla interna reported con los mensajes
          APPEND VALUE #( %key                      = ls_booking_result-%key
                          %msg                      = new_message( id = 'Z_MC_TRAVEL_1940'
                          number                    = '008'
                          v1                        = ls_booking_result-BookingId
                          severity                  = if_abap_behv_message=>severity-error )
                          %element-BookingStatus    = if_abap_behv=>mk-on ) TO reported-booking.
      ENDCASE.
    ENDLOOP.


  ENDMETHOD.

  METHOD get_instance_features.

    READ ENTITIES OF z_i_travel_1940 IN LOCAL MODE
      ENTITY Booking
      FIELDS ( BookingId BookingDate CustomerId BookingStatus )
      WITH VALUE #( FOR ls_key IN keys ( %key = ls_key-%key ) )
      RESULT DATA(lt_booking_result) .

    result = VALUE #( FOR ls_booking IN lt_booking_result (
                          %key                    = ls_booking-%key
                          %assoc-_BookingSupplement         = if_abap_behv=>fc-o-enabled  ) ). " Habilitamos la navegación a la asociación

  ENDMETHOD.

ENDCLASS.
