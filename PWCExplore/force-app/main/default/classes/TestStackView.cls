/*------------------------------------------------------------------------------------
 * Author        :        Stetig Consulting
 * Description   :        Test methods for stackview controller
 * History
 * --------
 * 02-12-2021     :    Initial Release
 * ----------------------------------------------------------------------------------*/
@isTest
public with sharing class TestStackView {
    static testmethod void viewPremise() {
        Id adminId = LeaseTestDataFactory.createAdminUser('leasetestdatauserAcc123456@godrej.com');
        User u = [Select Id from User where Id =: adminId];
        Id leasingId = LeaseTestDataFactory.createLeasingUser();
        User l1 = [Select Id from User where Id =: leasingId];

        test.StartTest();
        Id bId;
        Id lId;
        System.RunAs(u) {
             bId = LeaseTestDataFactory.createOfficeSpaceBuilding();
            LeaseTestDataFactory.createVacantUnits(bId);
            LeaseTestDataFactory.createOccupiedUnits(bId);
            LeaseTestDataFactory.createPartiallyVacantUnit(bId);
            
        }
        system.Runas(l1) {
            
            

            
            List<Project_Unit__c> bList = [Select Name, Id, Location__c, Use_of_premises__c, Project__c from Project_Unit__c where Id = :bId];
            PageReference pageRef = Page.StackView;
            Test.setCurrentPage(pageRef);
            StackView sv = new StackView();
            sv.objectPro.Location__c  = bList[0].Location__c;
            sv.objectPro.Asset_Type__c = bList[0].Use_of_premises__c;
            List<SelectOption> selOpts=sv.getProjects;
            sv.selectedProject = bList[0].Project__c;
            List<SelectOption> selOpts1=sv.getBuildings;
            sv.selectedBuilding = bList[0].Name;
            sv.Search();
        }
        test.StopTest();
    }
}