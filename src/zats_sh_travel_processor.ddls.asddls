@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Travel Projection Layer'
@Metadata.allowExtensions: true

define root view entity ZATS_SH_TRAVEL_PROCESSOR
  provider contract transactional_query
  as projection on ZATS_SH_TRAVEL
{
      @ObjectModel.text.element: [ 'Description' ]
  key TravelId,
      @ObjectModel.text.element: [ 'AgencyName' ]
      @Consumption.valueHelpDefinition: [{ entity.name: '/DMO/I_Agency' ,
                                           entity.element: 'AgencyID' }]
      AgencyId,
      @Semantics.text: true
      _agency.Name       as AgencyName,
      @ObjectModel.text.element: [ 'CustomerName' ]
      @Consumption.valueHelpDefinition: [{ entity.name: '/DMO/I_Customer',
                                           entity.element: 'CustomerID' }]
      CustomerId,
      @Semantics.text: true
      _customer.LastName as CustomerName,
      BeginDate,
      EndDate,
      BookingFee,
      TotalPrice,
      CurrencyCode,
      @Semantics.text: true
      Description,
      @ObjectModel.text.element: [ 'StatusText' ]
      @Consumption.valueHelpDefinition: [{ entity.name: '/DMO/I_Overall_Status_VH' ,
                                           entity.element: 'OverallStatus' }]
      OverallStatus,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      @Semantics.text: true
      StatusText,
      Criticality,
      /* Associations */
      _agency,
       _Booking    : redirected to composition child ZATS_SH_BOOKING_PROCESSOR,
       _Attachment : redirected to composition child ZATS_SH_TRAVEL_ATTACH_PROJ,
      _currency,
      _customer,
      _overallstatus,
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_ATS_VE_CALC'
      @EndUserText.label: 'CO2 Tax'
      virtual CO2Tax : abap.int4,
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_ATS_VE_CALC'
      @EndUserText.label: 'Week Days'

      virtual dayOfFlight : abap.char( 10 ) 
      
      
}
