public without sharing class PaymentReceiptController {
    public List<PaymentDetails> paymentDetails {get; set;}
    public OrderDetails orderDetails {get; set;}
    public String imageResource {get;set;}
    public String sAddress{get;set;}
    private List<Order> orders = new List<Order>();
    //Added by Siddhesh 21/04/2021
    public String BusinessUnit {get;set;}
    public String isInforNo {get;set;}          
    
	//added by Shreela
	 public UserDetails userDetails {get; set;}
	 public List<User> usr = new List<User>();
	 public List<Order> ord = new List<Order>();
	 public Id salesInternal{get; set;}
	 //public Id salesExternal{get; set;}
	//ended by Shreela
	
    public String ordersId{get;set;}
    public string paymentsId{get;set;} 
    
    //to get BU for current Adv payment record
    public List<Advance_Payment_Details__c> ap_bu = new List<Advance_Payment_Details__c>();
    
    private List<Address_by_BP__c > addressByBp = new List<Address_by_BP__c >();
    private List<Address__c  > customer = new List<Address__c  >();
    private List<Address__c  > storeAddress = new List<Address__c  >(); //added
    private List<Account > StoreName = new List<Account>();           //addded
    private List<ZipCode__c> zipCode = new List<ZipCode__c >();//added
    public double sum{get;set;}
    //Ended by Siddhesh 21/04/2021
    private List<Advance_Payment_Details__c> advPayments = new List<Advance_Payment_Details__c>();
    private List<Advance_Payment_Details__c> alreadyPaidList = new List<Advance_Payment_Details__c>(); //added by siddhesh for already existing payemnts
   // public double alreadyPaidAmounts{get;set;}  
     public Double already_payment_amount_orders; public double TestVariable = 0.00 ;
    private final String cardPaymentTypes = 'CARD, GIFT CARD';
    private final String chequePaymentTypes = 'CHEQUE, DD, RTGS, PAY BY LINK, UPI, EMI';
    // Added by Shankar Sahu 3-11-2020 for rally defect DE1163
    public List<OrderItem> orderItems {get; set;}
    
    public PaymentReceiptController() {
        userDetails = new UserDetails();  //added by Shreela
        orderDetails = new OrderDetails();
        sAddress='';
        paymentDetails = new List<PaymentDetails>();
        Id orderId = Apexpages.currentpage().getparameters().get('orderId');
        // Added by Shankar Sahu 3-11-2020 for rally defect DE1163
        orderItems = [SELECT Id, UnitPrice, Quantity, Product2.Name,Order.Status
                      FROM OrderItem
                      WHERE OrderId = :orderId];

        Id paymentId = Apexpages.currentpage().getparameters().get('paymentId')!=null ? Apexpages.currentpage().getparameters().get('paymentId') : null;
        paymentReceiptHandler(orderId, paymentId);
		
				  
		userDetailsHandler(orderId); //added by Shreela	   
		

           //added by siddhesh
           ap_bu = [SELECT Business_Unit__c,Name FROM Advance_Payment_Details__c WHERE Id =: paymentId LIMIT 1];
        if(ap_bu.size()>0)
        BusinessUnit = ap_bu[0].Business_Unit__c;
        SYstem.System.debug('Business Unit : '+BusinessUnit);
   
           //ended by siddhesh
    }
    
	//added by Shreela
	//Handler function
	public void userDetailsHandler(Id orderId){
        Id odrId = orderId;
      	ord = [SELECT Id,Internal_Sales_Representative__c
                      FROM Order
                      WHERE Id =:odrId];
		for(Order orderDet : ord ){
               salesInternal = orderDet.Internal_Sales_Representative__c;
			   //salesExternal = ord.External_Sales_Representative__c;
         }	
         		 
	  createUserDetailsDataStructure(salesInternal); 
	}
	//ended by Shreela
	
    // Handler function that does various processing.
    private void paymentReceiptHandler(Id orderId, Id paymentId) {
        getOrderAndRelatedAdvPaymentData(orderId, paymentId);
        createOrderAndPaymentDataStructure();
        String resourceName = getImageResourceNameFromRecordType();
        imageResource = getResourceURL(resourceName);
    }
    
    // Function to get Order and it's child Advance Payment records.
    private void getOrderAndRelatedAdvPaymentData(Id orderId, Id paymentId) {
        //If you have paymentId specified then you have to generate pdf for that advance payment record only.
        //Getting user 
        User oUser=[select Id,Account__c,AccountId,City,Street,State,PostalCode from User where Id=:Userinfo.getUserId()];

     

        String sAccId=null;
        if(oUser.AccountId!=null)
          sAccId=oUser.AccountId;
        else if(oUser.Account__c!=NULL)
         sAccId=oUser.Account__c;  
        if(sAccId!=null){
            Account addVar=new Account();
            addVar=[select Id,Primary_Address__r.CityName__c,Primary_Address__r.Street__c,Primary_Address__r.StateName__c,
                                 Primary_Address__r.ZipCode__c,Primary_Address__r.ZipCode__r.Name from Account where Id=:sAccId];

            if(addVar.Primary_Address__r.Street__c!=null)
              sAddress+=addVar.Primary_Address__r.Street__c+',';
            if(addVar.Primary_Address__r.CityName__c!=null)
              sAddress+=addVar.Primary_Address__r.CityName__c+',';  
            if(addVar.Primary_Address__r.StateName__c!=null)
              sAddress+=addVar.Primary_Address__r.StateName__c+',';  
            if(addVar.Primary_Address__r.ZipCode__c!=null)
              sAddress+=addVar.Primary_Address__r.ZipCode__r.Name;     
        }
        else{
           if(oUser.Street!=null)
              sAddress+=oUser.Street+',';
            if(oUser.City!=null)
              sAddress+=oUser.City+',';  
            if(oUser.State!=null)
              sAddress+=oUser.State+',';  
            if(oUser.PostalCode!=null)
              sAddress+=oUser.PostalCode;     
        }
        if(paymentId != null) {
            orders = [Select Id,OrderReferenceNumber,Ship_To_Account__c, OrderNumber,Total_Advance_Amount__c, Order_Amount__c, RecordTypeId, Account.Name,Sold_To_Address__c,Account.ShippingStreet,
                  Account.ShippingCity, Account.ShippingState,Total_Due_Amount__c,
                  //added by Shreela 
				  External_Sales_Representative__r.name,Internal_Sales_Representative__r.name,
				  //ended by Shreela
                  (Select Id, Name,Already_Received_Payment__c, Amount__c, Reference_Number__c,Payment_Date__c, Payment_Mode__c, Credit_Card_Last_four_digits__c,
                     Bank_Provider_Name__c,
                     Balance_Payment__c, Subsidy_Amount__c, Exchange_Amount__c, Order__r.Is_Exchange_order__c, Order__r.Total_Unit_Price__c,
                     //added by Shankar Sahu Loan_Amount__c
                     Loan_Amount__c,Order__r.Order_Amount__c,Mode_of_Advance_Payment__c, Delivery_Order_Number__c, EMI_Count__c, EMI_Amount__c, Down_Payment__c, Processing_Fees__c,
                     EMI_Scheme__c, EMI_Vendor__c, Bank_Reference__c
                     from Child_AdvancePaymentDetails__r Where Id = :paymentId) 
                     from Order Where Id = :orderId LIMIT 1];

        } else {
        // Else generate PDF for the order by fetching all the related advance payment records.
            orders = [Select Id,OrderReferenceNumber,Ship_To_Account__c,Total_Advance_Amount__c, OrderNumber,Order_Amount__c, RecordTypeId, Account.Name,Sold_To_Address__c, Account.ShippingStreet,
                  Account.ShippingCity, Account.ShippingState,Total_Due_Amount__c,
                  //added by Shreela 
			      External_Sales_Representative__r.name,Internal_Sales_Representative__r.name,
				  //ended by Shreela
                     (Select Id, Name,Already_Received_Payment__c, Amount__c, Payment_Date__c,Mode_of_Advance_Payment__c ,Reference_Number__c, Payment_Mode__c, Credit_Card_Last_four_digits__c,
                     Bank_Provider_Name__c,
                     Balance_Payment__c, Subsidy_Amount__c, Exchange_Amount__c, Order__r.Is_Exchange_order__c, Order__r.Total_Unit_Price__c,					 
                     //added by Shankar Sahu Loan_Amount__c
                     Loan_Amount__c,Order__r.Order_Amount__c, Delivery_Order_Number__c, EMI_Count__c, EMI_Amount__c, Down_Payment__c, Processing_Fees__c,
                     EMI_Scheme__c, EMI_Vendor__c, Bank_Reference__c
                     from Child_AdvancePaymentDetails__r ORDER BY CreatedDate ASC) 
                     from Order Where Id = :orderId LIMIT 1];
        }
        addressByBp = [SELECT Address_Code__c  FROM Address_by_BP__c Where Id = :orders[0].Sold_To_Address__c LIMIT 1];
        if(addressByBp.size()>0)
        customer  = [SELECT Name__c  FROM Address__c Where Id = :addressByBp[0].Address_Code__c LIMIT 1];
        StoreName = [Select Primary_Address__c,Name,Business_Unit__c from Account where id = : orders[0].Ship_To_Account__c LIMIT 1];
        if(StoreName.size()>0) 
        storeAddress = [Select Street__c,CityName__c,StateName__c,ZipCode__c from Address__c where id = :StoreName[0].Primary_Address__c LIMIT 1];
        if(storeAddress.size()>0)
        zipCode = [Select Name from ZipCode__c where id = :storeAddress[0].ZipCode__c LIMIT 1];
        alreadyPaidList = [Select Amount__c,Name,Order__c,Already_Received_Payment__c FROM Advance_Payment_Details__c WHERE Order__c =: orders[0].Id AND Id =: paymentId  LIMIT 1];
        if(alreadyPaidList.size()>0) 
        already_payment_amount_orders = alreadyPaidList[0].Already_Received_Payment__c;
       
    }
    
    // Create datastructures for Order and Payment records.
    private void createOrderAndPaymentDataStructure() {
        createOrderDetailsDataStructure();
        createPaymentDetailsDataStructure();
        convertTotalAmountInWords();
		
    }
    
	 //added by Shreela
	private void createUserDetailsDataStructure(Id salesInternal) {
	 usr = [SELECT Name,Email,MobilePhone
	        FROM User 
			WHERE Id =: salesInternal];
     for(User user: usr){
         userDetails.Mobile = user.MobilePhone;
	     userDetails.EmailId = user.Email;
     }	 	
	}
	 //ended by Shreela
	 
	 
    // Create data structure for OrderDetails
    private void createOrderDetailsDataStructure() {
        for(Order order : orders) {
            // Create Order Info DS
            if(customer.size()>0)
            orderDetails.customerName = customer[0].Name__c;
            SYstem.System.debug('Business Unit for Store Address: '+BusinessUnit);
            //  if(BusinessUnit == 'H')
            if(StoreName.size()>0)
                { if(StoreName[0].Business_Unit__c == 'H'){
                orderDetails.storeAddress = String.valueOf(order.Account.ShippingStreet + ', ' + order.Account.ShippingCity + ', ' + order.Account.ShippingState);
                orderDetails.storeAddress=sAddress;
                    }
                    
                     else if(StoreName[0].Business_Unit__c == 'W')
                    {
                        SYstem.System.debug('Business Unit inside IF '+BusinessUnit);
                        orderDetails.storeAddress= StoreName[0].Name + ', ' +storeAddress[0].Street__c+ ', ' +storeAddress[0].CityName__c+ ', ' +storeAddress[0].StateName__c + ', ' +zipCode[0].Name;
                     }
                }
            else 
            // if(BusinessUnit == 'W')
                if(StoreName.size()>0){
            if(StoreName[0].Business_Unit__c == 'W')
                    {
                        SYstem.System.debug('Business Unit inside IF '+BusinessUnit);
                        orderDetails.storeAddress= StoreName[0].Name + ', ' +storeAddress[0].Street__c+ ', ' +storeAddress[0].CityName__c+ ', ' +storeAddress[0].StateName__c + ', ' +zipCode[0].Name;
                     }
                 }
            orderDetails.orderName = order.OrderNumber;

            //added by siddhesh
            orderDetails.productPrice = order.Order_Amount__c;
            orderDetails.totalAdvAmount = order.Total_Advance_Amount__c;
			//ended by Siddhesh
			
			//added by Shreela
			orderDetails.internalRep = order.Internal_Sales_Representative__r.name;
			orderDetails.externalRep = order.External_Sales_Representative__r.name;
			//ended by Shreela
        }
    }
    
    // Create data structure for PaymentDetails
    private void createPaymentDetailsDataStructure() {
        orderDetails.totalAmount = 0;
        for(Order order : orders) {
            // Create payment related DS
            Integer i = 1;
            for(Advance_Payment_Details__c advancePaymentDetail : order.Child_AdvancePaymentDetails__r) {
                PaymentDetails paymentDetail = new PaymentDetails();
                paymentDetail.paymentRec = advancePaymentDetail;
                paymentDetail.columnNo = i;
                isInforNo = order.OrderReferenceNumber;

                 if(order.OrderReferenceNumber == null){
                    paymentDetail.systemOrderNo = order.OrderNumber;
                 }
                 else
                 {
                    paymentDetail.systemOrderNo = order.OrderNumber + ' / '+order.OrderReferenceNumber;
                 }
                paymentDetail.billNo = advancePaymentDetail.Name;
                paymentDetail.documentNo = advancePaymentDetail.Name;
                paymentDetail.amount = advancePaymentDetail.Amount__c;
                paymentDetail.paymentReceivedDate = advancePaymentDetail.Payment_Date__c;
                paymentDetail.AlreadyPaid = advancePaymentDetail.Already_Received_Payment__c;   //added by siddhesh yesterday for testing
                
                if(BusinessUnit == 'W'){
                //if(StoreName[0].Business_Unit__c == 'W'){
                    System.debug('Already Paid List Line 211 :' + alreadyPaidList[0].Amount__c);
                //if(alreadyPaidList[0].Amount__c == null)
                if(advancePaymentDetail.Already_Received_Payment__c == 0)
                {
                  paymentDetail.AlreadyPaid = 0.00;
                  orderDetails.ExistingPaidValue = 0.00;
                
                }
                else{
                    //added for summing
                     paymentDetail.AlreadyPaid = already_payment_amount_orders ;     //already_payment_amount_orders;
                     OrderDetails.ExistingPaidValue = already_payment_amount_orders;
                }
            }
 

               //Added by Shankar Sahu 3-11-2020
                paymentDetail.TotalDueAmount=order.Total_Due_Amount__c;
                
                // Get the name of bank and payment mode and store it in order
                orderDetails.totalAmount += advancePaymentDetail.Amount__c;
                orderDetails.bank = advancePaymentDetail.Bank_Provider_Name__c;
                orderDetails.receiptNumber=advancePaymentDetail.Name;
                orderDetails.refNumber=advancePaymentDetail.Reference_Number__c;
                orderDetails.paymentMode = identifyPaymentMode(advancePaymentDetail.Mode_of_Advance_Payment__c);
                orderDetails.paymentModeActual=advancePaymentDetail.Mode_of_Advance_Payment__c;
                orderDetails.earliestPaymentDate = identifyEarliestPaymentDate(orderDetails.earliestPaymentDate, advancePaymentDetail.Payment_Date__c);
                orderDetails.creditCardNo = 'XXXX-XXXX-XXXX-'+advancePaymentDetail.Credit_Card_Last_four_digits__c;
                orderDetails.bankBranch = advancePaymentDetail.Bank_Reference__c;
                paymentDetails.add(paymentDetail);
                i+=1;
            }
        }
    }
    
    // Function to convert total amount to words.
    private void convertTotalAmountInWords() {
        orderDetails.totalAmountInWords = (new NumberToWord()).getNumberToWordConvertion(orderDetails.totalAmount);
    }
    
    // Identify the payment mode.
    private String identifyPaymentMode(String paymentMode) {
        if(cardPaymentTypes.containsIgnoreCase(paymentMode.toUpperCase())) {
            return 'Credit Card';
        } else if(chequePaymentTypes.containsIgnoreCase(paymentMode.toUpperCase())) {
            return 'Cheque';       
        }
        return 'Cash';
    }
    
    // Function to identify the earliest payment date if an order has multiple advance payments.
    private Date identifyEarliestPaymentDate(Date sourceDate, Date targetDate) {
        if(sourceDate < targetDate) {
            return sourceDate;
        }
        return targetDate;
    }
    
    // Get the name of the logo based on record type name.
    private String getImageResourceNameFromRecordType() {
        String imageResource = 'godrej_interio';
        RecordType recordTypeObj = [Select Id, Name, SobjectType, DeveloperName FROM RecordType 
                                    Where SobjectType = 'Order' AND Id = :orders[0].RecordTypeId];
        orderDetails.recordtype= recordTypeObj.DeveloperName;
        System.debug('Testing for Developer :'+recordTypeObj.DeveloperName);
        if(recordTypeObj.DeveloperName.contains('SCRIPT')){
                imageResource = 'godrej_script';
            }
          else if(recordTypeObj.DeveloperName.contains('Appliance')) {
                imageResource = 'godrej_appliance'; }
            else {
                imageResource = 'godrej_interio';
            }
        return imageResource;
    }
    
    // Function to get the image resource url.
    private String getResourceURL(String resourceName) {
        String zipFileStaticResourceName = 'Godrej_Images';
        //Fetching the resource
        List<StaticResource> resourceList = [SELECT Name, NamespacePrefix, SystemModStamp FROM StaticResource WHERE Name = :zipFileStaticResourceName LIMIT 1];
                            
        //Checking if the result is returned or not
        if(resourceList.size() == 1) {
           //Getting namespace
           String namespace = resourceList[0].NamespacePrefix;
           //Resource URL
           return '/resource/' + resourceList[0].SystemModStamp.getTime() + '/' + (namespace != null && namespace != '' ? namespace + '__' : '') + zipFileStaticResourceName + '/' + resourceName + '.png'; 
        }
        else return '';
    }
    
    // Inner class to maintain order related info.
    public class OrderDetails {
        public String orderName {get; set;}
        public String customerName {get; set;}
        public String bank {get; set;}
        public string receiptNumber{get;set;}
        public string refNumber{get;set;} 
        public String paymentMode {get; set;}
        public String paymentModeActual {get; set;}
        public double totalAmount {get; set;}
        public String creditCardNo {get; set;}
        public String totalAmountInWords {get; set;}
        public String storeAddress {get; set;}
        public Date earliestPaymentDate {get; set;}
        public string recordtype{get;set;}
    
        public double ExistingPaidValue{get;set;}
        public double productPrice{get;set;}
        public String BusinessUnitAccount{get;set;}
        public double totalAdvAmount{get;set;}
        public String bankBranch {get;set;}
		
		public String internalRep {get;set;}
		public String externalRep {get;set;}
    }
    
    // Inner class to maintain advance payment related info.
    public class PaymentDetails {
        public Integer columnNo {get; set;}
        public String systemOrderNo {get; set;}
        public String billNo {get; set;}
        public String documentNo {get; set;}
        public double amount {get; set;}
        public Date paymentReceivedDate {get; set;}
        //Added by Shankar Sahu 3-11-2020
        public double TotalDueAmount {get; set;}
        public double AlreadyPaid {get;set;} 
        public Advance_Payment_Details__c paymentRec {get; set;}
    }
	
	//added by Shreela
	//Inner class to maintain user related info.
	public class UserDetails {
	    public String EmailId {get; set;}
		public String Mobile {get; set;}
	}
    
    
	//ended by Shreela


}