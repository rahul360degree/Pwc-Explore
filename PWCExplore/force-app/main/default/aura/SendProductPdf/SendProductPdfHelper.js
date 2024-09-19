({
	sendPDFAttachmentDetails : function(component, helper) {
        let action = component.get('c.SendProductDetailsMethod');
        action.setParams({
            "recordId": component.get('v.recordId')
        });
        action.setCallback(this, function(response) {
            var isSuccess = response.getState();
            console.log(isSuccess);
            if (response.getState() === "SUCCESS") {
                if(response.getReturnValue()== 'Successfully sent attachment'){
                    helper.showToast("Success!", response.getReturnValue(), "success");
                }
                else{
                    if(response.getReturnValue()== 'File Not found'){
                        helper.showToast("Error!", response.getReturnValue(), "error");                        
                    }
                }
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