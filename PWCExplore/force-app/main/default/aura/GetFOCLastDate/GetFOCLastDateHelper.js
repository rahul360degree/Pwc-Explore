({
	GetLastDate: function(component) {
        console.log(2222,component.get("v.recordId"));
        
        
        var action = component.get("c.GetLastDate");
        action.setParams({
             "PmId": component.get("v.recordId")
        })
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                
                console.log('RES >>>',response);
                console.log('RES RET >>>',response.getReturnValue());
                component.set('v.statusMessage', response.getReturnValue());
            }
            else {
                
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
        
    }
})