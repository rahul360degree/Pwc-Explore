({
	syncQuoteHelper : function(component, helper) {
        let action = component.get('c.startSyncWithQuote');
        action.setParams({
            "recordId": component.get('v.recordId')
        });
        action.setCallback(this, function(response) {
            var isSuccess = response.getState();
            console.log(isSuccess);
            if (response.getState() === "SUCCESS") {
                var staticLabel = $A.get("$Label.c.QuoteSyncSuccessful ");
                component.set('v.message', staticLabel);
            } else {
                let errors = action.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        var staticLabel = $A.get("$Label.c.QuoteSyncFailure");
                        component.set('v.message', staticLabel + errors[0].message);
                    }
                }
            }
        });
        $A.enqueueAction(action);
    }
})