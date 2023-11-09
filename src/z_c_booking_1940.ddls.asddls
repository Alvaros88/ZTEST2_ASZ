@EndUserText.label: 'Consumption - Booking'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
define view entity z_c_booking_1940
  as projection on z_i_booking_1940
{
  key TravelId,
  key BookingId,
      BookingDate,
      CustomerId,
      @ObjectModel.text.element: ['CarrierName']
      CarrierId,
      _Carrier.Name as CarrierName,
      ConnectionId,
      FlightDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      FlightPrice,
      @Semantics.currencyCode: true
      CurrencyCode,
      BookingStatus,
      LastChangeAt,
      /* Associations */
      _Travel            : redirected to parent z_c_travel_1940,
      _BookingSupplement : redirected to composition child z_c_booksuppl_log_1940,
      _Carrier,
      _Connection,
      _Customer

}
