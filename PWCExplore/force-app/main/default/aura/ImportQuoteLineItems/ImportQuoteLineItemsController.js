({
	doInit: function (component, event, helper) {
		helper.doInitHelper(component, event, helper);
	},
	quoteClicked: function (component, event, helper) {
		helper.loadQuoteHelper(component, event, helper);
	},
	handleSelect: function (component, event, helper) {
		helper.selectRowsHelper(component, event, helper);
	},
	importQLI: function (component, event, helper) {
		helper.importQLIHelper(component, event, helper);
	},
    handlePrev: function (component, event, helper) {
        helper.getPreviousPage(component, event, helper);
    },
    handleNext: function (component, event, helper) {
        helper.getNextPage(component, event, helper);
    }
})