({
	closePopup : function(component, event, helper) {
       let context = component.get("v.userContext");

       if(context !== undefined) {
           if(context == 'Theme4t' || context == 'Theme4d') {
               sforce.one.navigateToSObject(component.get("v.recordId"));
           } else {
               let quoteId = component.get("v.recordId");
               window.location.assign('/' + quoteId);
           }
       } else {
           let event = $A.get("e.force:navigateToSObject");
           event.setParams({"recordId": component.get("v.recordId")});
           event.fire();
       }
	}
})