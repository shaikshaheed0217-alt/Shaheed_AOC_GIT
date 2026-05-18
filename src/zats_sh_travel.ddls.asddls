@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Travel Root BO'
define root view entity ZATS_SH_TRAVEL
  as select from /dmo/travel_m

  -----------Composition(Child)----------------
  composition [0..*] of ZATS_SH_BOOKING          as  _Booking 
  -----------Travel Attachment-----------------
  composition [0..* ] of ZATS_SH_ATTACHMENT      as  _Attachment
  
 
  ------------Association----------------
  --1)To get Agency Data :
  association [1]    to /DMO/I_Agency               as _agency     on $projection.AgencyId = _agency.AgencyID
  --2)To get Customer Data :
  association [1]    to /DMO/I_Customer             as _customer   on $projection.CustomerId = _customer.CustomerID
  --3)To get Currency Data :
  association [1]    to I_Currency                  as _currency   on $projection.CurrencyCode = _currency.Currency
  --4)To get Overall Status data :
  association [1..1] to /DMO/I_Overall_Status_VH as _overallstatus on $projection.OverallStatus = _overallstatus.OverallStatus


{

  key travel_id       as TravelId,
      agency_id       as AgencyId,
      customer_id     as CustomerId,
      begin_date      as BeginDate,
      end_date        as EndDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      booking_fee     as BookingFee,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      total_price     as TotalPrice,
      currency_code   as CurrencyCode,
      description     as Description,
      overall_status  as OverallStatus,
      --Autofilling by Framework :
      @Semantics.user.createdBy: true
      created_by      as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at      as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at as LastChangedAt,
      case overall_status
      when 'O' then 'Open'
      when 'A' then 'Approved'
      when 'R' then 'Rejected'
      when 'X' then 'Cancelled'
      end             as StatusText,
      case overall_status
      when 'O' then 2
      when 'A' then 3
      when 'R' then 1
      when 'X' then 1
      end             as Criticality,

      --Expose this association :

      _agency,
      _customer,
      _currency,
      _overallstatus,
      _Booking,
      _Attachment
      


}
