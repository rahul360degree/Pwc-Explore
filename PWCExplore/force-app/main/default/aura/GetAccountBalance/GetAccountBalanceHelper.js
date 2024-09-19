({
	callAPI : function(component) {
        console.log(2222,component.get("v.recordId"));
        
        
        var action = component.get("c.callAPI");
        action.setParams({
             "orderId": component.get("v.recordId")
        })
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                
                console.log('RES >>>',response);
                console.log('RES RET >>>',response.getReturnValue());
                component.set('v.statusMessage', response.getReturnValue());
            }
            else if(state === "ERROR")
            {
            	var errors = action.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                             mode: 'sticky',
                            "title": "Error",
                            "message": errors[0].message
                        });
                        toastEvent.fire();
                        $A.get("e.force:closeQuickAction").fire();
                    }
                }  
            }
            else {
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
        
    }
})