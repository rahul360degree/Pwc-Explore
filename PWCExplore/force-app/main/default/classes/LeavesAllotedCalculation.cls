public class LeavesAllotedCalculation {
    public static void yearEndLogic(List<Contact> Contacts){
        List<Contact> cntlst = new List<Contact>();
        for(Contact Con :Contacts){
            if(Con.Leaves_Left__c > 10){
                if(Schema.sObjectType.Contact.fields.Leaves_Left__c.isUpdateable()){ 
                   Con.Leaves_Left__c = 10;     // more than 10 leaves will lapse in the year end
                   cntlst.add(Con);
                 }
            }
        }
        try{
        	update cntlst;
        }Catch(Exception e){
             Logger.logError('LeavesAllotedCalculation', 'yearEndLogic', '', e);
        }
    }
    public static void monthlyLeavesAlloted(List<Contact> Contacts){
        List<Contact> cntlst = new List<Contact>();
        for(Contact Con :Contacts){
            if(Con.Leaves_Left__c < 23){
                Con.Leaves_Left__c = Con.Leaves_Left__c + Decimal.valueOf(Label.No_of_leaves_alloted_every_month);
                cntlst.add(Con);
            }
            else{
                Con.Leaves_Left__c = 24;
            }
        }
        try{
            update cntlst;
        }Catch(Exception e){
             Logger.logError('LeavesAllotedCalculation', 'monthlyLeavesAlloted', '', e);
        }        
    }
}