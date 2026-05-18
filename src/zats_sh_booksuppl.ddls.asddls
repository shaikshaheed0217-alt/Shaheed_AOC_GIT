@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Supplement BO'
define view entity ZATS_SH_BookSuppl
  as select from /dmo/booksuppl_m
  ---------------Association(Parent)-----------------
  association        to parent ZATS_SH_BOOKING as _Booking        on  $projection.BookingId = _Booking.BookingId
                                                                  and $projection.TravelId  = _Booking.TravelId


  ----------------Associations-------------------------
  --1)To get the Travel data :
  association [1..1] to ZATS_SH_TRAVEL         as _travel         on  $projection.TravelId = _travel.TravelId
  --2)To get the Supplement ID  :
  association [1..1] to /DMO/I_Supplement      as _product        on  $projection.SupplementId = _product.SupplementID
  --3)To get the Supplement Text :
  association [1..*] to /DMO/I_SupplementText  as _SupplementText on  $projection.SupplementId = _SupplementText.SupplementID
{
  key travel_id             as TravelId,
  key booking_id            as BookingId,
  key booking_supplement_id as BookingSupplementId,
      supplement_id         as SupplementId,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      price                 as Price,
      currency_code         as CurrencyCode,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,

      --Expose Associations :

      _travel,
      _product,
      _SupplementText,
      _Booking
}
