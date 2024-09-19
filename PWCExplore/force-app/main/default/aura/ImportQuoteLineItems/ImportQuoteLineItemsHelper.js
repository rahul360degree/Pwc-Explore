({
	doInitHelper : function(component, event, helper) {
        helper.showSpinner(component);
		let action = component.get("c.fetchQuotes");
		action.setParams({
			quoteId: component.get("v.recordId")
		});
		action.setCallback(this, function (response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				component.set("v.quoteList", response.getReturnValue());
			} else if (state === "ERROR") {
				helper.showToast("Error!", "An error occurred while fetching quotes: " + response.getError(), "error");
			}
            helper.hideSpinner(component);
		});
		$A.enqueueAction(action);
	},

    selectRowsHelper : function(component, event, helper) {
        let selectedRows = event.getParam('selectedRows');
		let setRows = [];
		for (let i = 0; i < selectedRows.length; i++) {
			setRows.push(selectedRows[i]);
		}
		component.set("v.selectedQLIs", setRows);
        if (setRows.length > 0) {
        	component.set("v.hasSelectedQLI", true);
        } else {
            component.set("v.hasSelectedQLI", false);
        }
    },
    
    importQLIHelper : function(component, event, helper) {
        helper.showSpinner(component);
        let selectedRows = component.get('v.selectedQLIs');
		let action = component.get("c.importQLIRecords");
		action.setParams({
			'lstQLI': selectedRows,
            'ogQuoteId': component.get("v.recordId")
		});
		action.setCallback(this, function (response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				helper.hideSpinner(component);
                helper.showToast("Imported!", "All line items were imported successfully", "success");
            } else {
                let errors = action.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        helper.showToast("Error!", "An error occurred importing the line items: " + errors[0].message, "error");
                    }
                }
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
    },
    
    getPreviousPage : function(component, event, helper) {
        let pageNumber = component.get("v.pageNumber");
        let pageSize = component.get("v.pageSize");
        let fullQuoteList = component.get("v.fullQuotelineItemList");
        let updatedQuoteList = [];
        if (pageNumber > 1) {
            pageNumber--;
            component.set("v.isLastPage", false);
            for (let i = (pageNumber-1)*pageSize; i < (pageNumber*pageSize); i++) {
                updatedQuoteList.push(fullQuoteList[i]);
            }
            component.set("v.pageNumber", pageNumber);
            component.set("v.quotelineItemList", updatedQuoteList);
            component.set("v.dataSize", updatedQuoteList.length);
        }
    },
    
    getNextPage : function(component, event, helper) {
        helper.showSpinner(component);
        let isLastPage = component.get("v.isLastPage");
        let pageNumber = component.get("v.pageNumber");
        let pageSize = component.get("v.pageSize");
        let fullQuoteList = component.get("v.fullQuotelineItemList");
        let updatedQuoteList = [];
        if (!isLastPage) {
            pageNumber++;
            for (let i = (pageNumber-1)*pageSize; i < (pageNumber*pageSize); i++) {
                if (i >= fullQuoteList.length) {
                    component.set("v.isLastPage", true);
                    break;
                }
                updatedQuoteList.push(fullQuoteList[i]);
            }
            component.set("v.pageNumber", pageNumber);
            component.set("v.quotelineItemList", updatedQuoteList);
            component.set("v.dataSize", updatedQuoteList.length);
        }
        helper.hideSpinner(component);
    },

    showSpinner : function(component) {
		let spinnerMain = component.find("spinner");
		$A.util.removeClass(spinnerMain, "slds-hide");
	},

	hideSpinner : function(component) {
		let spinnerMain = component.find("spinner");
		$A.util.addClass(spinnerMain, "slds-hide");
	},

    loadQuoteHelper : function(component, event, helper) {
        helper.showSpinner(component);
        let quoteId = event.target.id;
		let quotes = component.get('v.quoteList');
		for (let i = 0; i < quotes.length; i++) {
			if (quotes[i].Id == quoteId) {
				component.set("v.selectedQuoteId", quotes[i].Id);
				component.set("v.quoteFlag", true);
				break;
			}
		}
		component.set('v.mycolumns', [{label: 'Product Name', fieldName: 'Product_Name', type: 'text'},
									  {label: 'Description', fieldName: 'Description', type: 'text'},
									  {label: 'Quantity', fieldName: 'Quantity', type: 'Integer'},]);
		let action = component.get("c.fetchQuoteLineItems");
		action.setParams({
			quoteId: component.get("v.selectedQuoteId")
		});
		action.setCallback(this, function (response) {
			let state = response.getState();
			if (state === "SUCCESS") {
				let responseData = response.getReturnValue();
                let quoteNumber;
                for (let i = 0; i < responseData.length; i++) {
                	let eachQLI = responseData[i];
                    if (eachQLI.Product2) {
            			eachQLI.Product_Name = eachQLI.Product2.Name;
        			}
        			quoteNumber = eachQLI.Quote.QuoteNumber;
            	}
				component.set("v.fullQuotelineItemList", responseData);
    			let paginatedList = [];
    			for (let i = 0; i < component.get("v.pageSize"); i++) {
    				if (i >= responseData.length) {
    					component.set("v.isLastPage", true);
    					break;
					}
    				paginatedList.push(responseData[i]);
				}
    			component.set("v.selectedQuoteNumber", quoteNumber);
				component.set("v.quotelineItemList", paginatedList);
				component.set("v.dataSize", paginatedList.length);
			} else if (state === "ERROR") {
				helper.showToast("Error!", "An error occurred while fetching quote line items: " + response.getError(), "error");
			}
			helper.hideSpinner(component);
		});
		$A.enqueueAction(action);
    }
})