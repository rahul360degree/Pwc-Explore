public class GenerateLabelListViewControlle {
    public List<Category_Line_Item__c> getIDs {get; set;}
    public String catIds {get; set;}
    public Boolean allowDML {get; set;}

    public GenerateLabelListViewControlle(ApexPages.StandardSetController controller){
        system.debug('Get Selected');
        getIDs = (List<Category_Line_Item__c>)controller.getSelected();
        catIds = ''; 
        for(Category_Line_Item__c cat : getIDs){
            catIds += cat.Id + ','; 
            System.debug ('Cat ID : '+catIds);
        }
        catIds = catIds.removeEnd(','); 
        
        // Set allowDML to true if DML operations are allowed in this context
        allowDML = true;
    }

    public void updateStatus() {
        if(allowDML) {
            List<Category_Line_Item__c> recordsToUpdate = new List<Category_Line_Item__c>();

            // Iterate over selected records and update their Status__c field
            for(Category_Line_Item__c cat : getIDs) {
                cat.Status__c = 'To be Categorised'; 
                recordsToUpdate.add(cat);
            }
            system.debug('recordsToUpdate'+recordsToUpdate[0].Status__c);
            // Update records
            if(!recordsToUpdate.isEmpty()) {
                try {
                    update recordsToUpdate;
                } catch(Exception e) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error updating records: ' + e.getMessage()));
                }
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'DML operations are not allowed in this context.'));
        }
    }
}