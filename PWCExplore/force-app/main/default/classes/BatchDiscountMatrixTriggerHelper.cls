/*------------------------------------------------------------------------
Author:        Ashwin Thale
Company:       Godrej
Description:   Batch class for Discount Matrix Trigger
Inputs:        NA
Test Class:    
History
18-05-2020      Ashwin Thale    Initial Release
----------------------------------------------------------------------------*/
public class BatchDiscountMatrixTriggerHelper implements Database.Batchable<sObject>{
    
    Map<String, Discount_Matrix__c> existingMatrixMap = new Map<String, Discount_Matrix__c>();
    List<Discount_Matrix__c> newMatrices=new List<Discount_Matrix__c>();
    Set<ID> setDisMatID = new Set<ID>();
    Set<String> setDisMatLevel = new Set<String>();
    Set<String> setDisMatPB = new Set<String>();
    Set<String> setDisMatItem = new Set<String>();
    DiscountMatrixTriggerHelper objDscMatHelp = new DiscountMatrixTriggerHelper();
    
    public BatchDiscountMatrixTriggerHelper(List<Discount_Matrix__c> newMatricesTrg,Map<String, Discount_Matrix__c> existingMatrixMapTrg,
                                            Set<String> setDisMatLevelTrg,Set<String> setDisMatPBTrg,Set<String> setDisMatItemTrg,Set<ID> setDisMatIDTrg){
        newMatrices=newMatricesTrg;
        existingMatrixMap=existingMatrixMapTrg;
        setDisMatLevel=setDisMatLevelTrg;
        setDisMatPB=setDisMatPBTrg;
        setDisMatItem=setDisMatItemTrg;
        setDisMatID=setDisMatIDTrg;
    }
    
    public Database.QueryLocator start(Database.BatchableContext context) {
        
        String strKey='';
        Boolean isCheck=false;
        String strBusinessUnit = GlobalConstants.APPLIANCE_BUSINESS_UNIT;
        String strStage = GlobalConstants.ACTIVE;
        
        String discountQuery = 'SELECT Id, Name, Level__c, Discount_Code__c, Exclusive__c, BP_Code_LN__c, ';
        discountQuery +='Business_Unit__c, Area__c, Manufacturer__c, Price_List__c, Delivery_Terms__c, ';
        discountQuery +='Order_Currency__c, Payment_Terms__c, Item_Type__c, Price_Group__c, ';
        discountQuery +='Item_Group__c, Item_Code__c, Channel__c, Sales_Office__c, Order_Type__c, ';
        discountQuery +='Zone__c, BP_Code__c, Product_Class__c, Product_Line__c, Stage__c, ';
        discountQuery +='Start_Date__c, Type__c, End_Date__c FROM Discount_Matrix__c WHERE Level__c IN :setDisMatLevel ';
        discountQuery +='AND Price_List__c IN : setDisMatPB AND Item_Code__c IN : setDisMatItem ';
        discountQuery +='AND Stage__c =: strStage AND Business_Unit__c =: strBusinessUnit AND ID NOT IN : setDisMatID ';
        
        return Database.getQueryLocator(discountQuery);
    }
    public void execute(Database.BatchableContext context, List<Discount_Matrix__c> listDiscountMatrix) {
        try {
            List<Discount_Matrix__c> lstMatricesToUpdate = new List<Discount_Matrix__c>();
            String strKey='';
            Boolean isCheck=false;
            for (Discount_Matrix__c objDscMat : listDiscountMatrix) 
            {
                strKey = objDscMatHelp.createKey(objDscMat);
                if(existingMatrixMap.containsKey(strKey)) {
                    Discount_Matrix__c objDscTrg = existingMatrixMap.get(strKey);
                    isCheck = objDscMatHelp.compareDiscountMatrix(objDscMat, objDscTrg);
                    if (isCheck) {
                        objDscMat.Stage__c = GlobalConstants.DISCOUNT_MATRIX_INACTIVE_STAGE;
                        objDscMat.End_Date__c = System.Today();
                        lstMatricesToUpdate.add(objDscMat);
                    }
                }
            }
            system.debug('lstMatricesToUpdate.size()='+lstMatricesToUpdate.size());
            If(lstMatricesToUpdate.size()>0) {
                Update lstMatricesToUpdate;
            }
        } catch (Exception ex) {
            System.debug('Error: ' + ex.getStackTraceString());
            Logger.logError('BatchDiscountMatrixTriggerHelper', 'execute', '', ex);
        }
    }
    public void finish(Database.BatchableContext context) {
        system.debug('BATCH EXECUTION FINISHED');
    }
    
}