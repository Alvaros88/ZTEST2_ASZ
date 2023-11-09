CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Travel RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS acceptTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~acceptTravel RESULT result.

    METHODS createTravelByTemplate FOR MODIFY
      IMPORTING keys FOR ACTION Travel~createTravelByTemplate RESULT result.

    METHODS rejectTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~rejectTravel RESULT result.

    METHODS validateCustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateCustomer.

    METHODS validateDates FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateDates.

    METHODS validateStatus FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateStatus.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_instance_features.

    READ ENTITIES OF z_i_travel_1940
    ENTITY Travel
    FIELDS ( TravelId OverallStatus )
    WITH VALUE #( FOR ls_key IN keys ( %key = ls_key-%key ) )
    RESULT DATA(lt_travel_result).

    result = VALUE #( FOR ls_travel IN lt_travel_result (
                          %key                    = ls_travel-%key
                          %field-TravelId         = if_abap_behv=>fc-f-read_only
                          %field-OverallStatus    = if_abap_behv=>fc-f-read_only
                          " Si tiene estado Aceptado, deshabilitamos la acción de aceptar
                          %action-acceptTravel    = COND #( WHEN ls_travel-OverallStatus = 'A'
                                                              THEN if_abap_behv=>fc-o-disabled
                                                              ELSE if_abap_behv=>fc-o-enabled )
                          " Si tiene estado Rechazado, deshabilitamos la acción de rechazar
                          %action-rejectTravel    = COND #( WHEN ls_travel-OverallStatus = 'X'
                                                              THEN if_abap_behv=>fc-o-disabled
                                                              ELSE if_abap_behv=>fc-o-enabled )  ) ).

  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD acceptTravel.

    " Modify In local mode - BO - Estas modificaciones no son relevantes para objetos de autorización
    " Se modifica la entidad con el valor de estado "A" = Aceptado
    MODIFY ENTITIES OF z_i_travel_1940 IN LOCAL MODE
        ENTITY Travel
        UPDATE FIELDS ( OverallStatus )
        WITH VALUE #( FOR ls_keys IN keys ( TravelId = ls_keys-TravelId
                                                  OverallStatus = 'A' ) )  " Aceptado
       FAILED failed
       REPORTED reported.

    READ ENTITIES OF  z_i_travel_1940 IN LOCAL MODE
        ENTITY Travel
        FIELDS (    AgencyId
                    CustomerId
                    BeginDate
                    EndDate
                    BookingFee
                    TotalPrice"
                    CurrencyCode
                    OverallStatus
                    Description
                    CreatedBy
                    CreatedAt
                    LastChangedBy
                    LastChangedAt )
        WITH VALUE #( FOR ls_keys1 IN keys ( TravelId = ls_keys1-TravelId ) )
        RESULT DATA(lt_travel).

    " Devolvemos al framework la entidad actualizada
    result = VALUE #( FOR ls_travel IN lt_travel ( TravelId = ls_travel-TravelId
                                                   %param   = ls_travel ) ).

  ENDMETHOD.

  METHOD createTravelByTemplate.

*  De la siguiente forma añadiendo - podemos observar los campos que contienen lo
*  keys[ 1 ]-
*  result[ 1 ]-
*  mapped-
*  failed- " Para reportar un error sobre alguna de las acciones de la entidad
*  reported- " Para reportar mensajes

    " Se lee el objeto de negocio en la entidad Travel
    READ ENTITIES OF z_i_travel_1940  " Para leer una de la entidades de la interfaz
        ENTITY Travel " Se indica la entidad que deseamos leer
        FIELDS ( TravelId AgencyId CustomerId BookingFee TotalPrice CurrencyCode ) " Se indican los campos de la entidad que deseamos recuperar
        WITH VALUE #( FOR ls_key IN keys ( %key = ls_key-%key ) )  " Se indican los valores con los que queremos filtrar. En este caso en base al parémtro de entrada en la firma "KEY"
        RESULT DATA(lt_entity_travel) " Volcamos el resultado en la tabla interna
        FAILED failed " Si hay error, se volcaría a la estructura failed
        REPORTED reported.

*    " También se puede leer directamente la entidad, ya que está acción ha sido definida en la propia entidad y obtenemos el mismo resultado que el anterior
*    READ ENTITY z_i_travel_1940 " Se indica la entidad que deseamos leer
*        FIELDS ( TravelId AgencyId CustomerId BookingFee TotalPrice CurrencyCode ) " Se indican los campos de la entidad que deseamos recuperar
*        WITH VALUE #( FOR ls_key IN keys ( %key = ls_key-%key ) )  " Se indican los valores con los que queremos filtrar. En este caso en base al parémtro de entrada en la firma "KEY"
*        RESULT lt_entity_travel " Volcamos el resultado en la tabla interna
*        FAILED failed " Si hay error, se volcaría a la estructura failed
*        REPORTED reported.

    CHECK failed IS INITIAL.

    DATA: lt_create_travel TYPE TABLE FOR CREATE z_i_travel_1940\\Travel.

    " Se recupera el último identificador del viaje
    SELECT MAX( travel_id )
        FROM ztravel_1940
        INTO @DATA(lv_travel_id).
    IF  sy-subrc NE 0.
      CLEAR: lv_travel_id.
    ENDIF.

    DATA(lv_today) = cl_abap_context_info=>get_system_date( ). " Se recupera la fecha actual

    " Se crean los datos del nuevo viaje, en base con la informado recuperada en la lectura del objeto de negocio
    lt_create_travel = VALUE #( FOR ls_entity_travel IN lt_entity_travel INDEX INTO lv_index
                                (   TravelId        = lv_travel_id + lv_index  " Para incrementar automáticamente el Identificador del viaje
                                    AgencyId        = ls_entity_travel-AgencyId
                                    CustomerId      = ls_entity_travel-CustomerId
                                    BeginDate       = lv_today  " Fecha actual
                                    EndDate         = lv_today + 30  " Fecha actual + 30
                                    BookingFee      = ls_entity_travel-BookingFee
                                    TotalPrice      = ls_entity_travel-TotalPrice
                                    CurrencyCode    = ls_entity_travel-CurrencyCode
                                    Description     = 'Add comments'
                                    OverallStatus   = 'O') ).

    " Se modifica el objeto de negocio pasandole los valores de la tabla interna anterior y los campos
    " Modifica el objeto de negocia hasta la capa de persistencia
    MODIFY ENTITIES OF z_i_travel_1940
     IN LOCAL MODE ENTITY Travel " Entidad que vamos a modificar
     CREATE FIELDS (    TravelId
                        AgencyId
                        CustomerId
                        BeginDate
                        EndDate
                        BookingFee
                        TotalPrice
                        CurrencyCode
                        Description
                        OverallStatus  )
                        WITH lt_create_travel
                        MAPPED mapped
                        FAILED failed
                        REPORTED reported.

    " A continuación, se devuelven los datos al framework para que tenga los resultados en la capa de la interfaz de usuario
    result = VALUE #( FOR ls_create_travel IN lt_create_travel INDEX INTO lv_index
                        ( %cid_ref  = keys[ lv_index ]-%cid_ref
                          %key      = keys[ lv_index ]-%key
                          %param    = CORRESPONDING #( ls_create_travel ) )  ).

  ENDMETHOD.

  METHOD rejectTravel.
    " Modify In local mode - BO - Estas modificaciones no son relevantes para objetos de autorización
    " Se modifica la entidad con el valor de estado "X" = Rechazado
    MODIFY ENTITIES OF z_i_travel_1940 IN LOCAL MODE
        ENTITY Travel
        UPDATE FIELDS ( OverallStatus )
        WITH VALUE #( FOR ls_keys IN keys ( TravelId = ls_keys-TravelId
                                                  OverallStatus = 'X' ) )  " Rechazado
       FAILED failed
       REPORTED reported.

    READ ENTITIES OF  z_i_travel_1940 IN LOCAL MODE
        ENTITY Travel
        FIELDS (    AgencyId
                    CustomerId
                    BeginDate
                    EndDate
                    BookingFee
                    TotalPrice"
                    CurrencyCode
                    OverallStatus
                    Description
                    CreatedBy
                    CreatedAt
                    LastChangedBy
                    LastChangedAt )
        WITH VALUE #( FOR ls_keys1 IN keys ( TravelId = ls_keys1-TravelId ) )
        RESULT DATA(lt_travel).

    " Devolvemos al framework la entidad actualizada
    result = VALUE #( FOR ls_travel IN lt_travel ( TravelId = ls_travel-TravelId
                                                   %param   = ls_travel ) ).
  ENDMETHOD.

  METHOD validateCustomer.
  ENDMETHOD.

  METHOD validateDates.
  ENDMETHOD.

  METHOD validateStatus.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_Z_I_TRAVEL_1940 DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_Z_I_TRAVEL_1940 IMPLEMENTATION.

  METHOD save_modified.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
