/*------------------------------------------------------------------------
Author:        Mrunali Chuadhari
Company:       Salesforce
Description:   Handler class for paymetTerm Trigger
test class :   PaymentTermsProcessorTest
History
23/01/2022     Mrunali      Initial Release
----------------------------------------------------------------------------*/
public class paymentTermHelper {
    public static void paymentTermError(list<Payment_Term__c> paymTRecords) {   
        String Area ;
        String Zone ;
        String OrderSeries ;
        String SalesServiceOffice ;
        String Channel ;
        String ItemGroup ;
        String ItemCode ;
        String ItemType ;
        String Productline ;
        String ProductClassnew ;
        String PriceList ; 
        string Status ;
        List<Payment_Term__c> pymtList;
        for(Payment_Term__c pymT : paymTRecords) {
            Area = pymT.Area_Code__c ;
            Zone = pymT.Zone__c ;
            OrderSeries = pymT.Order_Series__c ;
            SalesServiceOffice = pymT.Sales_Service_Office__c ;
            Channel = pymT.Channel__c ;
            ItemGroup = pymT.Item_Group__c ;
            ItemCode = pymT.Item_Code__c ;
            ItemType = pymT.Item_Type__c ;
            Productline = pymT.Product_line__c ;
            ProductClassnew = pymT.Product_Class_new__c ;
            PriceList = pymT.Price_List__c ;
            Status = pymT.Status__c ;
            
           pymtList = [Select id from Payment_Term__c where Area_Code__c =: Area AND Zone__c =:Zone AND Order_Series__c =:OrderSeries AND Sales_Service_Office__c =:SalesServiceOffice AND Channel__c =:Channel AND Item_Group__c =:ItemGroup AND Item_Code__c =: ItemCode AND Item_Type__c =:ItemType AND Product_line__c =:Productline AND Product_Class_new__c =:ProductClassnew AND Price_List__c =:PriceList AND Status__c =:Status ];

            if(Area != null && Zone != null && OrderSeries != null && SalesServiceOffice != null && Channel != null && ItemGroup != null && ItemCode != null && ItemType != null && Productline != null && ProductClassnew != null && PriceList != null && Status != null){
                if(pymtList.size() > 0)
                    pymT.addError(GlobalConstants.DUPLICATE_RECORD_FOUND);
            }
            else if(Area == null || Zone == null || OrderSeries == null || SalesServiceOffice == null || Channel == null || ItemGroup != null || ItemCode != null || ItemType != null || Productline != null || ProductClassnew != null || PriceList != null && Status != null){
                if(pymtList.size() > 0)
                    pymT.addError(GlobalConstants.DUPLICATE_RECORD_FOUND);
            }
        }           
    } 
}