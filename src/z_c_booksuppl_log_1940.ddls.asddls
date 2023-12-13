@EndUserText.label: 'Consumption - Booking Supplement'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
define view entity z_c_booksuppl_log_1940
  as projection on z_i_booksuppl_log_1940
{
  key TravelId,
  key BookingId,
  key BookingSupplementId,
      SupplementId,
      _SupplementText.Description as SupplementDescription : localized,
      @Semantics.amount.currencyCode : 'CurrencyCode'
      Price,
      @Semantics.currencyCode: true
      CurrencyCode,
      LastChangedAt,
      /* Associations */
      _Travel  : redirected to z_c_travel_1940,
      _Booking : redirected to parent z_c_booking_1940,
      _Product,
      _SupplementText
}
