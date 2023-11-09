@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Interface -  Booking'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity z_i_booking_1940
  as select from zbooking_1940
  //  En la composición se indica la cardinalidad de la relación en este caso con la entidad "hijo"
  //  suplementos de la reserva, la composición se debe indicar como elemento de la entidad la asociación _BookingSupplement
  composition [0..*] of z_i_booksuppl_log_1940 as _BookingSupplement
  // Se crea la asociación con el objeto "Padre" para permitir la relación desde el objeto padre
  // Se debe indicar como elemento de la entidad la asociación _Travel
  association        to parent z_i_travel_1940        as _Travel on $projection.TravelId = _Travel.TravelId
  // Se indican las asociaciones estándar para los elementos de la entidad que correspondan, con la cardinalidad
  // como por ejemplo el ID de agencia, la moneda, etc… También se deben incluir los elementos de la asociación
  association [1..1] to /DMO/I_Customer        as _Customer      on $projection.CustomerId = _Customer.CustomerID
  association [1..1] to /DMO/I_Carrier         as _Carrier       on $projection.CarrierId = _Carrier.AirlineID
  association [1..*] to /DMO/I_Connection      as _Connection    on $projection.ConnectionId = _Connection.ConnectionID
{
  key travel_id      as TravelId,
  key booking_id     as BookingId,
      booking_date   as BookingDate,
      customer_id    as CustomerId,
      carrier_id     as CarrierId,
      connection_id  as ConnectionId,
      flight_date    as FlightDate,
      @Semantics.amount.currencyCode : 'CurrencyCode'
      flight_price   as FlightPrice,
      currency_code  as CurrencyCode,
      booking_status as BookingStatus,
      last_change_at as LastChangeAt,
      _Travel,
      _BookingSupplement,
      _Customer,
      _Carrier,
      _Connection
}
