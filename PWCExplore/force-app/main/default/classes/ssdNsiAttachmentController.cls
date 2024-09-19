/* --------------------------------------------------------------------
Author: Sreekanth Jujare
Written for: NSI PDF for Security Solutions
Visualforce Page: ssdNsiAttachment
-----------------------------------------------------------------------*/


public class ssdNsiAttachmentController {
    Public NSI__c nsiData {get; set;}
    Public Id NsiId {get; set;}
    public ssdNsiAttachmentController(ApexPages.StandardController standardController){
        NsiId = standardController.getId();
        nsiData = getNsi(nsiId);
        String Nnumb = 'inline; filename='+nsiData.NSI_Number__c+'.pdf';
        Apexpages.currentPage().getHeaders().put('content-disposition', Nnumb);
    }  
    public NSI__c getNsi(Id nsiId){
        return[Select Id, Any_Other_Customized_Accessories__c,Approval_Status__c,Certification_If_others__c,Certifications__c,Competitors_Offerings__c,
               Customer_Expected_Period__c,Depth_Clear_inside__c,Depth_Outside__c,Estimated_Lead_time_Design__c,Estimated_Lead_time_Finance__c,Product_Category__c,
               Estimated_Lead_time_Planning__c,Height_Clear_inside__c,Height_Outside__c,Initial_Remarks__c,toLabel(Lock_Type__c),Make_Model__c,Nearest_Standard_Product__c,
               NSI_Number__c,Price__c,Product_Qty__c,Remarks_Design__c,Remarks_Finance__c,Remarks_Planning__c,Requirement_Description__c,
               Target_Price__c,Tender_Document_Attached__c,Width_Clear_inside__c,Width_Outside__c,CreatedById,CreatedBy.Name, CreatedDate,
               Opportunity__r.Account.Name, toLabel(Opportunity__r.End_Customer_Segment_SSD__c), Nearest_Standard_Product__r.Search_Key_I__c,
               Nearest_Standard_Product__r.Name, Remarks_HO__c, Price_HO__c FROM NSI__c Where Id =: nsiId];
    }

}