public without sharing class QuoteLineRuleEngine{
    
    public static void evaluteRule(List<sObject> lstNewObj,Map<Id,sObject> mapOldObj,String sScenarioType,String contextVariable){

        
        List<Quote_Line_Item_Approval_Rule__mdt> lstRule=new List<Quote_Line_Item_Approval_Rule__mdt>();
        Map<Id,Quote> mapQuote=new Map<Id,Quote>();
        Set<String> setQuoteID=new Set<String>();
        Set<String> setProductID=new Set<String>();
        Set<String> setUserID=new Set<String>();
        Set<String> setQuoteRecordType=new Set<String>();
        Set<String> setProductField=new Set<String>();
        Set<String> setUserFilterField=new Set<String>();
        Map<Id,Product2> mapProduct=new Map<Id,Product2>();
        map<Id,User> mapUser=new Map<Id,User>();
        String sProductQuery='SELECT ID,{0} FROM PRODUCT2 WHERE ID IN:setProductID';
        String sUserQuery='SELECT ID,{0} FROM USER WHERE ID IN :setUserID';
        List<String> fields = new List<String>(Quote.SObjectType.getDescribe().fields.getMap().keySet());
        String sQuoteQuery = ' select recordtype.developerName,Opportunity.Sub_Division__c, ' + String.join(fields, ',')+ ' from Quote where Id IN :setQuoteID'; //Appended Opportunity.Sub_Division__c  by Shreela on 22nd Dec 2022
        set<String> quoteRtForApproval = new set<String>{GlobalConstants.QUOTE_RECORDTYPE_APPLIANCE, //Added GlobalConstants.QUOTE_RECORDTYPE_APPLIANCE by Shreela on 7th September 2022 for SAEPB - 44 Appliance B2B
            GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_RENTAL,
            GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_EQUIPMENTS,
            GlobalConstants.QUOTE_RECORDTYPE_DEV_NAME_MHE_PARTS,
            GlobalConstants.QUOTE_MHE_CONTRACTS_RECORDTYPE_APINAME,
            GlobalConstants.RECORDTYPE_Locks_B2B,
            GlobalConstants.QUOTE_RECORDTYPE_SSG};
            String oldPaymentTerms; //Added by Shreela for SAEPB- 44
            Boolean oldCheckCatASec; //Added by Shreela for SMEPB 111
            Decimal oldReqCustDis; //Added by Shreela for SMEPB 111
                
                //Logic For Quote Line Item Level Filter
                if(sScenarioType==GlobalConstants.QUOTE_LINE_ITEM_SOBJECT_API_NAME){ 
                    Map<Id,QuoteLineItem> qliOldMapVariable = new Map<Id,QuoteLineItem>();//Added by Shreela for SAEPB- 44
                    if(contextVariable == GlobalConstants.Context_Variable_Update){
                        if(!mapOldObj.isEmpty() && mapOldObj!=null){
                            for(QuoteLineItem qliOld : (List<QuoteLineItem>)mapOldObj.values()){ 
                                qliOldMapVariable.put(qliOld.Id,qliOld);
                            }  
                        } 
                     }
                    
                                        
                    for(QuoteLineItem QLVar: (List<QuoteLineItem>)lstNewObj){
                        setQuoteID.add(QlVar.QuoteId);
                        setProductID.add(Qlvar.product2Id);
                    }
                    
                    mapQuote=new Map<Id,Quote>((List<Quote>)Database.query(sQuoteQuery));
                    for(Quote qvar: mapQuote.values()){
                        setQuoteRecordType.add(qvar.recordtype.developerName);
                    } 
                    
                    
                    lstRule=[select Id,Quote_Line_Item_Field_Value__c,Sub_Division__c,Quote_Record_Type_Filter__c,User_Filter_Field__c,User_Filter_Operator__c,User_Filter_Value__c,
                             Additional_Quote_Field_Filter_Field__c,Additional_Quote_Field_Filter_Operator__c,Additional_Quote_Field_Filter_Value__c,
                             Product_Field_Filter__c,Product_Field_Filter_Operator__c,Product_Field_Filter_Value__c,Quote_User_ID_Field__c,
                             Quote_Line_Item_Field_To_Be_Updated__c,(Select Id,QL_Field_Type__c,QL_Criteria_Field__c,QL_Criteria_Field_Operator_LB__c,Label,
                                                                     
                                                                     QL_Criteria_Field_Operator_UB__c,Quote_Line_Item_Approval_Rule__c,QL_Criteria_Field_Value_LB__c,QL_Criteria_Field_Value_UB__c
                                                                     from Quote_Line_Item_Approval_Rule_Entry__r)
                             from Quote_Line_Item_Approval_Rule__mdt where Quote_Record_Type_Filter__c IN :setQuoteRecordType and Is_Quote_Level_Rule__c=false];  //Added Sub_Division__c by Shreela on 23rd January 2023 for 
                    for(Quote_Line_Item_Approval_Rule__mdt oRulevar: lstRule){
                        if(oRuleVar.Product_Field_Filter__c!=null)
                            setProductField.add(oRuleVar.Product_Field_Filter__c);
                        if(oRuleVar.User_Filter_Field__c!=null)
                            setUserFilterField.add(oRuleVar.User_Filter_Field__c);   
                        for(Quote qvar: mapQuote.values()){
                            try{
                                if(oRulevar.Quote_User_ID_Field__c!=null && qvar.get(oRulevar.Quote_User_ID_Field__c)!=null) 
                                setUserID.add((Id)qvar.get(oRulevar.Quote_User_ID_Field__c));
                            } 
                            catch(Exception ex){
                                system.debug('==Exception occurred in QLI updates. Error message: '+ex.getMessage());
                            }
                        }
                        
                    }   
                    
                    mapUser=getUserMap(sUserQuery,setUserFilterField,setUserID);                
                    
                    for(QuoteLineItem oQLVar: (List<QuoteLineItem>)lstNewObj){
                        QuoteLineItem oQLOldvar;
                        if(contextVariable == GlobalConstants.Context_Variable_Update){
                            if(!qliOldMapVariable.isempty() && qliOldMapVariable!=null){
                                oldPaymentTerms = qliOldMapVariable.get(oQLVar.Id).Payment_Terms__c;
                                oldCheckCatASec = qliOldMapVariable.get(oQLVar.Id).Check_Category_A_Secondary__c; //Added by Shreela for SMEPB 111
                                oldReqCustDis =   qliOldMapVariable.get(oQLVar.Id).Requested_Customer_Discount__c; //Added by Shreela for SMEPB 111
                            }  //Added if loop by Shreela on 15th Dec 2022 for SAEPB - 44
                        } //Added if loop for contextVariable condition by Shreela on 16th Jan 2023 for SAEPB - 44
                        
                        
                        if(mapOldObj!=null && oQLVar.Id!=null){
                            oQLOldvar=(QuoteLineItem)mapOldObj.get(oQLVar.Id);
                        }
                        
                        Quote oQuotevar=mapQuote.get(oQLVar.QuoteId);
                        Boolean aggregateRuleEval = false;
                        for(Quote_Line_Item_Approval_Rule__mdt oRulevar: lstRule){
                            boolean bIsRuleMatched=true;
                            boolean bIsEntryMatched=true;
                            boolean bIsDataChanged=false;
                            boolean bIsRightUser=true;
                            boolean bIsProductFilterMatched=true;
                            //User Filter Evalution
                            if(oRulevar.Quote_User_ID_Field__c!=null && oQuotevar.get(oRulevar.Quote_User_ID_Field__c)!=null){
                                User oUser;
                                if(mapUser.ContainsKey((Id)oQuotevar.get(oRulevar.Quote_User_ID_Field__c)))
                                    ouser=mapUser.get((Id)oQuotevar.get(oRulevar.Quote_User_ID_Field__c));
                                
                                if(oUser!=null )
                                    bIsRightUser= stringEvaluator(ouser.get(oRulevar.User_Filter_Field__c),oRuleVar.User_Filter_Operator__c,oRuleVar.User_Filter_Value__c,'String');

                                if(!bIsRightUser){
                                    bIsRuleMatched=false;
                                    continue;
                                }
                            }
                            //Additional Filter Evalution
                            if(oRulevar.Additional_Quote_Field_Filter_Field__c!=null && oQuotevar.get(oRulevar.Additional_Quote_Field_Filter_Field__c)!=null){
                                boolean bIsAddFilterMatched= stringEvaluator(oQuotevar.get(oRulevar.Additional_Quote_Field_Filter_Field__c),
                                                                             oRuleVar.Additional_Quote_Field_Filter_Operator__c,oRuleVar.Additional_Quote_Field_Filter_Value__c,'String');
                                if(!bIsAddFilterMatched){
                                    bIsRuleMatched=false;
                                    continue;
                                }
                            }
                            //Product Filter Evalution   
                            if(oRulevar.Product_Field_Filter__c!=null  ){
                                
                                if(oQLVar!=null && oQLVar.get(oRulevar.Product_Field_Filter__c)!=null)   
                                    bIsProductFilterMatched= stringEvaluator(oQLVar.get(oRulevar.Product_Field_Filter__c),
                                                                             oRuleVar.Product_Field_Filter_Operator__c,oRuleVar.Product_Field_Filter_Value__c,'String');
                                    
                                if(!bIsProductFilterMatched){
                                    bIsRuleMatched=false;
                                    continue;
                                }
                            }
                            
                            //record type Filter Evalution
                            if(oQuotevar.RecordType.Developername!=oRuleVar.Quote_Record_Type_Filter__c){
                                continue;
                            }
                            //Rule Entry level Evalution 
                            if(bIsRuleMatched){
                                Map<Id,Map <String,boolean>> mapRuelEval=new Map<Id,Map <String,boolean>> ();
                                
                                for(Quote_Line_Item_Approval_Rule_Entry__mdt entryVar:oRulevar.Quote_Line_Item_Approval_Rule_Entry__r){
                                    Map <String,boolean> mapEntrylEval=valueEvaluator(oQLVar,oQLOldvar,entryVar);
                                    mapRuelEval.put(entryVar.Id,mapEntrylEval);                  
                                }
                                system.debug('mapRuelEval');
                                system.debug(mapRuelEval);
                                for(Id entryId: mapRuelEval.keySet()){
                                    
                                    if( !mapRuelEval.get(entryId).get('ENTRY'))
                                        bIsEntryMatched=false;  // Set flag even if any rule changes.

                                    //Added by Shreela for SMEPB 111.After quote is approved, if user changes the Requested Customer Discount , then Approval Status should be changed for Categor A product(MHE Equipment)
                                    if(!mapRuelEval.get(entryId).get('DATACHANGE')  && 
                                      (oQLVar.Check_Category_A_Secondary__c && oldCheckCatASec == oQLVar.Check_Category_A_Secondary__c)
                                      && (oldReqCustDis != oQLVar.Requested_Customer_Discount__c)){
                                        bIsDataChanged=true;
                                    }
                                    //Ended by Shreela for SMEPB 111
                                    
                                    else if(mapRuelEval.get(entryId).get('DATACHANGE'))
                                        bIsDataChanged=true;

                                    
                                    if(bIsEntryMatched && bIsDataChanged){//B2C
                                        // QL field Update
                                        if( mapQuote.get(oQLVar.QuoteId).Opportunity.Sub_Division__c == oRulevar.Sub_Division__c && 
                                           oRuleVar.Quote_Record_Type_Filter__c == GlobalConstants.QUOTE_RECORDTYPE_APPLIANCE && 
                                           oldPaymentTerms == oQLVar.Payment_Terms__c){ //Added if  by Shreela on 23rd Jan 2023 for SAEPB - 44 for bypassing this condition for Appliance B2C and also for those Aplaince B2B whose payment terms has been changed 
                                               oQLVar.put(oRuleVar.Quote_Line_Item_Field_To_Be_Updated__c,(Object)oRuleVar.Quote_Line_Item_Field_Value__c);
                                           }
                                        else if (oRuleVar.Quote_Record_Type_Filter__c != GlobalConstants.QUOTE_RECORDTYPE_APPLIANCE){//put appl for only that to bypass
                                            oQLVar.put(oRuleVar.Quote_Line_Item_Field_To_Be_Updated__c,(Object)oRuleVar.Quote_Line_Item_Field_Value__c);
                                        }
                                        //oQLVar.put(oRuleVar.Quote_Line_Item_Field_To_Be_Updated__c,(Object)oRuleVar.Quote_Line_Item_Field_Value__c); //Commented by Shreela since if else if condition has been added above
                                        oQLVar.put('Approved_Customer_Discount__c',0.00);
                                        oQLVar.put('Approved_SAC_ORC__c',0.00);
                                        oQLVar.put('Approved_WD_Retention__c',0.00);
                                        
                                    }
                                    else if((oQLVar.get(oRuleVar.Quote_Line_Item_Field_To_Be_Updated__c)!=null )
                                            && ! bIsEntryMatched
                                            &&( 
                                                (String.valueOf(oQLVar.get(oRuleVar.Quote_Line_Item_Field_To_Be_Updated__c))!='Approved')
                                                && (String.valueOf(oQLVar.get(oRuleVar.Quote_Line_Item_Field_To_Be_Updated__c))!='Submitted for Approval'))){
                                                    oQLVar.put(oRuleVar.Quote_Line_Item_Field_To_Be_Updated__c,'Approval Not Required');
                                                    oQLVar.put('Approved_Customer_Discount__c',oQLVar.Requested_Customer_Discount__c);
                                                    oQLVar.put('Approved_SAC_ORC__c',oQLVar.Requested_SAC_ORC__c);
                                                    oQLVar.put('Approved_WD_Retention__c',oQLVar.Requested_WD_Retention__c);

                                                }
                                }
                            }
                            aggregateRuleEval |= (bIsEntryMatched && bIsRuleMatched);
                            if(bIsEntryMatched && bIsDataChanged)
                                break;
                            
                            if ( aggregateRuleEval
                                && oQLVar.get(oRuleVar.Quote_Line_Item_Field_To_Be_Updated__c) != null
                                && String.valueOf(oQLVar.get(oRuleVar.Quote_Line_Item_Field_To_Be_Updated__c))!='Approved'
                                && String.valueOf(oQLVar.get(oRuleVar.Quote_Line_Item_Field_To_Be_Updated__c))!='Submitted for Approval'
                                && quoteRtForApproval.contains(oQLVar.Quote_Record_Type__c)) {
                                    if( mapQuote.get(oQLVar.QuoteId).Opportunity.Sub_Division__c == oRulevar.Sub_Division__c && 
                                       oRuleVar.Quote_Record_Type_Filter__c == GlobalConstants.QUOTE_RECORDTYPE_APPLIANCE && 
                                       oldPaymentTerms == oQLVar.Payment_Terms__c){ //Added if  by Shreela on 20th Jan 2023 for SAEPB - 44 for bypassing this condition for Appliance B2C and also for those Aplaince B2B whose payment terms has been changed 
                                           oQLVar.put(oRuleVar.Quote_Line_Item_Field_To_Be_Updated__c,(Object)oRuleVar.Quote_Line_Item_Field_Value__c);
                                       }
                                    else if (oRuleVar.Quote_Record_Type_Filter__c != GlobalConstants.QUOTE_RECORDTYPE_APPLIANCE){
                                        oQLVar.put(oRuleVar.Quote_Line_Item_Field_To_Be_Updated__c,(Object)oRuleVar.Quote_Line_Item_Field_Value__c);
                                    }
                                }
                            
                        }
                        // Joshna - DE807
                        if(oQLVar.Additional_Discount__c <= 0 && oQuotevar.Scheme_code__c!=null){
                            oQLVar.put('Approval_Status__c','Approval Not Required');
                            oQLVar.put('Approved_Customer_Discount__c',oQLVar.Requested_Customer_Discount__c);
                            oQLVar.put('Approved_SAC_ORC__c',oQLVar.Requested_SAC_ORC__c);
                            oQLVar.put('Approved_WD_Retention__c',oQLVar.Requested_WD_Retention__c);
                        }
                        // Joshna - DE996
                        if(oQLVar.Approval_Status__c == 'Approval Required') {
                            system.debug('Inside if line 175');
                            oQLVar.put('Approved_Customer_Discount__c',0.00);
                            oQLVar.put('Approved_SAC_ORC__c',0.00);
                            oQLVar.put('Approved_WD_Retention__c',0.00);
                        }
                    }
                }
        else
            if(sScenarioType==GlobalConstants.QUOTE_SOBJECT_API_NAME){
                //DE#1183 to update approval status depending on the Category field for SSG                        
                Id ssgRTId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get(GlobalConstants.QUOTE_RECORDTYPE_SSG).getRecordTypeId();
                Set<String> setRecordtype=new Set<String>();
                Set<Id> quoteId = new Set<Id>(); //Added by Shreela on 20th Jan 2023 for SAEPB-44
                for(Quote qVar: (List<Quote>) lstNewObj){
                    setRecordtype.add(qVar.recordtypeId);
                    setQuoteID.add(qVar.Id); //Added by Shreela on 20th Jan 2023 for SAEPB-44
                }
                mapQuote=new Map<Id,Quote>((List<Quote>)Database.query(sQuoteQuery));  //Added by Shreela on 20th Jan 2023 for SAEPB-44
                List<RecordType> lstRecType=[select developerName from recordtype where Id IN :setRecordtype];
                setRecordtype=new Set<String>();
                for(RecordType recVar: lstRecType)
                    setRecordtype.add(recVar.developerName);
                lstRule=[select Id,Sub_Division__c,Quote_Line_Item_Field_Value__c,Quote_Record_Type_Filter__c,User_Filter_Field__c,User_Filter_Operator__c,User_Filter_Value__c,
                         Additional_Quote_Field_Filter_Field__c,Additional_Quote_Field_Filter_Operator__c,Additional_Quote_Field_Filter_Value__c,
                         Product_Field_Filter__c,Product_Field_Filter_Operator__c,Product_Field_Filter_Value__c,Quote_User_ID_Field__c,
                         Quote_Line_Item_Field_To_Be_Updated__c,(Select Id,QL_Field_Type__c,QL_Criteria_Field__c,QL_Criteria_Field_Operator_LB__c,
                                                                 
                                                                 QL_Criteria_Field_Operator_UB__c,Quote_Line_Item_Approval_Rule__c,QL_Criteria_Field_Value_LB__c,QL_Criteria_Field_Value_UB__c
                                                                 from Quote_Line_Item_Approval_Rule_Entry__r)
                         from Quote_Line_Item_Approval_Rule__mdt where Is_Quote_Level_Rule__c=true  //Added Sub_Division__c by Shreela 20th January 2023 for SAEPB-44
                         and Quote_Record_Type_Filter__c IN :setRecordtype]; 
                for(Quote_Line_Item_Approval_Rule__mdt oRulevar: lstRule){
                    
                    
                    if(oRuleVar.User_Filter_Field__c!=null)
                        setUserFilterField.add(oRuleVar.User_Filter_Field__c);   
                    for(Quote qvar: mapQuote.values()){
                        if(oRulevar.Quote_User_ID_Field__c!=null && qvar.get(oRulevar.Quote_User_ID_Field__c)!=null) 
                            setUserID.add((Id)qvar.get(oRulevar.Quote_User_ID_Field__c));
                    }  
                }   
                mapUser=getUserMap(sUserQuery,setUserFilterField,setUserID);             
                for(Quote oQVar: (List<Quote>)lstNewObj){
                    Quote oQOldvar;
                    
                    //DE#1183 to update approval status depending on the Category field for SSG                        
                    if(oQVar.RecordTypeId == ssgRTId && oQVar.Approval_Status__c != GlobalConstants.APPROVED_STATUS 
                       && oQVar.Approval_Status__c != GlobalConstants.Submitted_for_Approval){
                           oQVar.Approval_Status__c = GlobalConstants.APPROVAL_NOT_REQUIRED_STATUS;
                           system.debug('line no 223 check engine'+oQVar.Approval_Status__c);//SET DEBUG FOR APPROVAL ISSUE IN SSG ON 18 MAY 2022
                       }
                    
                    if(mapOldObj!=null && oQVar.Id!=null){
                        oQOldvar=(Quote)mapOldObj.get(oQVar.Id);
                    }
                    Boolean aggregateRuleEval = false;
                    
                    for(Quote_Line_Item_Approval_Rule__mdt oRulevar: lstRule){
                        boolean bIsRuleMatched=true;
                        boolean bIsEntryMatched=true;
                        boolean bIsDataChanged=false;
                        boolean bIsRightUser=true;
                        //User Filter Evalution
                        if((oRulevar.Quote_User_ID_Field__c!=null ) && (oQVar.get(oRulevar.Quote_User_ID_Field__c)!=null)){
                            User oUser;
                            if(mapUser.ContainsKey((Id)oQVar.get(oRulevar.Quote_User_ID_Field__c)))
                                ouser=mapUser.get((Id)oQVar.get(oRulevar.Quote_User_ID_Field__c));
                            if(oUser!=null )   
                                bIsRightUser= stringEvaluator(ouser.get(oRulevar.User_Filter_Field__c),oRuleVar.User_Filter_Operator__c,oRuleVar.User_Filter_Value__c,'String');
                            if(!bIsRightUser){
                                bIsRuleMatched=false;
                                continue;
                            }
                        }  
                        
                        //Additional Filter Evalution
                        if(oRulevar.Additional_Quote_Field_Filter_Field__c!=null && oQVar.get(oRulevar.Additional_Quote_Field_Filter_Field__c)!=null){
                            boolean bIsAddFilterMatched= stringEvaluator(oQVar.get(oRulevar.Additional_Quote_Field_Filter_Field__c),
                                                                         oRuleVar.Additional_Quote_Field_Filter_Operator__c,oRuleVar.Additional_Quote_Field_Filter_Value__c,'String');
                            if(!bIsAddFilterMatched){
                                bIsRuleMatched=false;
                                continue;
                            }
                        }
                        
                        //Rule Entry level Evalution 
                        if(bIsRuleMatched){
                            Map<Id,Map <String,boolean>> mapRuelEval=new Map<Id,Map <String,boolean>> ();
                            
                            for(Quote_Line_Item_Approval_Rule_Entry__mdt entryVar:oRulevar.Quote_Line_Item_Approval_Rule_Entry__r){
                                Map <String,boolean> mapEntrylEval=valueEvaluator(oQVar,oQOldvar,entryVar);
                                mapRuelEval.put(entryVar.Id,mapEntrylEval);
                                
                            }
                            for(Id entryId: mapRuelEval.keySet()){
                                if(!mapRuelEval.get(entryId).get('ENTRY'))
                                    bIsEntryMatched=false;  // Set flag even if any rule changes.
                                if(mapRuelEval.get(entryId).get('DATACHANGE'))
                                    bIsDataChanged=true;  
                                
                                if(bIsEntryMatched && bIsDataChanged){
                                    // QL field Update
                                    // Updated on 23-07-2020 for DE1014 to avoid updation of Quote Approval status when it is already Submitted for Approval
                                    if((String.valueOf(oQVar.get(oRuleVar.Quote_Line_Item_Field_To_Be_Updated__c))!='Submitted for Approval'))
                                        oQVar.put(oRuleVar.Quote_Line_Item_Field_To_Be_Updated__c,(Object)oRuleVar.Quote_Line_Item_Field_Value__c);
                                }
                                else if((oQVar.get(oRuleVar.Quote_Line_Item_Field_To_Be_Updated__c)!=null )
                                        && ! bIsEntryMatched && ( 
                                            (String.valueOf(oQVar.get(oRuleVar.Quote_Line_Item_Field_To_Be_Updated__c))!='Approved')
                                            && (String.valueOf(oQVar.get(oRuleVar.Quote_Line_Item_Field_To_Be_Updated__c))!='Submitted for Approval'))
                                        && oQVar.Submit_for_Approval_QLI_Count__c <=0){
                                            oQVar.put(oRuleVar.Quote_Line_Item_Field_To_Be_Updated__c,'Approval Not Required');
                                        }
                            }
                        }
                        aggregateRuleEval |= (bIsEntryMatched && bIsRuleMatched);
                        if(bIsEntryMatched && bIsDataChanged)
                            break;
                        if (aggregateRuleEval
                            && oQVar.get(oRuleVar.Quote_Line_Item_Field_To_Be_Updated__c) != null
                            && String.valueOf(oQVar.get(oRuleVar.Quote_Line_Item_Field_To_Be_Updated__c))!='Approved'
                            && String.valueOf(oQVar.get(oRuleVar.Quote_Line_Item_Field_To_Be_Updated__c))!='Submitted for Approval'
                            && quoteRtForApproval.contains(oQVar.Record_Type_Developer_Name__c)) {
                                 //Added if else by Shreela on 23rd January 2023 for SAEPB-44 - bypas appl B2C earler exstng lne should wor only for appl B2b
                               
                                if(!mapQuote.isEmpty() && mapQuote.size() > 0){//added by pankaj on 3/8/2023 for BUG SMEPB-112.
                                    if(mapQuote.get(oQVar.Id).Opportunity.Sub_Division__c != Null && mapQuote.get(oQVar.Id).Opportunity.Sub_Division__c ==  GlobalConstants.B2C_SUBDIVISION &&
                                       oRuleVar.Quote_Record_Type_Filter__c == GlobalConstants.QUOTE_RECORDTYPE_APPLIANCE){
                                    }else{
                                        oQVar.put(oRuleVar.Quote_Line_Item_Field_To_Be_Updated__c,(Object)oRuleVar.Quote_Line_Item_Field_Value__c); 
                                    }
                            	}
                                //Ended by Shreela  on 23rd January 2023 for SAEPB-44                                
                            }
                    }
                     /* 23-04-2022      Alpana S   Change for downward revision on the discount %
                        Jira #  SSEPB-16 [SSG - Updates for submission of discount approval with buffer]                        
                        Requirement : The system should not ask the user for approval if it is a downward revision on the discount %.
                     */
                    //START SSEPB-16
                    if ((oQOldvar != Null && oQVar.RecordTypeId == ssgRTId && oQOldvar.Approval_Status__c != null && oQOldvar.Approval_Status__c == GlobalConstants.APPROVED_STATUS && 
                    oQVar.Quote_Discount__c != 0 && oQVar.Quote_Discount__c != null && oQOldvar.Quote_Discount__c != 0 && oQOldvar.Quote_Discount__c != null &&
                         oQVar.Quote_Discount__c < oQOldvar.Quote_Discount__c) 
                      || (oQOldvar != Null && oQVar.RecordTypeId == ssgRTId && oQOldvar.Approval_Status__c != null && oQOldvar.Approval_Status__c == GlobalConstants.APPROVED_STATUS &&
                        oQOldvar.Dealer_Margin_Dealer_order__c != null && oQOldvar.Dealer_Margin_Dealer_order__c != 0
                            && oQOldvar.Dealer_Margin_Dealer_order__c > oQVar.Dealer_Margin_Dealer_order__c) )
                    {
                        oQVar.Approval_Status__c = GlobalConstants.APPROVED_STATUS;                     
                    }
                    // END SSEPB-16 
                }
                
            }
    }
    //Get Dependent Product2
    private static Map<Id,Product2> getProductMap(String sProductQuery,Set<String> setProductField,Set<String> setProductID){
        
        String sQueryFilter;
        Map<Id,Product2> mapResponse=new Map<Id,Product2>();
        if(setProductField.size()>0){
            sQueryFilter=String.join(new List<String>(setProductField),',');
            sProductQuery=String.format(sProductQuery,new List<Object>{sQueryFilter});
            
            
            mapResponse=new Map<Id,Product2>((List<Product2>)Database.query(sProductQuery));
        }  
        return mapResponse;
    }
    //Get Dependent User
    private static Map<Id,User> getUserMap(String sUserQuery,Set<String> setuserField,Set<String> setUserID){
        
        String sQueryFilter;
        Map<Id,User> mapResponse=new Map<Id,User>();
        if(setuserField.size()>0){
            sQueryFilter=String.join(new List<String>(setuserField),',');
            sUserQuery=String.format(sUserQuery,new List<Object>{sQueryFilter});
            
            mapResponse=new Map<Id,User>((List<User>)Database.query(sUserQuery));
        }  
        return mapResponse;
    }
    // Check if strings are same
    private static boolean stringEvaluator(Object sourceValue, String sOperator,String sTargetvalue,String sDataType)  {
        if(sDataType=='String'){
            String sourceStr=String.valueOf(sourceValue);
            String targetStr=String.valueOf(sTargetvalue);
            
            if(sOperator=='Contains'){
                if(sourceStr!=null && sourceStr.Contains(targetStr))
                    return true;
            }
            else if(sOperator=='Does not contain'){
                if(sourceStr!=null && !sourceStr.Contains(targetStr))
                    return true;
            }
            else if(sOperator=='='){
                if(sourceStr!=null && sourceStr==targetStr)
                    return true;
                    
            }
            else if(sOperator=='!='){
                if(sourceStr!=null && sourceStr!=targetStr)
                    return true;
                 
            }
            else
                return false;

        }
        return false;
    }
    // Check if entry values are matching are same
    private static map<String,boolean> valueEvaluator(sObject qlvar, sObject qlOldVar, Quote_Line_Item_Approval_Rule_Entry__mdt entryVar)  {
        boolean bIsLBMatched=false;
        boolean bIsUBMatched=false;
        Double  dOldEvalvar;
        Double  dEvalvar;
        String  strOldEvalvar;
        String  strEvalvar;
        if(qlvar.get(entryvar.QL_Criteria_Field__c)!=null ){
            object evalVar=qlvar.get(entryvar.QL_Criteria_Field__c);
            object evalOldVar;
            
            if(GlobalConstants.FIELDTYPE_VS_ELIGIBILITY.containsKey(entryvar.QL_Field_Type__c.toLowerCase())
               && GlobalConstants.FIELDTYPE_VS_ELIGIBILITY.get(entryvar.QL_Field_Type__c.toLowerCase())){
                   dEvalvar=Double.valueOf(evalVar);
                   dEvalvar=(Decimal.valueOf(dEvalvar)).setScale(3);   //Added by pankaj & santosh on 13 Oct 2021
               }else
                   strEvalvar = String.valueOf(evalVar);
                   
            
            if(qlOldvar!=null){
                evalOldVar=qlOldVar.get(entryvar.QL_Criteria_Field__c);
                if(GlobalConstants.FIELDTYPE_VS_ELIGIBILITY.get(entryvar.QL_Field_Type__c.toLowerCase())){
                    if(evalOldVar <> null){
                        dOldEvalvar=Double.valueOf(evalOldVar); 
                        dOldEvalvar=(Decimal.valueOf(dOldEvalvar)).setScale(3);   //Added by pankaj & santosh on 13 Oct 2021
                    }
                }
                else
                    strOldEvalvar = String.valueOf(evalOldVar);

            }
            else
                dOldEvalvar=0.0;

            if(evalVar!=null){
                if(GlobalConstants.FIELDTYPE_VS_ELIGIBILITY.get(entryvar.QL_Field_Type__c.toLowerCase())){
                    dEvalvar=Double.valueOf(evalVar);
                    dEvalvar=(Decimal.valueOf(dEvalvar)).setScale(3); //Added by pankaj & santosh on 13 Oct 2021
                }
                else
                    strEvalvar = String.valueOf(evalVar);
                    
            }
            else
                dEvalvar=0.0;
            
            //For Lower Bound values
            if(entryVar.QL_Criteria_Field_Operator_LB__c!=null){
                if(entryVar.QL_Criteria_Field_Operator_LB__c=='>'){
                    if((dEvalvar>Double.valueOf(entryvar.QL_Criteria_Field_Value_LB__c))
                      ){
                          bIsLBMatched=true;
                      }
                    
                }
                
                else if(entryVar.QL_Criteria_Field_Operator_LB__c=='='){
                    if(GlobalConstants.FIELDTYPE_VS_ELIGIBILITY.get(entryvar.QL_Field_Type__c.toLowerCase())
                       && (dEvalvar==Double.valueOf(entryvar.QL_Criteria_Field_Value_LB__c))
                      ){
                          bIsLBMatched=true;
                      }else if(strEvalvar == String.valueOf(entryvar.QL_Criteria_Field_Value_LB__c)){
                          bIsLBMatched = true;
                      }
                    
                } 
                else if(entryVar.QL_Criteria_Field_Operator_LB__c=='<'){
                    if((dEvalvar<Double.valueOf(entryvar.QL_Criteria_Field_Value_LB__c))
                      ){
                          bIsLBMatched=true;
                      }
                    
                }
                else if(entryVar.QL_Criteria_Field_Operator_LB__c=='<='){
                    if((dEvalvar<=Double.valueOf(entryvar.QL_Criteria_Field_Value_LB__c))
                      ){
                          bIsLBMatched=true;
                      }
                    
                }
                else if(entryVar.QL_Criteria_Field_Operator_LB__c=='>='){
                    if((dEvalvar>=Double.valueOf(entryvar.QL_Criteria_Field_Value_LB__c))
                      ){
                          bIsLBMatched=true;
                      }
                    
                }
                
            }
            else{
                bIsLBMatched=true;
            }
            //For Upper Bound values
            if(entryVar.QL_Criteria_Field_Operator_UB__c!=null){
                if(entryVar.QL_Criteria_Field_Operator_UB__c=='>'){
                    if((dEvalvar>Double.valueOf(entryvar.QL_Criteria_Field_Value_UB__c))
                      ){
                          bIsUBMatched=true;
                      }
                    
                }
                else if(entryVar.QL_Criteria_Field_Operator_UB__c=='<'){
                    if((dEvalvar<Double.valueOf(entryvar.QL_Criteria_Field_Value_UB__c))
                      ){
                          bIsUBMatched=true;
                      }
                    
                }
                else if(entryVar.QL_Criteria_Field_Operator_UB__c=='<='){
                    if((dEvalvar<=Double.valueOf(entryvar.QL_Criteria_Field_Value_UB__c))
                      ){
                          bIsUBMatched=true;
                      }
                    
                }
                else if(entryVar.QL_Criteria_Field_Operator_UB__c=='>='){
                    if((dEvalvar>=Double.valueOf(entryvar.QL_Criteria_Field_Value_UB__c))){
                        bIsUBMatched=true;
                    }
                }
                else{
                    bIsUBMatched=true;
                }
            }
        }
        system.debug('dOldEvalvar ' + dOldEvalvar);
        system.debug('dEvalvar ' + dEvalvar);
        system.debug('strOldEvalvar ' + strOldEvalvar);
        system.debug('strEvalvar ' + strEvalvar);
        boolean bIsValueChanged=(dOldEvalvar !=dEvalvar) || (strOldEvalvar != strEvalvar) ?true:false;
        boolean bIsRuleMatched=(bIsLBMatched && bIsUBMatched)?true:false;
        return new map<String,boolean>{'ENTRY'=> bIsRuleMatched,'DATACHANGE'=>bIsValueChanged};
            }              
}