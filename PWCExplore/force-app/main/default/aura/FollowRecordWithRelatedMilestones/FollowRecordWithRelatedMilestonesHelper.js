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
    
	handleFollow : function(component, helper) {
        component.set("v.spinner", !component.get('v.spinner'));

		let action = component.get('c.followRecord');
        action.setParams({
            "caseId" : component.get('v.recordId') 
        });

        action.setCallback(this, function(response) {
            var isSuccess = response.getState();
            
            if (response.getState() === "SUCCESS") {
                console.log('===success');
               component.set("v.spinner", !component.get('v.spinner'));
               this.showToast(component, event, 'Success', 'Success!', 'Record followed successfully.');
               
            } else {
                console.log('====not success');
                component.set("v.spinner", !component.get('v.spinner'));
        		let errors = action.getError();
                console.log(errors);
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        this.showToast(component, event, 'Error', 'Error!', errors[0].message);
                        //var dismissActionPanel = $A.get("e.force:closeQuickAction");
        				//dismissActionPanel.fire();
                    }
                }

            }
        });
        
        
        $A.enqueueAction(action);
    }

    
})