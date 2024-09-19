/**
* @description       : PES division customised report for Monthly and Quarterly report
* @author            : snehalw@godrej.com
* @group             : 
* @last modified on  : 12-04-2023
* @last modified by  : snehalw@godrej.com
**/ 
public with sharing class PESReportsBatch implements schedulable {
    
    public static Map<String,String> totalOpportunitiesMap = new Map<String,String>();
    public Static String subject = ''; //Added by Shreela on 28th Nov 2023 for SPEP - 34
    
    // Fetching opportunity data
    @AuraEnabled
    public static Map<String,String> getOppDataForReport(Integer lastNMonth, Boolean isCalledFromLWC, Date fromDate,Date toDate){
        
        
        
        String oppQuoted =GlobalConstants.OPPORTUNITY_QUOTED;
        String oppInProcess=GlobalConstants.OPPORTUNITY_INPROCESS;  
        String oppRegret=GlobalConstants.OPPORTUNITY_REGRET;
        String oppShelved=GlobalConstants.OPPORTUNITY_SHELVED;
        String oppClosedWon=GlobalConstants.OPPORTUNITY_CLOSEDWON;
        String oppClosedLost=GlobalConstants.OPPORTUNITY_CLOSEDLOST;
        
        String oppRecType =GlobalConstants.OPPORTUNITY_RECORD_TYPE;
        String sectorOthers=GlobalConstants.OPPORTUNITY_SECTOR;
        String firmValue=GlobalConstants.OPPORTUNITY_FIRM; //Added by Shreela for SPEP-9 on 5th June 2023
        Integer oppCount; // to get opportunity count
        Decimal valuesInCr; // to get total value of Quoted_Value_In_lakh__c
        
        // added by Shreela on 25th Oct 2023 for SPEP-32
		String pesNAStr = System.Label.PES_Name_Not_Available;
        String startDateStr = System.Label.PES_Start_date;
        String endDateStr = System.Label.PES_End_Date;
        Datetime startDatetime;
        Datetime endDatetime;
        Date startDate;
        Date endDate;
        if(startDateStr != pesNAStr){
            startDatetime = Datetime.valueOf(startDateStr);
            startDate = startDatetime.date();
        }
        if(endDateStr!= pesNAStr){
            endDatetime = Datetime.valueOf(endDateStr);
            endDate = endDatetime.date();
        }    
        // ended by Shreela on 25th Oct 2023 for SPEP-32
        
        
        
        //No of Enquiries in Result Awaited till date in system 
        List<AggregateResult> quotedOpportunityList = Database.query('SELECT Sector__c sector, SUM(Quoted_Value_In_lakh__c) valuesInCr, COUNT(Id) totalOpp FROM Opportunity'+
                                                                     ' WHERE StageName =:oppQuoted ' +
                                                                     ' AND RecordType.Name =:oppRecType AND Firm_BQ__c=:firmValue' +  //Added Firm_BQ__c condition by Shreela for SPEP-9 on 5th June 2023
                                                                     ' GROUP BY Sector__c');
        
        totalOpportunityCount(quotedOpportunityList,'1');
        
        
        
        
        //No of Enquiries in Process till date in system
        List<AggregateResult> oppListInProcess = Database.query('SELECT Sector__c sector, SUM(Quoted_Value_In_lakh__c) valuesInCr, COUNT(Id) totalOpp FROM Opportunity'+
                                                                ' WHERE StageName =:oppInProcess ' +
                                                                ' AND RecordType.Name =:oppRecType AND Firm_BQ__c=:firmValue' +    //Added Firm_BQ__c condition by Shreela for SPEP-9 on 5th June 2023
                                                                ' GROUP BY Sector__c');
        
        totalOpportunityCount(oppListInProcess,'2'); 
        
        
        
        
        
        //No of Enquiries created in current Month 
        String allOpportunity = 'SELECT Sector__c sector, SUM(Quoted_Value_In_lakh__c) valuesInCr, COUNT(Id) totalOpp FROM Opportunity'+
            ' WHERE  RecordType.Name =:oppRecType AND Firm_BQ__c=: firmValue' ;   //Added Firm_BQ__c condition by Shreela for SPEP-9 on 5th June 2023
        
        
        if (isCalledFromLWC == true) {
            // if it is called from lwc component
            allOpportunity += ' AND DAY_ONLY(CreatedDate) >=: fromDate' +
                ' AND DAY_ONLY(CreatedDate) <=: toDate';
        } else if (startDateStr != pesNAStr && endDateStr!= pesNAStr) {
               allOpportunity += ' AND CreatedDate >= :startDate AND CreatedDate <=: endDate';
        }
          else if(lastNMonth != null){
               allOpportunity += ' AND CreatedDate = LAST_N_MONTHS:' + lastNMonth;// if it is called from scheduled job
        }
        
        allOpportunity += ' GROUP BY Sector__c';
        
        List<AggregateResult> allOpportunityAggrList = Database.query(allOpportunity);
        
        
        //No of Enquiries created in current Month total opp count
        totalOpportunityCount(allOpportunityAggrList,'3');
        
        //Enquiries Quoted in current month
        String quotedOppCurrentMonth = 'SELECT Sector__c sector, SUM(Quoted_Value_In_lakh__c) valuesInCr, COUNT(Id) totalOpp FROM Opportunity'+
            ' WHERE RecordType.Name =:oppRecType AND Firm_BQ__c=: firmValue' +  //Added Firm_BQ__c condition by Shreela for SPEP-9 on 5th June 2023
            ' AND Quote_Submission_date__c != null ' ;
        
        if (isCalledFromLWC == true) {
            quotedOppCurrentMonth += ' AND Quote_Submission_date__c >=: fromDate' +
                ' AND Quote_Submission_date__c <=: toDate';
        } else if (startDateStr != pesNAStr && endDateStr!= pesNAStr) {
               quotedOppCurrentMonth += ' AND Quote_Submission_date__c >= :startDate AND Quote_Submission_date__c <=: endDate';
        }
        else if(lastNMonth != null){
               quotedOppCurrentMonth += ' AND Quote_Submission_date__c = LAST_N_MONTHS:' + lastNMonth;
        }

        
        quotedOppCurrentMonth += ' GROUP BY Sector__c';
        
        List<AggregateResult> quotedOppCurrentMonthList = Database.query(quotedOppCurrentMonth);
        
        totalOpportunityCount(quotedOppCurrentMonthList,'4'); 
        
        
        //Total Decided in current month for Regret+shelved+ Closed won+ closed lost
        
        String shelvedWonLostOpp = 'SELECT Sector__c sector, SUM(Quoted_Value_In_lakh__c) valuesInCr, COUNT(Id) totalOpp FROM Opportunity'+
            ' WHERE (StageName =: oppRegret' + 
            ' OR StageName =: oppShelved' +
            ' OR StageName =: oppClosedWon' +
            ' OR StageName =: oppClosedLost' +                                                     
            ' )AND RecordType.Name =:oppRecType AND Firm_BQ__c=: firmValue' ;  //Added Firm_BQ__c condition by Shreela for SPEP-9 on 5th June 2023
        
        if (isCalledFromLWC == true) {
            shelvedWonLostOpp += ' AND CloseDate >=: fromDate' +
                ' AND CloseDate <=: toDate';
        } else if (startDateStr != pesNAStr && endDateStr!= pesNAStr) {
            shelvedWonLostOpp += ' AND CloseDate >= :startDate AND CloseDate <=: endDate';
        }
        else if(lastNMonth != null){
               shelvedWonLostOpp += ' AND CloseDate = LAST_N_MONTHS:' + lastNMonth;
        }
        
        shelvedWonLostOpp += ' GROUP BY Sector__c';
        
        List<AggregateResult> shelvedWonLostOppList = Database.query(shelvedWonLostOpp);
        
        
        totalOpportunityCount(shelvedWonLostOppList,'5');
        
        
        //Regret + Shelved in current month
        String shelvedOpportunity = 'SELECT Sector__c sector, SUM(Quoted_Value_In_lakh__c) valuesInCr, COUNT(Id) totalOpp FROM Opportunity'+
            ' WHERE (StageName =: oppRegret' + 
            ' OR StageName =: oppShelved' +
            ' )AND RecordType.Name =:oppRecType AND Firm_BQ__c=:firmValue ' ;  //Added Firm_BQ__c condition by Shreela for SPEP-9 on 5th June 2023
        
        if (isCalledFromLWC == true) {
            shelvedOpportunity += ' AND CloseDate >=: fromDate' +
                ' AND CloseDate <=: toDate';
        } else if (startDateStr != pesNAStr && endDateStr!= pesNAStr) {                       
            shelvedOpportunity += ' AND CloseDate >= :startDate AND CloseDate <=: endDate';
        }
        else if(lastNMonth != null){
               shelvedOpportunity += ' AND CloseDate = LAST_N_MONTHS:' + lastNMonth;
        }

        
        shelvedOpportunity += ' GROUP BY Sector__c';
        List<AggregateResult> shelvedOpportunityList = Database.query(shelvedOpportunity);
        
        
        totalOpportunityCount(shelvedOpportunityList,'6');
        
        
        
        //Closed Won in current month
        String closedWonOpp = 'SELECT Sector__c sector, SUM(Quoted_Value_In_lakh__c) valuesInCr, COUNT(Id) totalOpp FROM Opportunity'+
            ' WHERE (StageName =: oppClosedWon' + 
            ' )AND RecordType.Name =:oppRecType AND Firm_BQ__c=:firmValue' ;   //Added Firm_BQ__c condition by Shreela for SPEP-9 on 5th June 2023
        
        if (isCalledFromLWC == true) {
            closedWonOpp += ' AND CloseDate >=: fromDate' +
                ' AND CloseDate <=: toDate';
        } else if (startDateStr != pesNAStr && endDateStr!= pesNAStr) {          
            closedWonOpp += ' AND CloseDate >= :startDate AND CloseDate <=: endDate';
        }
        else if(lastNMonth != null){
               closedWonOpp += ' AND CloseDate = LAST_N_MONTHS:' + lastNMonth;
        }

        
        closedWonOpp += ' GROUP BY Sector__c';
        List<AggregateResult> closedWonOppList = Database.query(closedWonOpp);
        
        
        totalOpportunityCount(closedWonOppList,'7'); 
        
        
        
        
        //Closed Lost in current month
        String closedLostOpportunity = 'SELECT Sector__c sector, SUM(Quoted_Value_In_lakh__c) valuesInCr, COUNT(Id) totalOpp FROM Opportunity'+
            ' WHERE (StageName =: oppClosedLost' + 
            ' )AND RecordType.Name =:oppRecType AND Firm_BQ__c=:firmValue' ;   //Added Firm_BQ__c condition by Shreela for SPEP-9 on 5th June 2023
        
        if (isCalledFromLWC == true) {
            closedLostOpportunity += ' AND CloseDate >=: fromDate' +
                ' AND CloseDate <=: toDate';
        } else if (startDateStr != pesNAStr && endDateStr!= pesNAStr) {              
            closedLostOpportunity += ' AND CloseDate >= :startDate AND CloseDate <=: endDate';
        }
        else if(lastNMonth != null){
               closedLostOpportunity += ' AND CloseDate = LAST_N_MONTHS:' + lastNMonth;
        }
        
        closedLostOpportunity += ' GROUP BY Sector__c';
        List<AggregateResult> closedLostOpportunityList = Database.query(closedLostOpportunity);
        
        
        totalOpportunityCount(closedLostOpportunityList,'8'); 
        If(isCalledFromLWC == false){
            // To send Email notification
            sendEmailNotification(lastNMonth);
        }
        
        //totalOpportunitiesMap.put('FISCAL_YEAR',2022);
        return totalOpportunitiesMap;
    }    
    
    //To get total Opportunity count    
    public static void totalOpportunityCount( List<AggregateResult> listOpportunity , String count){
        totalOpportunitiesMap.put('DEFENCE_OPP_NO_ROW_'+ count ,'0');
        totalOpportunitiesMap.put('DEFENCE_VALUE_IN_CR_ROW_'+ count ,'0.00');
        totalOpportunitiesMap.put('NUCLEAR_OPP_NO_ROW_'+ count ,'0');
        totalOpportunitiesMap.put('NUCLEAR_VALUE_IN_CR_ROW_'+ count ,'0.00');
        totalOpportunitiesMap.put('EXPORT_OPP_NO_ROW_'+ count ,'0');
        totalOpportunitiesMap.put('EXPORT_VALUE_IN_CR_ROW_'+ count ,'0.00');
        totalOpportunitiesMap.put('GE_OPP_NO_ROW_'+ count ,'0');
        totalOpportunitiesMap.put('GE_VALUE_IN_CR_ROW_'+ count ,'0.00');
        totalOpportunitiesMap.put('OTHERS_OPP_NO_ROW_'+ count ,'0');
        totalOpportunitiesMap.put('OTHERS_VALUE_IN_CR_ROW_'+ count ,'0.00');
        totalOpportunitiesMap.put('TOTAL_OPP_NO_ROW_'+ count ,'0');
        totalOpportunitiesMap.put('TOTAL_VALUE_IN_CR_ROW_'+ count ,'0.00');
        
        If(!listOpportunity.isEmpty()){
            
            Integer oppCount = 0;// Initially declaring value as 0
            Decimal valuesInCr = 0.00;// Initially declaring value as 0
            String totalFormattedValue;
            Decimal totalValuesInCr;
            
            // Dividing sector wise opportunity count and Quoted_Value_In_lakh__c values
            for(AggregateResult ar : listOpportunity ){
                String formattedValue;
                if(ar.get('sector') == 'Defence'){

                    //Added by Shreela on 30th August 2023
                    totalOpportunitiesMap.put('DEFENCE_OPP_NO_ROW_'+ count ,String.valueOf((Integer) ar.get('totalOpp')));
                    totalOpportunitiesMap.put('DEFENCE_VALUE_IN_CR_ROW_'+ count ,((Decimal) ar.get('valuesInCr') != Null && ((Decimal) ar.get('valuesInCr') != 0 ||(Decimal) ar.get('valuesInCr') != 0.0)) ? formatDecimal((Decimal) ar.get('valuesInCr'), 2) : String.valueOf(0.00)); 
                    
                    
                }else if(ar.get('sector') == 'Nuclear'){
                    
                    //Added by Shreela on 30th August 2023
                    totalOpportunitiesMap.put('NUCLEAR_OPP_NO_ROW_'+ count ,String.valueOf((Integer) ar.get('totalOpp')));
                    totalOpportunitiesMap.put('NUCLEAR_VALUE_IN_CR_ROW_'+ count ,((Decimal) ar.get('valuesInCr') != Null && ((Decimal) ar.get('valuesInCr') != 0 ||(Decimal) ar.get('valuesInCr') != 0.0)) ? formatDecimal((Decimal) ar.get('valuesInCr'), 2) : String.valueOf(0.00)); 
                    
                    
                }else if(ar.get('sector') == 'Exports' && count != null && ar.get('totalOpp') != null && ar.get('valuesInCr') != null){

                    //Added by Shreela on 30th August 2023
                    totalOpportunitiesMap.put('EXPORT_OPP_NO_ROW_'+ count ,String.valueOf((Integer) ar.get('totalOpp')));
                    totalOpportunitiesMap.put('EXPORT_VALUE_IN_CR_ROW_'+ count ,((Math.round(((Decimal) ar.get('valuesInCr')*100)/100)) != Null && ((Math.round(((Decimal) ar.get('valuesInCr')*100)/100)) != 0 ||(Math.round(((Decimal) ar.get('valuesInCr')*100)/100)) != 0.0)) ? formatDecimal(Math.round(((Decimal) ar.get('valuesInCr')*100)/100), 2) : String.valueOf(0.00)); 
                    
                    
                }else if(ar.get('sector') == 'General Engineering'){
                    
                    //Added by Shreela on 30th August 2023
                    totalOpportunitiesMap.put('GE_OPP_NO_ROW_'+ count ,String.valueOf((Integer) ar.get('totalOpp')));
                    totalOpportunitiesMap.put('GE_VALUE_IN_CR_ROW_'+ count ,((Decimal) ar.get('valuesInCr') != Null && ((Decimal) ar.get('valuesInCr') != 0 ||(Decimal) ar.get('valuesInCr') != 0.0)) ? formatDecimal((Decimal) ar.get('valuesInCr'), 2) : String.valueOf(0.00)); 
                    
                    
                }
                else if(ar.get('sector') == 'Others'){

                    //Added by Shreela on 30th August 2023
                    totalOpportunitiesMap.put('OTHERS_OPP_NO_ROW_'+ count ,String.valueOf((Integer) ar.get('totalOpp')));
                    totalOpportunitiesMap.put('OTHERS_VALUE_IN_CR_ROW_'+ count ,((Decimal) ar.get('valuesInCr') != Null && ((Decimal) ar.get('valuesInCr') != 0 ||(Decimal) ar.get('valuesInCr') != 0.0)) ? formatDecimal((Decimal) ar.get('valuesInCr'), 2) : String.valueOf(0.00)); 
                    
                    
                }
                

                oppCount = oppCount + (Integer) ar.get('totalOpp');                
                //Added by Shreela on 30th August 2023
                if((Decimal) ar.get('valuesInCr') != Null 
                  ){
                    ValuesInCr = ValuesInCr + (Decimal) ar.get('valuesInCr');
                    totalFormattedValue = formatDecimal(ValuesInCr, 2);
                } 
                
            }
            
            totalOpportunitiesMap.put('TOTAL_OPP_NO_ROW_'+ count ,String.valueOf(oppCount));
            
            //Added by Shreela on 30th August 2023
            totalOpportunitiesMap.put('TOTAL_VALUE_IN_CR_ROW_'+ count ,String.valueOf(totalFormattedValue));
            
            
        }
        
    }
    public static void sendEmailNotification(Integer lastNMonth ){
        string fiscalYr;
        String previousQuarterStr;
        String currentQuarterStr;
        String currentHalfStr; //Added by Shreela on 25th Oct 2023 for SPEP - 34
        
        String PrevMonth = system.now().addMonths(-1).format('MMMM');
        // Get the current date
        Integer currentDateMonth = Date.today().month();
        Integer todayMonth = system.today().month();
        Integer todayYear = system.today().year();
        
        if (todayMonth>=1 && todayMonth<4){ //Modified by Shreela on 14th Nov 2023 for SPEP - 34
            fiscalYr = String.valueOf(todayYear-1).substring(2, 4) + '-' + String.valueOf(todayYear).substring(2, 4); // Months Jan Feb Mar will always have prev year - current year like Feb 2023 is 22-23
        }
        else{
            fiscalYr = String.valueOf(todayYear).substring(2, 4) + '-' +String.valueOf(todayYear+1).substring(2, 4);
        }
        
        // Get the current quarter
        if ((currentDateMonth>=1) && (currentDateMonth<=3)){
            currentQuarterStr = 'Q4';
        }
            
        else if ((currentDateMonth>=4) && (currentDateMonth<=6)){
            currentQuarterStr = 'Q1';
        }
            
        else if ((currentDateMonth>=7) && (currentDateMonth<=9)){
            currentQuarterStr = 'Q2';
        }
            
        else if ((currentDateMonth>=10) && (currentDateMonth<=12)){
            currentQuarterStr = 'Q3';
        }
          
        //Added by Shreela for SGF - 53
        if(currentDateMonth>=4  && (currentDateMonth<10)){
            currentHalfStr = 'H1';
        }
        else if((currentDateMonth>=10) || (currentDateMonth>=1  && currentDateMonth<=3)){
            currentHalfStr = 'H2';
        }
        
        // Get the previous quarter based on the current quarter
        previousQuarterStr = currentQuarterStr == 'Q4' ? 'Q3' : 
        currentQuarterStr == 'Q1' ? 'Q4' :
        currentQuarterStr == 'Q2' ? 'Q1' :
        currentQuarterStr == 'Q3' ? 'Q2' :
        null;
        
        // Get the previous half term based on the current half term
        String previousHalfStr = currentHalfStr == 'H2' ? 'H1' : currentHalfStr == 'H1' ? 'H2' :null; //Ended by Shreela for SPEP - 34 on 14th Nov 2023
        
        
        List<String> toAddresses = Label.PES_Report_Email_Notification_To_Addresses.split(',');
        
        EmailTemplate template;
        
        //Added by Shreela on 28th Nov 2023 for SPEP - 34
        String reportHeader='';
        String reportHeaderDuration ='';
        String duration = '';
        
        If(lastNMonth == 1 || lastNMonth == 3 || lastNMonth == 6 || lastNMonth == 9 || lastNMonth == 12){
            template = [SELECT Id 
                        FROM EmailTemplate
                        WHERE Name =:GlobalConstants.PES_Common_Email_Template
                        WITH SECURITY_ENFORCED limit 1 ];
            if(lastNMonth == 1){
                reportHeader = 'Sales Report for the month of ';
                reportHeaderDuration = PrevMonth+' '+fiscalYr;
                duration = PrevMonth;
                subject = 'Monthly Consolidated Sales Report';               
            }
            else if(lastNMonth == 3){
                reportHeader = 'Sales Report for the quarter of ';
                reportHeaderDuration = previousQuarterStr+' '+fiscalYr;
                duration = previousQuarterStr;
                subject = 'Quarterly Consolidated Sales Report'; 
            }
            else if(lastNMonth == 6){
                reportHeader = 'Half-Yearly Report: ';
                reportHeaderDuration = previousHalfStr+' '+fiscalYr;
                duration = previousHalfStr;
                subject = 'Half-Yearly Consolidated Sales Report'; 
                
            }
            else if(lastNMonth == 9){
                reportHeader = 'Sales Report of Last 09 Months: FY'+' '+fiscalYr;
                duration = 'last 09 months';
                subject = '9-Month Consolidated Sales Report'; 
                
            }
            else if(lastNMonth == 12){
                reportHeader = 'Year-end Sales Report : FY'+' '+fiscalYr;
                duration = fiscalYr;
                subject = 'Fiscal Year-end  Sales Report';                
            }
                        
        }
        //Ended by Shreela on 28th Nov 2023 for SPEP - 34
        
        OrgWideEmailAddress owea =  [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName=:GlobalConstants.One_CRM WITH SECURITY_ENFORCED]; 
        
        List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>(); 
        Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(template.Id, null, null);
        String htmlBody=message.gethtmlBody();
        
        
        //Added by Shreela on 28th Nov 2023
        htmlBody=htmlBody.replace('REPORT_HEADER',reportHeader);
        htmlBody=htmlBody.replace('REPORTHEADER_DURATION',reportHeaderDuration);
        htmlBody=htmlBody.replace('DURATION',duration);
        htmlBody=htmlBody.replace('SUBJECT',subject);
        //Ended by Shreela on 28th Nov 2023
        
        for(string key : totalOpportunitiesMap.keySet()){
            htmlBody=htmlBody.replace(key, totalOpportunitiesMap.get(key) != null ?totalOpportunitiesMap.get(key):'0');  
        }
        
        message.setSubject(subject);
        message.sethtmlBody(htmlBody);
        message.setOrgWideEmailAddressId(owea.id);
        message.setToAddresses(toAddresses);
        mailList.add(message);    
        if(!mailList.isEmpty()) {                       
            Messaging.sendEmail(mailList);
        }
    }
    
    
    public void execute(SchedulableContext sc){

	    if(System.Label.PES_Monthly_Execute_Job != GlobalConstants.NO_CONSTANT){
		    getOppDataForReport(1,false,null,null); // To send Monthly report from schedule job
		}
        Date currentDate = Date.today();
        Integer currentMonth = currentDate.month();     
        
        if((currentMonth == 1 || currentMonth == 4 || currentMonth == 7 || currentMonth == 10 && System.Label.PES_Quarterly_Execute_Job != GlobalConstants.NO_CONSTANT)
		    ||(System.Label.PES_Quarterly_Execute_Job == GlobalConstants.YES_CONSTANT)){// To send Quarterly report from schedule job
            getOppDataForReport(3,false,null,null);
            
        } 
         
        //Added by Shreela for SPEP-32 on 25th Oct 2023
        if(currentMonth == 4 || currentMonth == 10 && System.Label.PES_Halfly_Execute_Job != GlobalConstants.NO_CONSTANT
		   ||(System.Label.PES_Halfly_Execute_Job == GlobalConstants.YES_CONSTANT)){
           getOppDataForReport(6, false,null,null); //Half year
        }
		
		//Added by Shreela for SPEP - 34 on 14th Nov 2023
		if(currentMonth == 1 && System.Label.PES_9_Months_Execute_Job != GlobalConstants.NO_CONSTANT
		   ||(System.Label.PES_9_Months_Execute_Job == GlobalConstants.YES_CONSTANT)){
           getOppDataForReport(9, false,null,null); //Half year
        }
        
        if(currentMonth == 4 && System.Label.PES_Yearly_Execute_Job != GlobalConstants.NO_CONSTANT
		   ||(System.Label.PES_Yearly_Execute_Job == GlobalConstants.YES_CONSTANT)){
            getOppDataForReport(12, false,null,null); //Previous fiscal year
        } 
		//Ended by Shreela for SPEP - 34 on 14th Nov 2023
    }
    
    //Added by Shreela on 30th August 2023 //For formatting values
    public static String formatDecimal(Decimal value, Integer decimalPlaces) {   
        String valueStr = String.valueOf(value.format());
        Integer indexOfDecimal = valueStr.indexOf('.');
        
        if (indexOfDecimal == -1) {
            // No decimal point found, add decimal places
            return valueStr + '.' + '0'.repeat(decimalPlaces);
        } else {
            // Decimal point found, adjust decimal places
            Integer currentDecimalPlaces = valueStr.length() - indexOfDecimal - 1;
            if (currentDecimalPlaces < decimalPlaces) {
                return valueStr + '0'.repeat(decimalPlaces - currentDecimalPlaces);
            } else {
                return valueStr.substring(0, indexOfDecimal + decimalPlaces + 1);
            }
        }
    }
}