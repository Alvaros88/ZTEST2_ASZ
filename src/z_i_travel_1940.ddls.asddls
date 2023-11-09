@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Interface -  Travel'
define root view entity z_i_travel_1940 //Z_I_TRAVEL_1940
  as select from ztravel_1940 as Travel
  // En la composición se indica la relación con el resto de entitys views
  // Indicando la carnidinalidad. Para incluir la entidad como composición la entidad
  // de la composición debe "permitirlo"
  composition [0..*] of z_i_booking_1940 as _Booking
  // Se indican las asociaciones estándar para los elementos de la entidad que correspondan, con la cardinalidad
  // como por ejemplo el ID de agencia, la moneda, etc… También se deben incluir los elementos de la asociación
  association [0..1] to /DMO/I_Agency    as _Agency   on $projection.AgencyId = _Agency.AgencyID
  association [0..1] to /DMO/I_Customer  as _Customer on $projection.CustomerId = _Customer.CustomerID
  association [0..1] to I_Currency       as _Currency on $projection.CurrencyCode = _Currency.Currency
{
  key Travel.travel_id       as TravelId,
      Travel.agency_id       as AgencyId,
      Travel.customer_id     as CustomerId,
      Travel.begin_date      as BeginDate,
      Travel.end_date        as EndDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      Travel.booking_fee     as BookingFee,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      Travel.total_price     as TotalPrice,
      //      @Semantics.currencyCode: true
      Travel.currency_code   as CurrencyCode,
      Travel.description     as Description,
      Travel.overall_status  as OverallStatus,
      @Semantics.user.createdBy: true
      Travel.created_by      as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      Travel.created_at      as CreatedAt,
      @Semantics.user.lastChangedBy: true
      Travel.last_changed_by as LastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      Travel.last_changed_at as LastChangedAt,
      _Booking,
      _Agency,
      _Customer,
      _Currency
}
