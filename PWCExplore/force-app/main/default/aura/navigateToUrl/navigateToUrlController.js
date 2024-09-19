({    
    invoke : function(component, event, helper) {
    console.log('Hii');
        
    var redirectURL = component.get("v.redirectURL");
        console.log(redirectURL);
    var redirect = $A.get("e.force:navigateToURL");
    redirect.setParams({
        "url": redirectURL
    	});
    redirect.fire();
	}
}
)