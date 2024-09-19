({
	generatePDFHelperWithoutSync : function(component, helper) {
        let action = component.get('c.createAttachmentWithoutSync');
        action.setParams({
            "orderId": component.get('v.recordId')
        });
        action.setCallback(this, function(response) {
            var isSuccess = response.getState();
            console.log(isSuccess);
            if (response.getState() === "SUCCESS") {
                helper.showToast("Success!", response.getReturnValue(), "success");
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                  "recordId": component.get('v.recordId')
                });
                navEvt.fire();
            } else {
                let errors = action.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        helper.showToast("Error!", errors[0].message, "error");
                    }
                }
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                  "recordId": component.get('v.recordId')
                });
                navEvt.fire();
            }
        });
        $A.enqueueAction(action);
    },
    
    showToast : function(title, message, type) {
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type
        });
        toastEvent.fire();
    }
})