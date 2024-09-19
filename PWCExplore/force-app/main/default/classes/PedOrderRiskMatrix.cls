/**
* @description       : Used as Controller class for PedOrderRiskMatrix LWC Component.
* @author            : jadhavr@godrej.com
* @last modified on  : 21-12-2023
* @last modified by  : jadhavr@godrej.com
**/
public class PedOrderRiskMatrix {
    @AuraEnabled
    public static User getLoggedInUserDetails(){
       return [Select Id,Persona__c from User where Id = :UserInfo.getUserId() limit 1];
    }

	@AuraEnabled
    public static Order_Risk_Matrix__c getOrderRiskMatrix(String quoteId){
        try {
        //Fetch related Order Risk Matrix record exists for the Quote.
        Order_Risk_Matrix__c ormRecord1=getOrmRecord(quoteId);
      	
      /*If a related Order Risk Matrix record exists for the Quote, return it; otherwise,
		create a new Order Risk Matrix record and return it. */
        if(ormRecord1!=null){
            return ormRecord1;
        }
        else{
            Order_Risk_Matrix__c ormRecord2=new Order_Risk_Matrix__c();
            ormRecord2.Quote__c=quoteId;
            insert ormRecord2;
            Order_Risk_Matrix__c ormRecord3=getOrmRecord(quoteId);
            return ormRecord3;
        }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    private static Order_Risk_Matrix__c getOrmRecord(String quoteId){
        List<Order_Risk_Matrix__c> ormRecordList=[Select Id,Quote__c,Quote__r.Status, 
        CCL_Clause_1_Decision_1__c,CCL_Clause_1_Decision_2__c,CCL_Clause_1_Decision_3__c,CCL_Clause_2_Decision_1__c,
        CCL_Clause_2_Decision_2__c,CCL_Clause_3_Decision_1__c,CCL_Clause_3_Decision_2__c,CCL_Clause_3_Decision_3__c,
        CCL_Clause_3_Decision_4__c,CCL_Clause_3_Decision_5__c,CCL_Clause_4_Decision_1__c,CCL_Clause_4_Decision_2__c,
        CCL_Clause_5_Decision_1__c,CCL_Clause_6_Decision_1__c,CCL_Clause_7_Decision_1__c,CCL_Clause_8_Decision_1__c,
        CCL_Clause_9_Decision_1__c,CCL_Clause_10_Decision_1__c,CCL_Clause_11_Decision_1__c,CCL_Clause_12_Decision_1__c,
        CCL_Clause_13_Decision_1__c,CCL_Clause_14_Decision_1__c,CCL_Clause_15_Decision_1__c,CCL_Clause_16_Decision_1__c,CCL_Clause_17_Decision_1__c,CCL_Clause_18_Decision_1__c,
        CCL_Clause_19_Decision_1__c,CCL_Clause_20_Decision_1__c,CCL_Clause_21_Decision_1__c,CCL_Clause_1_Input_1__c,
        CCL_Clause_1_Input_2__c,CCL_Clause_1_Input_3__c,CCL_Clause_2_Input_1__c,CCL_Clause_2_Input_2__c,
        CCL_Clause_3_Input_1__c,CCL_Clause_3_Input_2__c,CCL_Clause_3_Input_3__c,CCL_Clause_3_Input_4__c,
        CCL_Clause_3_Input_5__c,CCL_Clause_4_Input_1__c,CCL_Clause_4_Input_2__c,CCL_Clause_5_Input_1__c,
        CCL_Clause_6_Input_1__c,CCL_Clause_7_Input_1__c,CCL_Clause_8_Input_1__c,CCL_Clause_9_Input_1__c,
        CCL_Clause_10_Input_1__c,CCL_Clause_11_Input_1__c,CCL_Clause_12_Input_1__c,CCL_Clause_13_Input_1__c,
        CCL_Clause_14_Input_1__c,CCL_Clause_15_Input_1__c,CCL_Clause_16_Input_1__c,CCL_Clause_17_Input_1__c,
        CCL_Clause_18_Input_1__c,CCL_Clause_19_Input_1__c,CCL_Clause_20_Input_1__c,CCL_Clause_21_Input_1__c,
        RM_Table_1_Risk_1_Likelihood_1__c,RM_Table_1_Risk_1_Consequence_1__c,RM_Table_1_Risk_1_Input_1__c,
        RM_Table_1_Risk_1_Likelihood_2__c,RM_Table_1_Risk_1_Consequence_2__c,RM_Table_1_Risk_1_Input_2__c,RM_Table_1_Risk_2_Likelihood_1__c,
        RM_Table_1_Risk_2_Consequence_1__c,RM_Table_1_Risk_2_Input_1__c,RM_Table_1_Risk_2_Likelihood_2__c,RM_Table_1_Risk_2_Consequence_2__c,
        RM_Table_1_Risk_2_Input_2__c,RM_Table_1_Risk_3_Likelihood_1__c,RM_Table_1_Risk_3_Consequence_1__c,RM_Table_1_Risk_3_Input_1__c,
        RM_Table_1_Risk_3_Likelihood_2__c,RM_Table_1_Risk_3_Consequence_2__c,RM_Table_1_Risk_3_Input_2__c,RM_Table_1_Risk_4_Likelihood_1__c,
        RM_Table_1_Risk_4_Consequence_1__c,RM_Table_1_Risk_4_Input_1__c,RM_Table_1_Risk_4_Likelihood_2__c,RM_Table_1_Risk_4_Consequence_2__c,
        RM_Table_1_Risk_4_Input_2__c,RM_Table_1_Risk_5_Likelihood_1__c,RM_Table_1_Risk_5_Consequence_1__c,RM_Table_1_Risk_5_Input_1__c,
        RM_Table_1_Risk_5_Likelihood_2__c,RM_Table_1_Risk_5_Consequence_2__c,RM_Table_1_Risk_5_Input_2__c,RM_Table_1_Risk_6_Likelihood_1__c,
        RM_Table_1_Risk_6_Consequence_1__c,RM_Table_1_Risk_6_Input_1__c,RM_Table_1_Risk_6_Likelihood_2__c,RM_Table_1_Risk_6_Consequence_2__c,
        RM_Table_1_Risk_6_Input_2__c,RM_Table_2_Sub_Criteria_1__c,RM_Table_2_Sub_Criteria_2__c,RM_Table_2_Sub_Criteria_3__c,
        DM_Table_1_Parameter_1_Measure__c,DM_Table_1_Parameter_2_Measure__c,DM_Table_1_Parameter_3_Measure__c,DM_Table_1_Parameter_4_Measure__c,
        DM_Table_1_Parameter_5_Measure__c,DM_Table_1_Parameter_6_Measure__c,DM_Table_1_Parameter_7_Measure__c,DM_Table_1_Parameter_8_Measure__c,
        DM_Table_1_Parameter_9_Measure__c,DM_Table_1_Parameter_10_Measure__c,DM_Table_1_Parameter_11_Measure__c,DM_Table_1_Parameter_12_Measure__c,
        DM_Table_1_Parameter_1_Input_1__c,DM_Table_1_Parameter_2_Input_1__c,DM_Table_1_Parameter_3_Input_1__c,DM_Table_1_Parameter_4_Input_1__c,
        DM_Table_1_Parameter_5_Input_1__c,DM_Table_1_Parameter_6_Input_1__c,DM_Table_1_Parameter_7_Input_1__c,DM_Table_1_Parameter_8_Input_1__c,
        DM_Table_1_Parameter_9_Input_1__c,DM_Table_1_Parameter_10_Input_1__c,DM_Table_1_Parameter_11_Input_1__c,DM_Table_1_Parameter_12_Input_1__c,
        DM_Table_1_Parameter_1_Input_2__c,DM_Table_1_Parameter_2_Input_2__c,DM_Table_1_Parameter_3_Input_2__c,DM_Table_1_Parameter_4_Input_2__c,
        DM_Table_1_Parameter_5_Input_2__c,DM_Table_1_Parameter_6_Input_2__c,DM_Table_1_Parameter_7_Input_2__c,DM_Table_1_Parameter_8_Input_2__c,
        DM_Table_1_Parameter_9_Input_2__c,DM_Table_1_Parameter_10_Input_2__c,DM_Table_1_Parameter_11_Input_2__c,DM_Table_1_Parameter_12_Input_2__c,
        DM_Table_1_Parameter_1_Input_3__c,DM_Table_1_Parameter_2_Input_3__c,DM_Table_1_Parameter_3_Input_3__c,DM_Table_1_Parameter_4_Input_3__c,
        DM_Table_1_Parameter_5_Input_3__c,DM_Table_1_Parameter_6_Input_3__c,DM_Table_1_Parameter_7_Input_3__c,DM_Table_1_Parameter_8_Input_3__c,
        DM_Table_1_Parameter_9_Input_3__c,DM_Table_1_Parameter_10_Input_3__c,DM_Table_1_Parameter_11_Input_3__c,
        DM_Table_1_Parameter_12_Input_3__c from Order_Risk_Matrix__c where Quote__c=:quoteId limit 1];
        
        if(!ormRecordList.isEmpty()){
            return ormRecordList[0];
        }
        else{
            return null;
        }
    }
    
  @AuraEnabled
    public static string updateOrderRiskMatrixRecord(Order_Risk_Matrix__c orderRiskMatrixRecord,Boolean isORMFormCompleted){
        try {
            update orderRiskMatrixRecord;
            Quote quoteRecord=[Select Id,Status from Quote where Id=:orderRiskMatrixRecord.Quote__c];
            if(isORMFormCompleted && quoteRecord.Status!=GlobalConstants.APPROVED && quoteRecord.Status!=GlobalConstants.QUOTE_STATUS_FINALIZED && 
                quoteRecord.Status!=GlobalConstants.Submitted_for_Approval && quoteRecord.Status!=GlobalConstants.Quote_Status_Order_Risk_Matrix_Form_Completed){
                quoteRecord.Status=GlobalConstants.Quote_Status_Order_Risk_Matrix_Form_Completed;
                update quoteRecord;
            }else if(!isORMFormCompleted && quoteRecord.Status==GlobalConstants.Quote_Status_Order_Risk_Matrix_Form_Completed){
                quoteRecord.Status=GlobalConstants.DRAFT;
                update quoteRecord;
            }
            return 'SUCCESS';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}