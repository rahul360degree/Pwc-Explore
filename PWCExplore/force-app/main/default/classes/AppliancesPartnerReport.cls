/**
* @description       : Used for community to display all reports on mobile device.
* @author            : vrajpoot@godrej.com
* @group             : 
* @last modified on  : 11-02-2022
* @last modified by  : vrajpoot@godrej.com
**/
public with sharing class AppliancesPartnerReport {
    @AuraEnabled
    public static List<Report> getReports(){
        try {
            return [SELECT Id, OwnerId, FolderName, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById,
                    IsDeleted, Name, Description, DeveloperName 
                    FROM Report where FolderName like '%D2D%'
                    WITH SECURITY_ENFORCED
                   ];
        } catch (Exception e) {throw new AuraHandledException(e.getMessage());}
    }
}