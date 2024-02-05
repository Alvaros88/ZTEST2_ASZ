CLASS zcl_ext_update_ent_1940 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_ext_update_ent_1940 IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    MODIFY ENTITIES OF z_i_travel_1940
        ENTITY Travel
        UPDATE FIELDS ( AgencyId Description )
        WITH VALUE #( ( TravelId = '000000001'
                        AgencyId = '070017'
                        Description = 'New external Update' ) )
        FAILED DATA(failed)
        REPORTED DATA(reported).

    READ ENTITIES OF z_i_travel_1940
        ENTITY Travel
        FIELDS ( AgencyId Description )
        WITH VALUE #( ( TravelId = '000000001' ) )
        RESULT DATA(lt_travel_data)
        FAILED failed
        REPORTED reported.

    " Se controla manualmente el commit entities porque estamos fuera
    " de las clases de comportamiento
    COMMIT ENTITIES.

    IF failed IS INITIAL.
      out->write( 'Commit Sucessfull' ).
    ELSE.
      out->write( 'Commit Failed' ).
    ENDIF.


  ENDMETHOD.

ENDCLASS.
