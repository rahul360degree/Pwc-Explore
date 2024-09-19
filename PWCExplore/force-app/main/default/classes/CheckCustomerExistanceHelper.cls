/*------------------------------------------------------------------------
Author:        HansRaj Yadav
Company:       PWC
Description:   Helper class for checking valid customer
Inputs:        NA
Test Class:    
---------------------------------------------------------------------------
History
12-04-2024      HansRaj Yadav     Initial Release
----------------------------------------------------------------------------*/

public class CheckCustomerExistanceHelper {
   
    public static ResponseWrapper checkCustomerIsValid( String mobileNumber ){
        ResponseWrapper response = new ResponseWrapper();
        response = searchForUniqueCustomer(mobileNumber);
        return response;
    }
    
    public static ResponseWrapper searchForUniqueCustomer(String callerNumber) {

        ResponseWrapper response = new ResponseWrapper();

        System.debug('contact number '+callerNumber);

        //Bussiness Account B2B
        List<Contact> b2bContactLst =   [   
                                            SELECT Id, LastName, AccountId,
                                            (
                                                SELECT Id, Name 
                                                FROM Assets
                                            )
                                            FROM Contact 
                                            WHERE Phone=:callerNumber OR MobilePhone =:callerNumber 
                                        ];
        
        //PersonAccounts B2C
        List<Account>  b2cCustomerLst = [  
                                            SELECT Id, PersonMobilePhone, Mobile_Number__c, Mobile_Number_of_ASP_Supervisor__c, 
                                                Primary_Contact_Mobile__c, Whatsapp_Mobile_Number__c, IsPersonAccount,
                                                    (
                                                        SELECT Id, Name, Product_Category__c
                                                        FROM Assets
                                                    )
                                            FROM Account 
                                            WHERE  PersonMobilePhone =:callerNumber
                                        ];

        //Can be alternate number
        List<ContactPointPhone> b2cContactPoint = [ SELECT Id, ParentId FROM ContactPointPhone WHERE TelephoneNumber =:callerNumber ];

        
        if( 
            (b2cContactPoint.size()==1 && b2cCustomerLst.size() == 1) 
            && b2cContactPoint[0].ParentId == b2cCustomerLst[0].Id
        ){
            System.debug('1st ');
            if( b2bContactLst.size() == 0 ){
                //
                response.mobileNumber = callerNumber;
                response.status = true;
                
                response.parentId = b2cCustomerLst[0].Id;
                //response.contactId = b2bContactLst[0].Id;
                response.customerType = 'B2C';
                response.accountId = b2cCustomerLst[0].Id;
                
                // response.parentId = b2cCustomerLst[0].Id;
                response.statusCode = 200;
                response.statusRemarks = 'Customer is valid';
                response.productCategoryAndLocation = new List<ProductCategoryAndLocation>();
                
                if( b2cCustomerLst[0].Assets != null ){

                    for( Asset asst : b2cCustomerLst[0].Assets){
                        response.productCategoryAndLocation.add( new ProductCategoryAndLocation( asst.Id, asst.Name) );
                    }
                } 

            } else {
                response.mobileNumber = callerNumber;
                response.status = false;
                response.statusCode = 200;
                response.statusRemarks = 'Customer is not valid';
            }
        
         
            
        }else if( b2bContactLst.size() == 1 && b2cContactPoint.size() == 0 && b2cCustomerLst.size() == 0){

            response.mobileNumber = callerNumber;
            response.parentId = b2bContactLst[0].Id;
            response.contactId = b2bContactLst[0].Id;
            response.customerType = 'B2B';
            response.accountId = b2bContactLst[0].AccountId;
            response.status = true;
            response.statusCode = 200;
            response.statusRemarks = 'Customer is valid';
            response.productCategoryAndLocation = new List<ProductCategoryAndLocation>();

            System.debug('size '+b2bContactLst[0].Assets);
            List<Asset> asste  = b2bContactLst[0].Assets;
            System.debug('size 2 '+asste);
            if( b2bContactLst[0].Assets != null ){

                for( Asset asst : asste){
                    response.productCategoryAndLocation.add( new ProductCategoryAndLocation( asst.Id, asst.Name) );
                }
            } 
        
        } else if( b2cCustomerLst.size() == 1 &&  b2cContactPoint.size() == 0 ){
            
            response.mobileNumber = callerNumber;
            response.status = true;
            response.parentId = b2cCustomerLst[0].Id;
            //response.contactId = b2cCustomerLst[0].Id;
            response.customerType = 'B2C';
            response.accountId = b2cCustomerLst[0].Id;
            
            response.statusCode = 200;
            response.statusRemarks = 'Customer is valid';
            response.productCategoryAndLocation = new List<ProductCategoryAndLocation>();

            System.debug('size '+b2cCustomerLst[0].Assets);
            List<Asset> asste  = b2cCustomerLst[0].Assets;
            System.debug('size 2 '+asste);
            if( b2cCustomerLst[0].Assets != null ){

                for( Asset asst : asste){
                    response.productCategoryAndLocation.add( new ProductCategoryAndLocation( asst.Id, asst.Name) );
                }
            } 
        
        } else if( b2cContactPoint.size() == 1 ){
            
            List<Account>  tempB2cCustomerLst = [  
                                                    SELECT Id, PersonMobilePhone, Mobile_Number__c, Mobile_Number_of_ASP_Supervisor__c, 
                                                        Primary_Contact_Mobile__c, Whatsapp_Mobile_Number__c, IsPersonAccount,
                                                            (
                                                                SELECT Id, Name, Product_Category__c
                                                                FROM Assets
                                                            )
                                                    FROM Account 
                                                    WHERE  PersonMobilePhone =:b2cContactPoint[0].ParentId
                                            	];
            
            
            response.mobileNumber = callerNumber;
            
            response.parentId = b2cContactPoint[0].ParentId;
            //response.parentId = b2cCustomerLst[0].Id;
            //response.contactId = b2cCustomerLst[0].Id;
            response.customerType = 'B2C';
            response.accountId = b2cContactPoint[0].Id;
            
            response.status = true;
            response.statusCode = 200;
            response.statusRemarks = 'Customer is valid';
            response.productCategoryAndLocation = new List<ProductCategoryAndLocation>();

            List<Asset> asste  = tempB2cCustomerLst[0].Assets;
            System.debug('size 2 '+asste);
            if( b2cCustomerLst[0].Assets != null ){

                for( Asset asst : asste){
                    response.productCategoryAndLocation.add( new ProductCategoryAndLocation( asst.Id, asst.Name) );
                }
            } 
            
        } else {
            response.mobileNumber = callerNumber;
            response.status = false;
            response.statusCode = 200;
            response.statusRemarks = 'Customer is not valid';
        }

        return response;

    }

    public Class ResponseWrapper {
        public Integer statusCode;
        public Boolean status;
        public String statusRemarks ;
        public String mobileNumber ;
        public String parentId;
        public String customerType;
        public String contactId;
        public String accountId;
        public List<ProductCategoryAndLocation> productCategoryAndLocation = new List<ProductCategoryAndLocation>();

    }
    
    public class ProductCategoryAndLocation {
        public String locationID; 
        public String productCategory;

        public ProductCategoryAndLocation( String locationId, String productCategory){
            this.locationID = locationId;
            this.productCategory = productCategory;
        }

    } 

    // public Class DataColletion{
    //     public Boolean status;
    //     public String statusRemarks;
    //     public String mobileNumber;
    // }

}