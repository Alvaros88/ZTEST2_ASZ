CLASS zcl_aux_travel_det_1940 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES: tt_travel_reported      TYPE TABLE FOR REPORTED z_i_travel_1940,
           tt_booking_reported     TYPE TABLE FOR REPORTED z_i_booking_1940,
           tt_supplements_reported TYPE TABLE FOR  REPORTED z_i_booksuppl_log_1940,
           tt_travel_id            TYPE TABLE OF /dmo/travel_id.

    CLASS-METHODS calculate_price IMPORTING it_travel_id TYPE tt_travel_id.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_aux_travel_det_1940 IMPLEMENTATION.

  METHOD calculate_price.

    DATA: lv_total_booking_price TYPE /dmo/total_price,
          lv_total_suppl_price   TYPE /dmo/total_price.

    IF it_travel_id IS INITIAL.
      RETURN.
    ENDIF.

    READ ENTITIES OF z_i_travel_1940
        ENTITY Travel
        FIELDS ( TravelId CurrencyCode )
        WITH VALUE #( FOR ls_travel_id IN it_travel_id ( TravelId = ls_travel_id ) )
        RESULT DATA(lt_read_travel).

    " Se leen las reservas que tienen que ver con el/los viajes recuperados
    " Solo aquellos viajes que han sido modificados
    READ ENTITIES OF z_i_travel_1940
        ENTITY Travel BY \_Booking
        FROM VALUE #( FOR lv_travel_id IN it_travel_id (
                            TravelId = lv_travel_id
                            %control-FlightPrice  = if_abap_behv=>mk-on
                            %control-CurrencyCode = if_abap_behv=>mk-on ) )
        RESULT DATA(lt_read_booking).

" Se recorren las reservas recuperadas anteriormente
    LOOP AT lt_read_booking INTO DATA(ls_booking)
        GROUP BY ls_booking-TravelId INTO DATA(lv_travel_key).

      " Se asigna la estructura del viaje en un field-symbol para actualizar directamente sobre el fs
      ASSIGN lt_read_travel[ KEY entity COMPONENTS TravelId = lv_travel_key ] TO FIELD-SYMBOL(<ls_travel>).

      LOOP AT GROUP lv_travel_key INTO DATA(ls_booking_result)
          GROUP BY ls_booking_result-CurrencyCode INTO DATA(lv_curr).
        " Se recorren las reservas agrupadas por monedas

        " Se inicializa por cada reserva
        lv_total_booking_price = 0.

        LOOP AT GROUP lv_curr INTO DATA(ls_booking_line).
          " Se recorre la agrupación de cada moneda y se incremente el precio de cada reserva
          lv_total_booking_price += ls_booking_line-FlightPrice.
        ENDLOOP.

        " Se comprueba la moneda de la reserva, si es la misma se incrementa
        " En caso contrario, se realiza la conversión a la moneda del viaje y después se incrementa"
        IF lv_curr EQ <ls_travel>-CurrencyCode.
          <ls_travel>-TotalPrice += lv_total_booking_price.
        ELSE.
          " Se realiza la conversión de la moneda
          /dmo/cl_flight_amdp=>convert_currency(
          EXPORTING
              iv_amount                 = lv_total_booking_price
              iv_currency_code_source   = lv_curr
              iv_currency_code_target   = <ls_travel>-CurrencyCode
              iv_exchange_rate_date     = cl_abap_context_info=>get_system_date( )
          IMPORTING
              ev_amount                 = DATA(lv_amount_converted) ).

          <ls_travel>-TotalPrice += lv_amount_converted.

        ENDIF.

      ENDLOOP.

    ENDLOOP.


    " Se leen los suplementos que tienen que ver con el/los viajes/reservas recuperados
    " Solo aquellos suplementos que han sido modificados el precio o la moneda
    READ ENTITIES OF z_i_travel_1940
        ENTITY Booking BY \_BookingSupplement
        FROM VALUE #( FOR ls_travel IN lt_read_booking (
                            TravelId                = ls_travel-TravelId
                            BookingId               = ls_travel-BookingId
                            %control-price          = if_abap_behv=>mk-on
                            %control-CurrencyCode   = if_abap_behv=>mk-on ) )
        RESULT DATA(lt_read_supplements).

 " Se reccorren los suplementos recuperados anteriormente
    LOOP AT lt_read_supplements INTO DATA(ls_booking_suppl)
        GROUP BY ls_booking_suppl-TravelId INTO lv_travel_key.

      " Se asigna la estructura del suplemento en un field-symbol para actualizar directamente sobre el fs
      ASSIGN lt_read_travel[ KEY entity COMPONENTS TravelId = lv_travel_key ] TO <ls_travel>.

      LOOP AT GROUP lv_travel_key INTO DATA(ls_supplements_result)
          GROUP BY ls_supplements_result-CurrencyCode INTO lv_curr.
        " Se recorren los suplementos agrupadas por monedas

        " Se inicializa por cada suplemento
        lv_total_suppl_price = 0.

        LOOP AT GROUP lv_curr INTO DATA(ls_supplement_line).
          " Se recorre la agrupación de cada moneda y se incremente el precio del suplemento
          lv_total_suppl_price += ls_supplement_line-price.
        ENDLOOP.

        " Se comprueba la moneda del suplemento, si es la misma se incrementa
        " En caso contrario, se realiza la conversión a la moneda del viaje y después se incrementa"
        IF lv_curr EQ <ls_travel>-CurrencyCode.
          <ls_travel>-TotalPrice += lv_total_suppl_price.
        ELSE.
          " Se realiza la conversión de la moneda
          /dmo/cl_flight_amdp=>convert_currency(
          EXPORTING
              iv_amount                 = lv_total_suppl_price
              iv_currency_code_source   = lv_curr
              iv_currency_code_target   = <ls_travel>-CurrencyCode
              iv_exchange_rate_date     = cl_abap_context_info=>get_system_date( )
          IMPORTING
              ev_amount                 = lv_amount_converted ).

          <ls_travel>-TotalPrice += lv_amount_converted.

        ENDIF.

      ENDLOOP.

    ENDLOOP.


    " Se modifica la entidad raiz con el valor del total price
    MODIFY ENTITIES OF z_i_travel_1940
        ENTITY Travel
        UPDATE FROM VALUE #( FOR ls_travel_bo IN lt_read_travel (
                                    TravelId = ls_travel_bo-TravelId
                                    TotalPrice = ls_travel_bo-TotalPrice
                                    %control-TotalPrice = if_abap_behv=>mk-on ) ).

  ENDMETHOD.

ENDCLASS.
