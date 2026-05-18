@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Supplement Projection Layer'
@Metadata.allowExtensions: true
define view entity ZATS_SH_BOOKSUPPL_PROCESSOR
  as projection on ZATS_SH_BookSuppl
{
  key TravelId,
  key BookingId,
  key BookingSupplementId,
      SupplementId,
      Price,
      CurrencyCode,
      LastChangedAt,
      /* Associations */
      _Booking : redirected to parent ZATS_SH_BOOKING_PROCESSOR,
      _travel  : redirected to ZATS_SH_TRAVEL_PROCESSOR
}
