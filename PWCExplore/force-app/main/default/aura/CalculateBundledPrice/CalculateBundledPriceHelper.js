({
    calculateBundledPrices : function(component, helper) {
        let action = component.get('c.calculateBundledPrices');
        action.setParams({
            "recordId": component.get('v.recordId')
        });
        action.setCallback(this, function(response) {
            var isSuccess = response.getState();
            if (response.getState() === "SUCCESS") {
                component.set('v.message', $A.get("$Label.c.Product_Bundling_Success"));
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