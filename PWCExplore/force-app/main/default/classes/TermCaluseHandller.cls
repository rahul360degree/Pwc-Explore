/*------------------------------------------------------------------------
	@Author:        Saurabh Mehta
	@File Name:     TermCaluseHandller.cls
	@Company:       Stetig
	@Description:   NA
	@Inputs:        NA
	@Last Modified: 26/11/2021
	@Test Class:    
----------------------------------------------------------------------------*/
public class TermCaluseHandller {
	
    //Method is used to update the log on negotiation
    public static void updatenegotiationLog(List<Term_Item__c> newTermItemList){
	
	for (Term_Item__c term: newTermItemList) {
           
            String user_name = Userinfo.getName();
            if (String.isNotBlank(term.Negotiation_Details__c)) { // process only if the data is not blank
                if (term.Negotiation_Counter__c == null) {
                    term.Negotiation_Counter__c = 1;
                } else {
                    term.Negotiation_Counter__c += 1;

                }
                if (term.Negotiation_Log__c == null) {
                    if (term.Negotiation_Status__c.equalsIgnoreCase(ElbConstantsClass.NEGOTIATION_AGREED)) {
                        term.Negotiation_Log__c = '<span style="color:green;\\">' + System.today().format() + '|' + 'Negotiation ' + term.Negotiation_Counter__c + ': ' + term.Negotiation_Details__c + ': User:' + user_name +
                            '| Status: ' + term.Negotiation_Status__c + '</span>';
                        
                    }else if (term.Negotiation_Status__c.equalsIgnoreCase(ElbConstantsClass.NEGOTIATION_DISAGREED)) {
                        term.Negotiation_Log__c += '<br/><br/> <span style="color:red;\\">' + System.today().format() + '|' + 'Negotiation ' + term.Negotiation_Counter__c + ': ' + term.Negotiation_Details__c + ': User:' + user_name +
                            '| Status: ' + term.Negotiation_Status__c + '</span>';
                        
                    }else {
                        term.Negotiation_Log__c = '<span style="color:blue;\\">' + System.today().format() + '|' + 'Negotiation ' + term.Negotiation_Counter__c + ': ' + term.Negotiation_Details__c + ': User:' + user_name +
                            '| Status: ' + term.Negotiation_Status__c + '</span>';
                    }
                    
                } else if (term.Negotiation_Status__c.equalsIgnoreCase(ElbConstantsClass.NEGOTIATION_AGREED)) {
                    term.Negotiation_Log__c += '<br/><br/> <span style="color:green;\\">' + System.today().format() + '|' + 'Negotiation ' + term.Negotiation_Counter__c + ': ' + term.Negotiation_Details__c + ': User:' + user_name +
                        '| Status: ' + term.Negotiation_Status__c + '</span>';
                    
                } 
                else if (term.Negotiation_Status__c.equalsIgnoreCase(ElbConstantsClass.NEGOTIATION_DISAGREED)) {
                    term.Negotiation_Log__c += '<br/><br/> <span style="color:red;\\">' + System.today().format() + '|' + 'Negotiation ' + term.Negotiation_Counter__c + ': ' + term.Negotiation_Details__c + ': User:' + user_name +
                        '| Status: ' + term.Negotiation_Status__c + '</span>';
                    
                } else {
                    term.Negotiation_Log__c += '<br/><br/> <span style="color:blue;\\">' + System.today().format() + '|' + 'Negotiation ' + term.Negotiation_Counter__c + ': ' + term.Negotiation_Details__c + ': User:' + user_name +
                        '| Status: ' + term.Negotiation_Status__c + '</span>';
                }
                term.Negotiation_Details__c = '';
                term.Negotiation_Status__c = '';
            }
        }	
	}
}