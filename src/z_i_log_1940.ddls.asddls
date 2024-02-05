@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface Log'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity Z_I_LOG_1940 as select from zlog_1940
{
    key change_id as ChangeId,
    travel_id as TravelId,
    changing_operation as ChangingOperation,
    change_field_name as ChangeFieldName,
    change_field_value as ChangeFieldValue,
    createdat as Createdat,
    user_mod as UserMod
}
