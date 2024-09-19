({
	 doInit : function(component, event, helper) {
         //Added by Namrata on 12-01-2023 for SMEPB-59
         var action = component.get("c.skipCreateNewAccount");
         action.setCallback(this,function(response){
             var state = response.getState();
             if(state === "SUCCESS"){
                 var returnData = response.getReturnValue();
                 component.set("v.checkProfile", returnData);
             }
         });
        
        var recordId = component.get("v.recordId");
        var action1 = component.get("c.getLeadData");
        action1.setParams({
            "recordId": recordId
        });
        action1.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var leadData=response.getReturnValue();
                console.log(leadData.Business_Unit__c);
                console.log(leadData.Sub_Division__c);
                if(leadData.Business_Unit__c==='L' && leadData.Sub_Division__c==='B2C ISTD'){
                   console.log('Inside If'); 
                   component.set("v.existingAccount", leadData.Distributor_1__c); 
                }                
            } 
        });
        $A.enqueueAction(action);
    	$A.enqueueAction(action1);
         // End by Namrata
     },
	 convertLeadQualifier : function(component, event, helper) {
         var createNew = component.get("v.createNewAccount");
         var existincAcc = component.get("v.existingAccount");
         
         var flag1 = false;
         var flag2 = false;

         if(createNew) flag1=true;
         if(existincAcc) flag2 = true;
         
         var executeConvert = true;
         
         if((flag1==false) && (flag2==false)){
                 var staticLabel1 = $A.get("$Label.c.LeadConvertMobileSelectOnlyOne");
                 component.set("v.message", staticLabel1);
                 executeConvert = false;
         }
         else{
             if( (flag1==true) && (flag2==true) && (existincAcc.length == 18) ){
                 var staticLabel2 = $A.get("$Label.c.LeadConvertMobileSelectOne");
                 component.set("v.message", staticLabel2);
                 executeConvert = false;
             }
         }
         if(executeConvert == true){
                  helper.convertLeadRecord(component, helper);
         }
     }

})