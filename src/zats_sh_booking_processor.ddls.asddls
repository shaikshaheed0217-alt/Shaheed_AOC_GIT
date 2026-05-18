@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Projection Layer'
@Metadata.allowExtensions: true

define view entity ZATS_SH_BOOKING_PROCESSOR
  as projection on ZATS_SH_BOOKING
{

  key TravelId,
  key BookingId,
      BookingDate,
      @Consumption.valueHelpDefinition: [{ entity.name    : '/DMO/I_Customer' ,
                                           entity.element : 'CustomerID'     }]
      CustomerId,
      @Consumption.valueHelpDefinition: [{ entity.name    : '/DMO/I_Carrier' ,
                                           entity.element : 'AirlineID' }]
      CarrierId,
      @Consumption.valueHelpDefinition: [{ entity.name    : '/DMO/I_Connection' ,
                                           entity.element : 'ConnectionID'      ,
                                           additionalBinding: [{ localElement: 'CarrierId',
                                                                 element: 'AirlineID' }] }]
      ConnectionId,
      FlightDate,
      FlightPrice,
      CurrencyCode,
      @Consumption.valueHelpDefinition: [{ entity.name    : '/DMO/I_Booking_Status_VH' ,
                                           entity.element : 'BookingStatus' }]
      BookingStatus,
      LastChangedAt,
      /* Associations */
      _bookingStatus,
      _BookingSupplement : redirected to composition child ZATS_SH_BOOKSUPPL_PROCESSOR,
      _carrier,
      _connection,
      _customer,
      _travel            : redirected to parent ZATS_SH_TRAVEL_PROCESSOR
}
