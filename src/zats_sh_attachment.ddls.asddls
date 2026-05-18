@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Attachment CDS view Entity'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZATS_SH_ATTACHMENT
  as select from zats_sh_trv_att
  association to parent ZATS_SH_TRAVEL as _travel on $projection.TravelId = _travel.TravelId
{
  key travel_id  as TravelId,
  key id         as Id,
      @EndUserText: {  label: 'Comments'}
      comment1   as Comment1,
      @Semantics.largeObject: {
          mimeType: 'Filetype',
          fileName: 'filename',
          contentDispositionPreference: #INLINE
      }
      @EndUserText: {  label: 'Attachment'}
      attachment as Attachment,
      @EndUserText: {  label: 'File name'}
      filename   as Filename,
      @Semantics.mimeType: true
      @EndUserText: {  label: 'File Type'}
      filetype   as Filetype,
      @Semantics.systemDateTime.lastChangedAt: true
      lastchangedat,
      _travel

}
