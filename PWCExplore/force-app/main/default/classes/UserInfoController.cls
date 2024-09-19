/*------------------------------------------------------------------------
Author:        Pankaj Meshram
Company:       GITL
 
History
19-07-2023      Pankaj Meshram     Initial Release
----------------------------------------------------------------------------*/
public with sharing class UserInfoController {
	@AuraEnabled(cacheable=true)
    public static User getUserInfo(){
        return [select Id,Name,Business_unit__c from User where id=:UserInfo.getUserId()];
    }
}