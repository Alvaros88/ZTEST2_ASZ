CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

*// Métodos referentes a las acciones
    METHODS:  acceptTravel           FOR MODIFY IMPORTING keys FOR ACTION Travel~acceptTravel            RESULT result,
      createTravelByTemplate FOR MODIFY IMPORTING keys FOR ACTION Travel~createTravelByTemplate  RESULT result,
      rejectTravel           FOR MODIFY IMPORTING keys FOR ACTION Travel~rejectTravel            RESULT result.

*// Métodos referentes a las validaciones
    METHODS:  validateCustomer   FOR VALIDATE ON SAVE IMPORTING keys FOR Travel~validateCustomer,
      validateDates      FOR VALIDATE ON SAVE IMPORTING keys FOR Travel~validateDates,
      validateStatus     FOR VALIDATE ON SAVE IMPORTING keys FOR Travel~validateStatus.

    METHODS get_instance_features FOR INSTANCE FEATURES IMPORTING keys REQUEST requested_features FOR Travel RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.

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
                          %assoc-_Booking         = if_abap_behv=>fc-o-enabled " Habilitamos la navegación a la asociación
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

    " Si es mi usuario personal, permitimos, en caso contrario no está autorizado
    "  CB9980008597
    DATA(lv_auth) = COND #( WHEN cl_abap_context_info=>get_user_technical_name( ) EQ 'CB9980005806' "'CB9980008597'
                            THEN if_abap_behv=>auth-allowed
                            ELSE if_abap_behv=>auth-unauthorized ).

    " Se recorren las instancias para autorizar o denegar los permisos correspondientes
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<fs_keys>).

      APPEND INITIAL LINE TO result ASSIGNING FIELD-SYMBOL(<fs_result>).

      <fs_result> = VALUE #(  %key = <fs_keys>-%key
                              %op-%update                       = lv_auth " if_abap_behv=>auth-allowed
                              %delete                           = lv_auth "''
                              %action-acceptTravel              = lv_auth " if_abap_behv=>auth-allowed
                              %action-rejectTravel              = lv_auth " if_abap_behv=>auth-allowed
                              %action-createTravelByTemplate    = lv_auth " if_abap_behv=>auth-allowed
                              %assoc-_Booking                   = lv_auth ).

    ENDLOOP.

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

    LOOP AT lt_travel ASSIGNING FIELD-SYMBOL(<fs_travel>).

      " Para formatear el ID
      DATA(lv_travel_msg) =  <fs_travel>-TravelId.
      SHIFT lv_travel_msg LEFT DELETING LEADING '0'.

      " Añadimos los valores que vamos a reportar en la tabla interna reported con los mensajes
      APPEND VALUE #( travelId = <fs_travel>-TravelId
       %msg  = new_message(   id       = 'Z_MC_TRAVEL_1940'
                              number   =  '006'
                              severity =  if_abap_behv_message=>severity-success " Constante de la interfaz para indicar el tipo de mensaje
                              v1       =  lv_travel_msg  )
      %element-customerid = if_abap_behv=>mk-on )  TO reported-travel.
    ENDLOOP.

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

    LOOP AT lt_travel ASSIGNING FIELD-SYMBOL(<fs_travel>).

      " Para formatear el ID
      DATA(lv_travel_msg) =  <fs_travel>-TravelId.
      SHIFT lv_travel_msg LEFT DELETING LEADING '0'.

      " Añadimos los valores que vamos a reportar en la tabla interna reported con los mensajes
      APPEND VALUE #( travelId = <fs_travel>-TravelId
       %msg  = new_message(   id       = 'Z_MC_TRAVEL_1940'
                              number   =  '007'
                              severity =  if_abap_behv_message=>severity-success " Constante de la interfaz para indicar el tipo de mensaje
                              v1       =  lv_travel_msg  )
      %element-customerid = if_abap_behv=>mk-on )  TO reported-travel.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateCustomer.

    " Se recuperan los customer de la entidad para la validación
    READ ENTITIES OF z_i_travel_1940 IN LOCAL MODE
      ENTITY Travel
      FIELDS ( CustomerId )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_travel). " Se vuelca el resultado en la tabla interna

    DATA: lt_customer TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id.

    " Movemos los datos a la tabla interna descartando los duplicados de la tabla interna lt_travel
    " Mapeando el campo necesario y exceptuando el resto de campos
    lt_customer = CORRESPONDING #( lt_travel DISCARDING DUPLICATES MAPPING customer_id = CustomerId EXCEPT * ).

    " Se eliminan los campos en blanco
    DELETE lt_customer WHERE customer_id IS INITIAL.

    " Se recuperan los clientes de la BBDD
    SELECT FROM  /dmo/customer FIELDS customer_id
        FOR ALL ENTRIES IN @lt_customer
        WHERE customer_id EQ @lt_customer-customer_id
        INTO TABLE @DATA(lt_customer_db).

    " Se recorren los clientes de la entidad lt_travel, para verificar que existe
    LOOP AT lt_travel ASSIGNING FIELD-SYMBOL(<fs_travel>).

      IF  <fs_travel>-CustomerId IS INITIAL OR
      NOT line_exists( lt_customer_db[ customer_id = <fs_travel>-CustomerId ] ). " Si no existe en la tabla interna de BBD

        " Añadimos el error de la validación
        APPEND VALUE #( travelId = <fs_travel>-TravelId ) TO failed-travel.

        " Añadimos los valores que vamos a reportar en la tabla interna reported con los mensajes
        APPEND VALUE #( travelId = <fs_travel>-TravelId
         %msg  = new_message(   id       = 'Z_MC_TRAVEL_1940'
                                number   =  '001'
                                severity =  if_abap_behv_message=>severity-error " Constante de la interfaz para indicar el error
                                v1       =  <fs_travel>-TravelId  )
        %element-customerid = if_abap_behv=>mk-on )  TO reported-travel.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validateDates.

    " Se recupera la entidad Travel
    READ ENTITY z_i_travel_1940\\Travel
        FIELDS ( BeginDate EndDate )
        WITH VALUE #( FOR <row_key> IN keys ( %key = <row_key>-%key ) )
        RESULT DATA(lt_travel_result).

    LOOP AT lt_travel_result INTO DATA(ls_travel_result).

      IF ls_travel_result-EndDate LT ls_travel_result-BeginDate. "fecha fin anterior a fecha inicio
        " Añadimos el error de la validación
        APPEND VALUE #( %key     = ls_travel_result-%key
                        travelid = ls_travel_result-travelid ) TO failed-travel.

        " Añadimos los valores que vamos a reportar en la tabla interna reported con los mensajes
        APPEND VALUE #( %key = ls_travel_result-%key
                        %msg                = new_message( id = 'Z_MC_TRAVEL_1940'
                        number              = '003'
                        v1                  = ls_travel_result-BeginDate
                        v2                  = ls_travel_result-EndDate
                        v3                  = ls_travel_result-travelid
                        severity            = if_abap_behv_message=>severity-error )
                        %element-BeginDate = if_abap_behv=>mk-on
                        %element-EndDate   = if_abap_behv=>mk-on ) TO reported-travel.

      ELSEIF ls_travel_result-BeginDate < cl_abap_context_info=>get_system_date( ). " Fecha de inicio debe ser en futuro
        " Añadimos el error de la validación
        APPEND VALUE #( %key        = ls_travel_result-%key
                        travelid    = ls_travel_result-travelid ) TO failed-travel.
        " Añadimos los valores que vamos a reportar en la tabla interna reported con los mensajes
        APPEND VALUE #( %key                = ls_travel_result-%key
                        %msg                = new_message( id = 'Z_MC_TRAVEL_1940'
                        number              = '002'
                        severity            = if_abap_behv_message=>severity-error )
                        %element-BeginDate  = if_abap_behv=>mk-on
                        %element-EndDate    = if_abap_behv=>mk-on ) TO reported-travel.

      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD validateStatus.

    READ ENTITY z_i_travel_1940\\Travel
      FIELDS ( OverallStatus )
      WITH VALUE #( FOR <row_key> IN keys ( %key = <row_key>-%key ) )
      RESULT DATA(lt_travel_result).

    LOOP AT lt_travel_result INTO DATA(ls_travel_result).
      CASE ls_travel_result-OverallStatus.
        WHEN 'O'. " Open
        WHEN 'X'. " Cancelled
        WHEN 'A'. " Accepted
        WHEN OTHERS.

          " Si el estado no está permitido devolvemos un error
          APPEND VALUE #( %key = ls_travel_result-%key ) TO failed-travel.

          " Añadimos los valores que vamos a reportar en la tabla interna reported con los mensajes
          APPEND VALUE #( %key                      = ls_travel_result-%key
                          %msg                      = new_message( id = 'Z_MC_TRAVEL_1940'
                          number                    = '004'
                          v1                        = ls_travel_result-OverallStatus
                          severity                  = if_abap_behv_message=>severity-error )
                          %element-OverallStatus    = if_abap_behv=>mk-on ) TO reported-travel.
      ENDCASE.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

CLASS lsc_Z_I_TRAVEL_1940 DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PUBLIC SECTION.

    CONSTANTS: create TYPE string VALUE 'CREATE',
               update TYPE string VALUE 'UPDATE',
               delete TYPE string VALUE 'DELETE'.

  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_Z_I_TRAVEL_1940 IMPLEMENTATION.

  METHOD save_modified.

    DATA: lt_travel_log        TYPE STANDARD TABLE OF zlog_1940, "z_i_log_1940, "zlog_1940,
          ls_travel_log        TYPE zlog_1940,
          lt_travel_log_update TYPE STANDARD TABLE OF zlog_1940. "z_i_log_1940. " zlog_1940.

    DATA(lv_user) = cl_abap_context_info=>get_user_technical_name( ).

    IF create-travel IS NOT INITIAL.
      " Si la entidad no es inicial, significa que se ha creado un nuevo viaje
      lt_travel_log = CORRESPONDING #( create-travel ).

      LOOP AT lt_travel_log ASSIGNING FIELD-SYMBOL(<fs_travel_log>).
        GET TIME STAMP FIELD <fs_travel_log>-createdat.
        <fs_travel_log>-changing_operation = lsc_z_i_travel_1940=>create.

        " Recomendable siempre realizar la lectura de los valores de entrada en una estructura, en lugar de field-symbols
        " para evitar hacer modificaciones no deseadas sobre los parámetros de entrada
        READ TABLE create-travel WITH TABLE KEY entity COMPONENTS TravelId = <fs_travel_log>-travel_id INTO DATA(ls_travel).
        IF sy-subrc NE 0.
          CLEAR: ls_travel.
        ELSE.

          " En este punto de la lógica se añaden todos los campos que se deseen añadir para tener el log de modificaciones en la tabla Z
          " a nivel de auditoria
          IF ls_travel-%control-BookingFee EQ cl_abap_behv=>flag_changed.
            " Si hay un cambio en el Bookingfee
            <fs_travel_log>-change_field_name   = 'Booking_fee'.
            <fs_travel_log>-change_field_value  = ls_travel-BookingFee.
            <fs_travel_log>-user_mod            = lv_user.
            TRY.
                <fs_travel_log>-change_id           = cl_system_uuid=>create_uuid_x16_static( ).
              CATCH cx_uuid_error.
            ENDTRY.

            APPEND <fs_travel_log> TO lt_travel_log_update.

          ENDIF.

        ENDIF.

      ENDLOOP.


    ENDIF.

    IF update-travel IS NOT INITIAL.
      " Si la entidad no es inicial, significa que se ha actualizado un viaje
*      lt_travel_log = CORRESPONDING #( update-travel ).

      LOOP AT update-travel ASSIGNING FIELD-SYMBOL(<fs_travel>).
        " No funciona la sentencia de arriba (corresponding), ya que los campos no se llaman iguales
        CLEAR: ls_travel_log.
        ls_travel_log-travel_id = <fs_travel>-TravelId.
        APPEND ls_travel_log TO lt_travel_log.
      ENDLOOP.


      " Recomendable siempre realizar la lectura de los valores de entrada en una estructura, en lugar de field-symbols
      " para evitar hacer modificaciones no deseadas sobre los parámetros de entrada
      LOOP AT update-travel INTO DATA(ls_update_travel).

*        ASSIGN lt_travel_log[ travel_id = ls_update_travel-TravelId ] TO FIELD-SYMBOL(<fs_travel_log_bd>).
        LOOP AT lt_travel_log ASSIGNING FIELD-SYMBOL(<fs_travel_log_bd>) WHERE travel_id EQ ls_update_travel-TravelId .

          GET TIME STAMP FIELD <fs_travel_log_bd>-createdat.
          <fs_travel_log_bd>-changing_operation = lsc_z_i_travel_1940=>update.

          " En este punto de la lógica se añaden todos los campos que se deseen añadir para tener el log de modificaciones en la tabla Z
          " a nivel de auditoria
          IF ls_update_travel-%control-CustomerId EQ cl_abap_behv=>flag_changed.
            <fs_travel_log_bd>-change_field_name   = 'customer_id'.
            <fs_travel_log_bd>-change_field_value  = ls_update_travel-CustomerId.
            <fs_travel_log_bd>-user_mod            = lv_user.
            TRY.
                <fs_travel_log_bd>-change_id           = cl_system_uuid=>create_uuid_x16_static( ).
              CATCH cx_uuid_error.
            ENDTRY.

            APPEND <fs_travel_log_bd> TO lt_travel_log_update.

          ENDIF.

        ENDLOOP.

      ENDLOOP.

    ENDIF.

    IF delete-travel IS NOT INITIAL.
      " Si la entidad no es inicial, significa que se ha eliminado un viaje
      lt_travel_log = CORRESPONDING #( delete-travel ).

      LOOP AT lt_travel_log ASSIGNING FIELD-SYMBOL(<fs_travel_log_del>).

        GET TIME STAMP FIELD <fs_travel_log_del>-createdat.
        <fs_travel_log_del>-changing_operation = lsc_z_i_travel_1940=>delete.
        <fs_travel_log_del>-user_mod            = lv_user.

        TRY.
            <fs_travel_log_del>-change_id           = cl_system_uuid=>create_uuid_x16_static( ).
          CATCH cx_uuid_error.
        ENDTRY.

        APPEND <fs_travel_log_del> TO lt_travel_log_update.

      ENDLOOP.

    ENDIF.


    IF lt_travel_log_update IS NOT INITIAL.
      " Si hay valores, es que se ha realizado alguna operación, almacenamos en BBDD
      INSERT zlog_1940 FROM TABLE @lt_travel_log_update.
    ENDIF.

  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
