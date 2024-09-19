({
    doInit : function(component, event, helper) {
        helper.updateApproverOnRecord(component,event);
    },
    
    onSubmitForApproval : function(component, event, helper) {
        helper.submitRecordForApproval(component);
    },
    
    closeModal:function(component,event,helper){
        //component.destroy();
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    }
})