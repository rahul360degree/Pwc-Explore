/*------------------------------------------------------------------------
Author:        Manasi Londhe
Company:       Salesforce
Description:   Test class for CalculateActuals
Inputs:        
Test Class:    
History
04-01-2021      Manasi Londhe     Initial Release
----------------------------------------------------------------------------*/
@isTest
public with sharing class CalculateActualsTest {
    
    public static final Id targetRecordTypeId=Schema.SObjectType.Receivable__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.RECEIVABLE_TARGET).getRecordTypeId();
    public static final Id receivableRecordTypeId=Schema.SObjectType.Receivable__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.RECEIVABLE_RECORDTYPE).getRecordTypeId();
    public static final Id invoiceRecordTypeId=Schema.SObjectType.Receivable__c.getRecordTypeInfosByDeveloperName().get(GlobalConstants.RECEIVABLE_INVOICE).getRecordTypeId();
    
    @TestSetup
    static void prepareData(){
        List<Receivable__c> recievablesToInsert=new List<Receivable__c>();
        List<User> usersToInsert=new List<User>();
        Id commercialManagerProfileId;
        Id ssgProfileId;
        for(Profile p:[Select Id,Name From Profile Where Name in ('SSG Commercial Manager User','SSG Sales Engineer & Manager User')]){
            if(p.Name=='SSG Commercial Manager User'){
                commercialManagerProfileId=p.Id;
            }
            else{
                ssgProfileId=p.Id;
            }
        }
        
        //insert users
        TestUserBuilder tub = new TestUserBuilder();
        tub.setProfileId(commercialManagerProfileId);
        User commercialManager = tub.getTestRecord();
        commercialManager.persona__c = 'SSG- Commercial Manager';
        commercialManager.Business_Unit__c='G';
        usersToInsert.add(commercialManager);
        TestUserBuilder tub1 = new TestUserBuilder();
        tub1.setProfileId(ssgProfileId);
        User ssgUser = tub1.getTestRecord();
        ssgUser.Business_Unit__c='G';
        usersToInsert.add(ssgUser);
        Insert usersToInsert;
        
        //insert Queues
        Group queue = new Group(Name='test group', type='Queue');
        insert queue;
        QueuesObject q1 = new QueueSObject(QueueID = queue.id, SobjectType = 'Receivable__c');
        insert q1;
        Group queue1 = new Group(Name='test group2', type='Queue');
        insert queue1;
        QueuesObject q2 = new QueueSObject(QueueID = queue1.id, SobjectType = 'Receivable__c');
        insert q2;
        
        // add user to Queues
        addUserToQueue(usersToInsert[1],queue,queue1);
        
        //insert line item records 
        System.runAs(usersToInsert[1]){
           recievablesToInsert.addAll(getOutstandingTargetRecords(queue.Id));
           recievablesToInsert.addAll(getOutstandingNormRecords(queue1.Id));
           recievablesToInsert.addAll(getReceivableRecords(usersToInsert[1].Id));
           recievablesToInsert.addAll(getInvoiceRecords(usersToInsert[1].Id));
           Insert recievablesToInsert;
            
        //create custom settings
            Apex_Batch_Configurations__c batchConfig = new Apex_Batch_Configurations__c(Name = 'CalculateOutstandingAmountSchedular', 
            																Batch_Size__c = 10);
            insert batchConfig;
        }
    }
    
    public static List<Receivable__c> getOutstandingTargetRecords(Id queueId) {
        List<Receivable__c> recievablesToInsert=new List<Receivable__c>();
        Receivable__c outstandingTarget =new TestReceivableBuilder().setRecordType(targetRecordTypeId).setStartDate(System.Today()).setEndDate(System.Today()).setOutstandingAmount(700000).setType('Outstanding').setOwnerId(queueId).getTestRecord();
        recievablesToInsert.add(outstandingTarget);
        return recievablesToInsert;
    }
    
    public static List<Receivable__c> getOutstandingNormRecords(Id queueId) {
        List<Receivable__c> recievablesToInsert=new List<Receivable__c>();
        Receivable__c normTarget =new TestReceivableBuilder().setRecordType(targetRecordTypeId).setStartDate(System.Today()).setEndDate(System.Today()).setType(GlobalConstants.RECEIVABLE_TYPE_NORM).setOwnerId(queueId).getTestRecord();
        recievablesToInsert.add(normTarget);
        return recievablesToInsert;
    }
    
    public static List<Receivable__c> getReceivableRecords(Id userId) {
        List<Receivable__c> recievablesToInsert=new List<Receivable__c>();
        Receivable__c RecivableTarget =new TestReceivableBuilder().setRecordType(receivableRecordTypeId).setStartDate(System.Today()).setEndDate(System.Today()).setOutstandingAmount(500000).setOwnerId(userId).setOrder('GOA').setRecordType('Receivable').getTestRecord();
        recievablesToInsert.add(RecivableTarget);
        
        return recievablesToInsert;
    }
    
    public static List<Receivable__c> getInvoiceRecords(Id userId) {
        List<Receivable__c> recievablesToInsert=new List<Receivable__c>();
        Receivable__c RecivableTarget =new TestReceivableBuilder().setRecordType(invoiceRecordTypeId).setStartDate(System.Today()).setEndDate(System.Today()).setNetBilledSales(40000).setDocumentDate(System.today()).setOwnerId(userId).setOrder('GOA').setRecordType('Invoice').getTestRecord();
        recievablesToInsert.add(RecivableTarget);
        return recievablesToInsert;
    }
    
    public static void addUserToQueue(User u,Group grp,Group grp2){
        List<GroupMember> members=new List<GroupMember>();
        GroupMember member = new GroupMember();
		member.UserOrGroupId = u.Id;
		member.GroupId = grp.Id;
        members.add(member);
        GroupMember member1 = new GroupMember();
		member1.UserOrGroupId = u.Id;
		member1.GroupId = grp2.Id;
        members.add(member1);
        insert members;
    }
    
     @isTest
    public static void ActualRecordsShouldGetCreated() {
        Test.startTest();
        Database.executeBatch(new CalculateActuals(), 200);    
        Test.stopTest();
        List<Receivable__c> actualLineItems=[Select Id from Receivable__c Where RecordType.DeveloperName='Actual'];
        System.assertEquals(2,actualLineItems.Size());
    }
    
    @isTest 
    public static void testSchedular() {
        Test.StartTest();
        CalculateActualAmountSchedular scheduler = new CalculateActualAmountSchedular();
        String sch = '0 0 23 * * ?'; 
        system.schedule('calculate Actuals schedular', sch, scheduler); 
        Test.stopTest();
   }

}