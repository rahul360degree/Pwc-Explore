({
    getBU : function(component) {
        var action = component.get("c.checkConstructionUser");
        // Register the callback function
        action.setCallback(this, function(response) {            
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.businessUnit",response.getReturnValue());
                component.set("v.showSpinner",false);
            }
            else if (state === "ERROR") {
            	component.set("v.showSpinner",false);
            }
        });
        // Invoke the service
        $A.enqueueAction(action); 
    }
})