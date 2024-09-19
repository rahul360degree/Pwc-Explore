({
    doInit: function (cmp, event, helper) {
        var action = cmp.get("c.updateBenifitBestValueOnAsset");
        action.setParams({ recordId: cmp.get("v.recordId") });

        // Create a callback that is executed after 
        // the server-side action returns
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // Alert the user with the value returned 
                // from the server
                if (response.getReturnValue() == true) {

                    var dismissActionPanel = $A.get("e.force:closeQuickAction");
                    dismissActionPanel.fire();
                    var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        "title": "Success",
                        "message": "Asset Benefit Best Value has been Updated on Asset",
                        "type": "success"
                    });
                    resultsToast.fire();
                    $A.get('e.force:refreshView').fire();
                } else {
                    // Display the total in a "toast" status message
                    var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        "title": "Error",
                        "message": "Could not perform Calculation. Please retry",
                        "type": "error"
                    });
                    resultsToast.fire();

                    // Close the action panel
                    var dismissActionPanel = $A.get("e.force:closeQuickAction");
                    dismissActionPanel.fire();
                }


            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                            errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);

    }
})