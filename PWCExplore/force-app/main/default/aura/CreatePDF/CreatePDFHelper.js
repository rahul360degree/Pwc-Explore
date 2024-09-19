({
    saveDocument : function(component,helper){  
        helper.showSpinner(component);
        console.log('savePDF');
        //$A.get("e.force:closeQuickAction").fire();
		//invoke apex method to get associated case record id and attach pdf
        var action = component.get("c.generatePDF");
        action.setParams({
            "serviceFormId": component.get("v.recordId"),
            "isSaveDisabled" : component.get("v.disableSaveButton")
        });
        // Register the callback function
        action.setCallback(this, function(response) {
            helper.hideSpinner(component);
            var data = JSON.parse(response.getReturnValue());
            //Close Quick ACtion Modal
            $A.get("e.force:closeQuickAction").fire();
            if(data){
                //Show Success Toast
                helper.showToast("Success!",$A.get("$Label.c.PDF_GENERATED_SUCCESSFULLY"),"success");
            }else{
                //Show Error Toast
                helper.showToast("Error!",$A.get("$Label.c.FAILED_TO_GENERATE_PDF"),"error");
            }
            
        });
        // Invoke the service
        $A.enqueueAction(action);   
    },
    
    getSaveReady : function(component,helper){  
        helper.showSpinner(component);
        console.log('disableSave');
        //$A.get("e.force:closeQuickAction").fire();
		//invoke apex method to get associated case record id and attach pdf
        var action = component.get("c.disableSave");
        action.setParams({
            "serviceFormId": component.get("v.recordId")
        });
        // Register the callback function
        action.setCallback(this, function(response) {
                let returnValue = response.getReturnValue();
                if (returnValue !== null && returnValue !== undefined) {
                    component.set("v.disableSaveButton", returnValue);
                }
            helper.hideSpinner(component);
        });
        // Invoke the service
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
    },

    showSpinner : function(component) {
		let spinnerMain = component.find("spinner");
		$A.util.removeClass(spinnerMain, "slds-hide");
	},

	hideSpinner : function(component) {
		let spinnerMain = component.find("spinner");
		$A.util.addClass(spinnerMain, "slds-hide");
	}
})