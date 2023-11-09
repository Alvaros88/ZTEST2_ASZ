@EndUserText.label: 'Consumption - Travel Approval'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
define root view entity z_c_atravel_1940 
as projection on z_i_travel_1940
{
    key TravelId,
    @ObjectModel.text.element: [ 'AgencyName' ]
    AgencyId,
      _Agency.Name as AgencyName,
    @ObjectModel.text.element: [ 'CustomerName' ]
    CustomerId,
    _Customer.LastName as CustomerName,
    BeginDate,
    EndDate,
    @Semantics.amount.currencyCode: 'CurrencyCode'
    BookingFee,
    @Semantics.amount.currencyCode: 'CurrencyCode'
    TotalPrice,
    @Semantics.currencyCode: true
    CurrencyCode,
    Description,
    OverallStatus as TravelStatus,
    CreatedBy,
    CreatedAt,
    LastChangedBy,
    LastChangedAt,
    /* Associations */
    _Agency,
    _Booking : redirected to composition child z_c_abooking_1940,
    _Currency,
    _Customer
}
