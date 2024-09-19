({
	createQuoteHelper : function(component, helper) {
        let action = component.get('c.createCustomerQuote');
        action.setParams({
            "recordId": component.get('v.recordId')
        });
        action.setCallback(this, function(response) {
            var isSuccess = response.getState();
            console.log(isSuccess);
            if (response.getState() === "SUCCESS") {
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                  "recordId": response.getReturnValue()
                });
                navEvt.fire();
            } else {
                let errors = action.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        component.set('v.message', errors[0].message);
                    }
                }
            }
        });
        $A.enqueueAction(action);
    }
})