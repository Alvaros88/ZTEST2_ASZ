@EndUserText.label: 'Consumption - Travel'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
define root view entity z_c_travel_1940
  as projection on z_i_travel_1940
{
  key     TravelId,
          @ObjectModel.text.element: [ 'AgencyName' ]
          AgencyId,
          _Agency.Name       as AgencyName,
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
          OverallStatus      as TravelStatus,
          CreatedBy,
          CreatedAt,
          LastChangedBy,
          LastChangedAt,
          // Añadimos el elemento virtual, con el tipo de dato que lo queremos declarar
          // en las anotaciones indicamos el tipo moneda al que hace referencia y la clase ABAP
          // donde se realizará la lógica para este objeto virtual
          @Semantics.amount.currencyCode: 'CurrencyCode'
          @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_VIRT_ELEM_1940'
  virtual DiscountPrice : /dmo/total_price,
          /* Associations */
          _Agency,
          _Booking : redirected to composition child z_c_booking_1940,
          _Currency,
          _Customer
}
