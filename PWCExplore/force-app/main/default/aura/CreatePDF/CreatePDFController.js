({
	doInit : function(component,event,helper){
        helper.getSaveReady(component,helper);
        if(window.location.href.indexOf('gbpartners') != -1){
            component.set('v.baseUrl', window.location.origin+'/gbpartners');
        }else{
        	component.set('v.baseUrl', window.location.origin);    
        }
	},

	generateDocument : function(component,event,helper) {
        helper.saveDocument(component,helper);
	}    
})