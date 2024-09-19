public class productDescriptionPopulator {
@InvocableMethod(Label='Capture product description from product2')
        Public static List<String> updateProductDescr(List<Id> Id){
        List<String> lstCommaSeparatedProductDescr = new List<String>();
        String CommaSeparatedProductDescr = '';
        
        List<OrderItem> lstSsgOrderItem = [select id,product2.Description from OrderItem where OrderId IN:Id];
        if(lstSsgOrderItem.size() > 1){//for >1 order item records to concatenate using ;
            for(OrderItem ssgOrderItem:lstSsgOrderItem){
                CommaSeparatedProductDescr  += ssgOrderItem.product2.Description+GlobalConstants.strSemiColon;	
            }
        	lstCommaSeparatedProductDescr.add(CommaSeparatedProductDescr);  
        }
        else if (lstSsgOrderItem.size() > 0){//for 1 record to not have ; at the end
            lstCommaSeparatedProductDescr.add(lstSsgOrderItem[0].product2.Description);
        }
        return lstCommaSeparatedProductDescr;
    }
    
}