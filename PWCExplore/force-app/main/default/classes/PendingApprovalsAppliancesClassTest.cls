/**
* @Author            : Ashwin Thale
* @class name  : PendingApprovalsAppliancesClassTest.apxc
* @description  : 
* @created date  : 30-11-2023
* @last modified on  : 30-11-2023
* @last modified by  : Ashwin Thale
* Modifications Log	 :
* Ver   Date         Author          Modification
* 1.0   30-11-2023   Ashwin Thale   Initial Version
**/

@isTest(SeeAllData=true)
public with sharing class PendingApprovalsAppliancesClassTest {
    
    @isTest
    public static void testDoInit() {
        Test.startTest();
        PendingApprovalsAppliancesClass controller = PendingApprovalsAppliancesClass.doInit('Order');
        Test.stopTest();
        
        System.assertNotEquals(null, controller);
        System.assertNotEquals(null, controller.procInstStepsList);
        System.assertNotEquals(null, controller.procInstWorkItemList);
        System.assertNotEquals(null, controller.ordList);
    }
    
    @isTest
    public static void testCreateApprovalData() {
        
        Test.StartTest();
        DateTime currentDateTime = DateTime.now();
        DateTime futureDateTime = currentDateTime.addDays(10);
        String formattedDateTime = futureDateTime.format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        
        String sObjectName = 'Order',strIdComment,strComment;
        String query=' SELECT Id, OriginalActorId '
            +' From ProcessInstanceWorkitem '
            +' Where '
            +' ProcessInstance.TargetObject.Type  =: sObjectName ' 
            +' Limit 1 ';
        List<ProcessInstanceWorkitem> processItems= Database.query(query);
        List<String> RecordIds = new List<String>();
        for(ProcessInstanceWorkitem approval : processItems) {
            strIdComment=approval.Id+'-'+approval.OriginalActorId;
            RecordIds.add(strIdComment);
        }
        String strBusinessUnit = GlobalConstants.APPLIANCE_BUSINESS_UNIT;
        Account acc = [SELECT Id FROM Account Where Business_Unit__c =: strBusinessUnit LIMIT 1];
        
        Order obj = new Order();
        obj.Planned_Delivery_Date__c = currentDatetime;
        obj.AccountId = acc.Id;
        obj.Business_Unit__c = strBusinessUnit;
        insert obj;   
        
        List<String> OrderIds = new List<String>();
        for(ProcessInstanceWorkitem approval : processItems) {
            strIdComment=approval.Id+'-'+obj.Id+'-'+formattedDateTime;
            OrderIds.add(strIdComment);
        }
        
        PendingApprovalsAppliancesClass.submitForApproval(RecordIds,OrderIds,GlobalConstants.APPROVED);
        Test.StopTest();
        
    }
    
}