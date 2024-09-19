/**
 * @description       : 
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 11-06-2022
 * @last modified by  : vrajpoot@godrej.com
**/
({
	updateApproverOnRecord : function(component,event) {
        var spinner = component.find("loadingSpinner");
        $A.util.addClass(spinner, "slds-show");
        var action = component.get("c.updateApprovers");
        action.setParams({
             "quoteId": component.get("v.recordId")
        })
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                $A.util.addClass(spinner, "slds-hide");
                let returnValue = response.getReturnValue();
                if (returnValue !== null && returnValue !== undefined && returnValue=="Interio_B2B_Finished_Good") {
                    component.set("v.isInterio_B2B_Finished_Good", true);
                    /*var urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        "url": "/lightning/n/Interio_Approval?quoteId=123"
                    });
                    urlEvent.fire();
                    */
                }else if (returnValue !== null && returnValue !== undefined) {
                    component.set("v.approvalStatusMessage", returnValue);
                }
            }
            else {
                $A.util.addClass(spinner, "slds-hide");
            }
        });
        $A.enqueueAction(action);
    },
    
    submitRecordForApproval : function(component) {
        var spinner = component.find("loadingSpinner");
        $A.util.addClass(spinner, "slds-show");
        var action = component.get("c.submitForApproval");
        action.setParams({
             "quoteId": component.get("v.recordId"),
            "approvalText" : component.get("v.approvalComment")
        })
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            $A.util.addClass(spinner, "slds-hide");
            
            if (state === "SUCCESS") {
                component.set("v.approvalStatusMessage", response.getReturnValue());
                $A.get('e.force:refreshView').fire();
            }
            else {
                
                var errors = response.getError();
                if (errors) {
                    component.set("v.approvalStatusMessage", response.getReturnValue());
                } else {
                    component.set("v.approvalStatusMessage", 'Error Occurred. Please contact System admin.');
                }
                
                $A.get('e.force:refreshView').fire();
            }
        });
        $A.enqueueAction(action);
    },
})