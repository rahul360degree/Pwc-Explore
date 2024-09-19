/*------------------------------------------------------------------------
Author:        Rohit Jadhav
Company:       Salesforce
Description:   Helper class for Address Trigger
Inputs:        NA
Test Class:    AddressTriggerHelperTest
History
06-02-2024      Rohit Jadhav     Initial Release
----------------------------------------------------------------------------*/
public with sharing class AddressTriggerHelper {
    Set<String> queueDeveloperNameSet=new Set<String>();
    Set<String> presentQueueDeveloperNameSet=new Set<String>();
    List<Address__c> addressList=new List<Address__c>();
    public void validateQueueName(list<Address__c> newItems,Map<Id,Address__c> oldItems){ 
        for(Address__c newAddress: newItems){
            if(String.isNotBlank(newAddress.Queue_Name__c) && 
               ( Trigger.isInsert || newAddress.Queue_Name__c != oldItems.get(newAddress.id).Queue_Name__c )){
                queueDeveloperNameSet.add(newAddress.Queue_Name__c);
                addressList.add(newAddress);
            }
        }
        if(!queueDeveloperNameSet.isEmpty()){
            for(Group grp:[SELECT Id,DeveloperName FROM Group WHERE Type = :GlobalConstants.Queue_Type and DeveloperName IN: queueDeveloperNameSet]){
                presentQueueDeveloperNameSet.add(grp.DeveloperName);
            }
        }
        if(!addressList.isEmpty()){
            for(Address__c addressRecord: addressList){
                if(presentQueueDeveloperNameSet.isEmpty() || !presentQueueDeveloperNameSet.contains(addressRecord.Queue_Name__c))
                {
                   addressRecord.addError('Queue with developer name: '+addressRecord.Queue_Name__c +' , not present. Please enter valid Queue Name.');
                }
            }
        }
    }
}