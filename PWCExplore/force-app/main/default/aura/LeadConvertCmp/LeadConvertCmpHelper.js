({
    
    
    showToast : function(component, event, type, title, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type" : type,
            "title": title,
            "message": message
        });
        toastEvent.fire();
    },
    
	convertLeadRecord : function(component, helper) {
       
        component.set("v.spinner", !component.get('v.spinner'));

		let action = component.get('c.convertLead');
        action.setParams({
                            "inputValue" : component.get('v.recordId'), 
                            "existingAccountId" : component.get('v.existingAccount')
                        });

        action.setCallback(this, function(response) {
            var isSuccess = response.getState();
            
            if (response.getState() === "SUCCESS") {
                console.log('success');
               component.set("v.spinner", !component.get('v.spinner'));
               this.showToast(component, event, 'Success', 'Success!', 'The Lead has been converted successfully.');
               var navEvt = $A.get("e.force:navigateToSObject");
               navEvt.setParams({
                 "recordId": response.getReturnValue()
               });
               navEvt.fire();

                
            } else {
                console.log('not success');
                component.set("v.spinner", !component.get('v.spinner'));
        		let errors = action.getError();
                console.log(errors);
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.showToast(component, event, 'Error', 'Error!', errors[0].message);
                        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        				dismissActionPanel.fire();
                    }
                }

            }
        });
        
        
        $A.enqueueAction(action);
    }

    
})