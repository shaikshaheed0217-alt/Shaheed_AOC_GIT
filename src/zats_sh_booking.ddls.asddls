@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking BO'
define view entity ZATS_SH_BOOKING
  as select from /dmo/booking_m
  -------------Composition(Child)---------------------
  composition [0..*] of ZATS_SH_BookSuppl     as _BookingSupplement




  ---------------Associations(Parent)------------------
  association        to parent ZATS_SH_TRAVEL        as _travel    on $projection.TravelId = _travel.TravelId

  ----------------Associations-------------------------
  --1)To get the Customer data :
  association [1]    to /DMO/I_Customer          as _customer      on $projection.CustomerId = _customer.CustomerID
  --2)To get the Carrier Data :
  association [1]    to /DMO/I_Carrier           as _carrier       on $projection.CarrierId = _carrier.AirlineID
  --3)To get the Connection data :
  association [0..1] to /DMO/I_Connection        as _connection       on $projection.ConnectionId = _connection.ConnectionID
  --4)To get the Booking status data :
  association [1]    to /DMO/I_Booking_Status_VH as _bookingStatus on $projection.BookingStatus = _bookingStatus.BookingStatus

{

  key travel_id       as TravelId,
  key booking_id      as BookingId,
      booking_date    as BookingDate,
      customer_id     as CustomerId,
      carrier_id      as CarrierId,
      connection_id   as ConnectionId,
      flight_date     as FlightDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      flight_price    as FlightPrice,
      currency_code   as CurrencyCode,
      booking_status  as BookingStatus,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at as LastChangedAt,

      ---Expose Assocations :
      _customer,
      _carrier,
      _connection,
      _bookingStatus,
      _travel,
      _BookingSupplement
}
