/*------------------------------------------------------------------------------------
 * Author        :        Stetig Consulting
 * Description   :        Test method for the premise tagging button/controller present on opportunity page
 * History
 * --------
 * 02-12-2021     :    Initial Release
 * ----------------------------------------------------------------------------------*/
@isTest
public with sharing class TestPremiseTagging {
    static testmethod void searchandtagPremise() {
       
        Id bId = LeaseTestDataFactory.createOfficeSpaceBuilding();
        LeaseTestDataFactory.createVacantUnits(bId);
        LeaseTestDataFactory.createOccupiedUnits(bId);
        List<Project_Unit__c> bList = [Select Name, Id, Location__c, Use_of_premises__c, Project__c from Project_Unit__c where Id = :bId];
        List<floor__c> fList = [Select Name, Id, Building__c, Asset_Code__c, Type_of_Premise__c,status__c from floor__c where Building__c = :bId];
        test.startTest();
        Id leasingUserId = LeaseTestDataFactory.createLeasingUser();
        User u = [Select Id from User where Id =: leasingUserId];
        System.RunAs(u) {
            List<Lead> lList = new List<Lead>();
            //System.debug('Lead List1: ' + lList[0]);
            Id lId = LeaseTestDataFactory.createLead();
            System.debug('Before lead conversion'+ lId);
            LeaseTestDataFactory.convertLead(lId);
            System.debug('After Lead Id: ' + lId); //00QH1000003S0qiMAC
            lList = [Select Id, ConvertedOpportunityId, ConvertedAccountId from Lead where isConverted = true and Id = :lId];
            System.debug('Lead List2: ' + lList.size());
            System.assertEquals(1, lList.size());
            List<Opportunity> oppList = new List<Opportunity>();
            oppList = [Select Id from Opportunity where Id =:lList[0].ConvertedOpportunityId];
            System.assertEquals(1, oppList.size());
            LeaseTestDataFactory.CreateHoT(oppList[0].Id);
            PageReference pageRef = Page.leasingProperty;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('optyId',oppList[0].Id);
            SearchTagPremise lp = new SearchTagPremise();

            lp.fromRange = 0;
            lp.ToRange = 50000;
            lp.fullyVacant = true;
            lp.Search();
            lp.ObjectPro.Location__c = bList[0].Location__c;
            lp.ObjectPro.Use_of_premises__c = bList[0].Use_of_premises__c;
            List<SelectOption> selOpts=lp.getProjects;
            lp.selectedProject = bList[0].Project__c;
            List<SelectOption> selOpts1=lp.getBuildings;
            lp.selectedBuilding = bList[0].Name;
            AggregateResult[] A =[select count(id)mycount from floor__c   WHERE ( ( Name LIKE 'OF%')) AND Building__r.Location__c=: lp.ObjectPro.Location__c AND Building__r.Project__c=: lp.selectedProject AND Building__c =: bId AND Vacant_Area_Sq_ft__c >= 0 AND vacant_Area_Sq_ft__c <=50000 AND status__c !='Leased Out'];
            lp.Search();
            system.assertEquals(A.size(), lp.wrapList.size());
            lp.wrapList[0].isSelected = true;
            lp.Selected();
            lp.wrapList[0].neededArea = '100000';
            lp.Selected();
            lp.wrapList[0].fullFloor = true;
            lp.Selected();
            lp.wrapList[0].neededArea = '10000';
            lp.Selected();
            lp.DeSelected();
            lp.wrapList[0].neededArea = '10000';
            lp.wrapList[0].isSelected = true;
            lp.Selected();
            lp.Submit();
            
        }
        test.stopTest();
    }
}