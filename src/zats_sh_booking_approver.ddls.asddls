@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Projection Layer'
@Metadata.allowExtensions: true

define view entity  ZATS_SH_BOOKING_APPROVER
  as projection on ZATS_SH_BOOKING
{

  key TravelId,
  key BookingId,
      BookingDate,
      CustomerId,
      CarrierId,
      ConnectionId,
      FlightDate,
      FlightPrice,
      CurrencyCode,
      BookingStatus,
      LastChangedAt,
      /* Associations */
      _bookingStatus,
      _carrier,
      _connection,
      _customer,
      _travel            : redirected to parent ZATS_SH_TRAVEL_APPROVER
}
