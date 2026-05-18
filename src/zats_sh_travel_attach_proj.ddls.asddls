@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Travel Attach Projection Layer'
@Metadata.allowExtensions: true

define view entity ZATS_SH_TRAVEL_ATTACH_PROJ
  as projection on ZATS_SH_ATTACHMENT
{

  key TravelId,
  key Id,
      Comment1,
      Attachment,
      Filename,
      Filetype,
      /* Associations */
      _travel : redirected to parent ZATS_SH_TRAVEL_PROCESSOR
}
