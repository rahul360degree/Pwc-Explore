/*------------------------------------------------------------------------
Author:        Manasi Londhe
Company:       Salesforce
Description:   Helper class for Discount Matrix Trigger
Inputs:        NA
Test Class:    
History
18-05-2020      Manasi Londhe     Initial Release
----------------------------------------------------------------------------*/

public without sharing class DiscountMatrixTriggerHelper {
    
    /*------------------------------------------------------------------------
Author:        Ashwin Thale
Company:       Godrej Infotech
Description:   Method to find similar Discount Matrix and Inactive it and update End Date.
Inputs:        List of SObject of Discount Matrix Records.
Test Class:    

History
17-01-2024      Ashwin Thale     Initial Release
----------------------------------------------------------------------------*/
    
    public void updateStageAndEndDate(List<Discount_Matrix__c> newMatrices) {
        try {
            Set<ID> setDisMatID = new Set<ID>();
            Set<String> setDisMatLevel = new Set<String>();
            Set<String> setDisMatPB = new Set<String>();
            Set<String> setDisMatItem = new Set<String>();
            Map<String, Discount_Matrix__c> existingMatrixMap = new Map<String, Discount_Matrix__c>();
            
            String strKey='';
            for (Discount_Matrix__c objDscTrg : newMatrices) {
                setDisMatID.add(objDscTrg.ID);
                setDisMatLevel.add(objDscTrg.Level__c);
                setDisMatPB.add(objDscTrg.Price_List__c);
                setDisMatItem.add(objDscTrg.Item_Code__c);
                strKey = createKey(objDscTrg);
                existingMatrixMap.put(strKey, objDscTrg);
            }
            
            BatchDiscountMatrixTriggerHelper bct = new BatchDiscountMatrixTriggerHelper(newMatrices,existingMatrixMap,setDisMatLevel,setDisMatPB,setDisMatItem,setDisMatID);
            database.executebatch(bct,10);
        }
        catch(Exception ex) {
            Logger.logError('DiscountMatrixTriggerHelper', 'updateStageAndEndDate', '', ex);
        }
    }
    
    /*------------------------------------------------------------------------
Author:        Ashwin Thale
Company:       Godrej Infotech
Description:   Method to compare Existing Discount Matrix Records and New Disocunt Matrix Records.

History
17-01-2024      Ashwin Thale     Initial Release
----------------------------------------------------------------------------*/
    
	public Boolean compareDiscountMatrix(Discount_Matrix__c objDscMat, Discount_Matrix__c objDscTrg) {
        Boolean isCheck=false;
        if(objDscMat.Level__c == objDscTrg.Level__c && objDscMat.Discount_Code__c == objDscTrg.Discount_Code__c &&
                   objDscMat.BP_Code_LN__c == objDscTrg.BP_Code_LN__c &&
                   objDscMat.Business_Unit__c == objDscTrg.Business_Unit__c && objDscMat.Area__c == objDscTrg.Area__c &&
                   objDscMat.Manufacturer__c == objDscTrg.Manufacturer__c && objDscMat.Price_List__c == objDscTrg.Price_List__c &&
                   objDscMat.Delivery_Terms__c == objDscTrg.Delivery_Terms__c && objDscMat.Order_Currency__c == objDscTrg.Order_Currency__c &&
                   objDscMat.Payment_Terms__c == objDscTrg.Payment_Terms__c && objDscMat.Item_Type__c == objDscTrg.Item_Type__c &&
                   objDscMat.Price_Group__c == objDscTrg.Price_Group__c && objDscMat.Item_Group__c == objDscTrg.Item_Group__c &&
                   objDscMat.Item_Code__c == objDscTrg.Item_Code__c && objDscMat.Channel__c == objDscTrg.Channel__c &&
                   objDscMat.Sales_Office__c == objDscTrg.Sales_Office__c && objDscMat.Order_Type__c == objDscTrg.Order_Type__c &&
                   objDscMat.Zone__c == objDscTrg.Zone__c && objDscMat.BP_Code__c == objDscTrg.BP_Code__c &&
                   objDscMat.Product_Class__c == objDscTrg.Product_Class__c && objDscMat.Product_Line__c == objDscTrg.Product_Line__c) {
            isCheck=true;
        }
        return isCheck;
    }
    
    /*------------------------------------------------------------------------
Author:        Ashwin Thale
Company:       Godrej Infotech
Description:   Method to create an new Key from the Obejct fields for Map.

History
17-01-2024      Ashwin Thale     Initial Release
----------------------------------------------------------------------------*/
    
    public String createKey(Discount_Matrix__c objDsc) {
        String strKey = objDsc.Level__c + '-' + objDsc.Discount_Code__c + 
                         '-' + objDsc.BP_Code_LN__c + '-' + objDsc.Business_Unit__c + '-' + objDsc.Area__c +
                         '-' + objDsc.Manufacturer__c + '-' + objDsc.Price_List__c + '-' + objDsc.Delivery_Terms__c +
                         '-' + objDsc.Order_Currency__c + '-' + objDsc.Payment_Terms__c + '-' + objDsc.Item_Type__c +
                         '-' + objDsc.Price_Group__c + '-' + objDsc.Item_Group__c + '-' + objDsc.Item_Code__c +
                         '-' + objDsc.Channel__c + '-' + objDsc.Sales_Office__c + '-' + objDsc.Order_Type__c +
                         '-' + objDsc.Zone__c + '-' + objDsc.BP_Code__c + '-' + objDsc.Product_Class__c +
                         '-' + objDsc.Product_Line__c;
        return strKey;
    }
    
    public void UpdateOrderLinesIfMatrixDeactivated(List<Discount_Matrix__c> newMatrices,Map<Id,Discount_Matrix__c> oldMatrices){
        List<Discount_Matrix__c> matricesApplicable=new List<Discount_Matrix__c>();
        Set<Id> matricesIds=new Set<Id>();
        for(Discount_Matrix__c matrix : newMatrices){
            if(matrix.Level__c!=null && matrix.Stage__c!=oldMatrices.get(matrix.Id).Stage__c && (matrix.Stage__c=='Inactive' || matrix.Stage__c=='Draft'))
                matricesIds.add(matrix.Id);
        }
        if(matricesIds.size()>0){
            String whereClause=' Order.Status=\''+GlobalConstants.ORDER_DEFAULT_STATUS+'\' AND (';
            for(Integer i=2;i<12;i++){
                if(i<11)
                    whereClause+='Applied_Discount_Matrix_Level_'+i+'_Code__c in :matricesIds OR ';
                else
                    whereClause+='Applied_Discount_Matrix_Level_'+i+'_Code__c in :matricesIds)';
            }
            String query=QueryBuilder.build(GlobalConstants.ORDER_ITEM_SOBJECT_API_NAME,whereClause,true);
            List<OrderItem> orderItemsToUpdate=new List<OrderItem>();
            for(OrderItem oli:Database.query(query)){
                for(Integer i=2;i<12;i++){
                    if(matricesIds.contains((Id)oli.get('Applied_Discount_Matrix_Level_'+i+'_Code__c'))){
                        oli.put('Applied_Discount_Matrix_Level_'+i+'_Code__c',null);
                        oli.put('Applied_Discount_Matrix_L'+i+'_Percentage__c',0);
                        oli.put('Applied_Discount_Matrix_Level_'+i+'_Amount__c',0);  
                    }
                }
                orderItemsToUpdate.add(oli);
            }
            try{
                if(orderItemsToUpdate.size()>0)
                    Update orderItemsToUpdate;
            }
            catch(Exception ex){
                Logger.logError('DiscountMatrixTriggerHelper', 'UpdateOrderLinesIfMatrixDeactivated', '', ex);
            }
        }
    }
}