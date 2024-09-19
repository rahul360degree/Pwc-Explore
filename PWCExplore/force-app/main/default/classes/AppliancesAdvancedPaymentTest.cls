@isTest
public class AppliancesAdvancedPaymentTest {
    @TestSetup static void createData(){        
            Profile userProfile = [Select Id from Profile where Name =: GlobalConstants.SYSTEM_ADMIN_PROFILE_NAME LIMIT 1];
            // Create User record.
            User userToRun = new User(EmailEncodingKey = 'UTF-8', firstName = 'Testing', lastname = 'AppUser', Alias = 'tuser',
                                languagelocalekey = 'en_US', localesidkey = 'en_US', profileid = userProfile.id,
                                timezonesidkey = 'Asia/Kolkata', email = 'test.AppuserAcc@godrej.com', username = 'test.AppuserAcc@godrej.com', Business_Unit__c = 'H');
    
            userToRun.IsActive = true;
            userToRun.Allow_Business_Account_Creation__c = true;
            userToRun.Logistic_Company__c = '2000';
            userToRun.Area_Code__c = 'WN1';
            insert userToRun;
        
        	System.runAs(userToRun){

                //Create Account
                /*Account newAccount = new Account();
                newAccount.Name = 'Testing Appaccount';
                newAccount.Business_Unit__c = 'H';
                newAccount.Account_Series__c = '00H';
                newAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId();
                insert newAccount;*/
                
                Address_Code_reserved_char__c rChar = new Address_Code_reserved_char__c();
                rChar.B2C_character__c = 'A';
                rChar.B2B_Account_Series_Char__c = 'X';
                rChar.B2B_character__c = 'AA';
                insert rChar;
                Account accountRecord = new Account(Name='Testing Appaccount', Business_Unit__c = 'H' );
                accountRecord.RecordTypeId = (RecordTypeUtils.getInstance()).getRecordTypeId('Account', 'Business_Account');
                insert accountRecord;
            
                //Create Order
                Order newOrder = new Order();
                newOrder.AccountId = accountRecord.id;
                newOrder.Name = 'Testing AppOrder';
                newOrder.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Appliance_Primary').getRecordTypeId();
                newOrder.Logistics_Company_Branch__c = '3010';                  
                newOrder.Line_of_Business__c = '3PL';                               
                newOrder.Business_Unit__c = 'H';
                newOrder.Order_Amount__c = 500 ;
                insert newOrder;
            
                //Create Advance Payment 
                Advance_Payment_Details__c newAdvDetail = new Advance_Payment_Details__c();
                newAdvDetail.Order__c = newOrder.id;

				 newAdvDetail.Reference_Number__c = '1234'; //disscuss
            newAdvDetail.Bank_Provider_Name__c = 'EzeTap Requested';//disscuss
            newAdvDetail.Mode_of_Advance_Payment__c = 'Cash';
            newAdvDetail.Bank_Name__c = newAdvDetail.Bank_Provider_Name__c;
            newAdvDetail.Credit_Card_Last_four_digits__c = '1234';//disscuss
            newAdvDetail.Credit_Debit_Card_Approval_Code__c = 'NA';//disscuss
            newAdvDetail.Transaction_Type__c = '328';
            newAdvDetail.Currency__c = 'INR';
            newAdvDetail.Transaction_Entry_Date__c = Date.today();
            newAdvDetail.Instrument_date__c = newAdvDetail.Transaction_Entry_Date__c;
        	newAdvDetail.Payment_Date__c = Date.today();
            newAdvDetail.Type_of_Transaction__c = 'Advance Receipt';
                newAdvDetail.Amount__c = 890;
                newAdvDetail.Payment_Mode__c = 'Others';
                
                insert newAdvDetail;
			
                
        	}
        	
       }
    @isTest private static void getAdvancedPaymentTest(){
        User testuser = [Select Id,LastName From User where username = 'test.AppuserAcc@godrej.com' Limit 1];
        
        System.runAs(testuser){
            Test.startTest();
            	
            
                Order orderRec = [select id from Order where Name = 'Testing AppOrder' Limit 1];
            	Double getadvpayment = AppliancesAdvancedPayment.getAdvancedPayment(orderRec.Id);
                
            	Advance_Payment_Details__c advpaymentdetail = [select id from Advance_Payment_Details__c where Order__c =: orderRec.id Limit 1];
            	boolean updateadvpayment = AppliancesAdvancedPayment.updateAdvancedPayment(advpaymentdetail);
            
            	String currentadvpaymet = AppliancesAdvancedPayment.getCurrentAdvancedPayment(advpaymentdetail.id);
            
            	String getphnumber = AppliancesAdvancedPayment.getPhoneNumber(orderRec.id);
            
            	String calloutType = 'createQR';
                String refNumber = '1234';
                String jsonPart = 'jsonPart'; 
            	String expiryTime = '5';
        		String json= '{"success": true,  "sessionKey": "0409d123-e149-41f8-9dd3-46930f1c2271",  "username": "3939000118", "setting": {"offeringEmiCashback": "YES", "customerNameEntryEnabled": false, "emailReceiptEnabled": true, "dukptMultiTidEnabled": false, "catalogEnabled": false, "deviceTimeout": "1", "twoFactorAuthenticationEnabled": true, "clientBaseURL": "DEFAULT", "cashBackEnabled": false, "cnpEnabled": false, "p2pEnabled": true, "notificationCentreLimit": "60", "upiEnabledInCNP": true, "settingVer": 1702040147000, "tipEnabled": false, "remotePaymentEnabled": true, "smsReceiptEnabledForDD": false, "supportPhoneNumber": "1800212212212", "orderNumberLabel": " ",  "automaticSMSPaymentLinkEnabled": true, "merchantBusinessHoursEnd": "12",  "smsReceiptEnabledForBharatQR": true, "eSignatureForNonCardEnabled": false, "signatureForCard": "ACQUIRER_BASED", "upiEnabled": true, "customWebFlowEnabled": false, "aggregatePaymentModesEnabled": false,  "paymentPromotionEnabled": false, "userAppOptions": {   "preferences": {  "language": {  "value": "English"        }      }    },    "devicePairingRequiredForNonCardPaymentModes": false,    "addlAuthReqdForCash": false,    "customConfigCode": "EZETAP",    "minCashBackAmount": "100",    "omsSettings": {      "omsEnabled": false,      "catalogEnabled": null,      "catalogType": null,      "maxOrderItems": 20,      "dataWindow": 45,      "orderListMaxRecords": null,      "fieldsToIndex": null    },    "tipAdjustmentEnabled": false,    "maxBTAttempts": "1",    "emiEnabled": true,    "preFillUsernameOnSessionTimeOut": true,    "saleOption": "1",    "prepaidVoucherPaymentEnabled": false,    "smsReceiptEnabled": true,    "allowAmountOverride": false,    "preAuthOption": "-1",    "notificationEnabled": false,    "brandEmiEnabled": false,    "merchantAddress": "Mumbai||Mumbai|Maharashtra||IN",    "maxCashBackAmount": "2000",    "smsReceiptEnabledForUpi": true,    "zestRegistrationSmsEnabled": false,    "pogSettings": "null",    "communicationRoute": "FCM",    "orderNumberInputEnabled": true,    "printMerchantCopy": false,    "passRegex": "^[a-zA-Z0-9_]*$",    "smsReceiptEnabledForUpiBqrRefundPending": true,    "notificationForcedTimeGap": "30",    "configFlowEnabled": false,    "tipPercentage": "15",    "collectMobileEmailUpfront": false,    "barcodeScanningEnabled": false,    "autoLoginByTokenEnabled": false,    "firmwareCheckInterval": "7200",    "eSignatureForWalletEnabled": true,    "automaticEmailPaymentLinkEnabled": true,    "smsReceiptEnabledForCheque": false,    "cashPaymentEnabled": true,    "sessionTimeOutForReversal": "28800",    "pogEnabled": false,    "cardPaymentEnabled": true,    "sodexoEnabled": false,    "minTxnAmount": "1",    "crateBasedSearchEnabled": false,    "emiEnabledForClient": false,    "refundEnabled": false,    "chequePaymentBankNames": [      {        "code": "ABN_AMRO",        "codeDescription": "ABN AMRO Bank"      },      {        "code": "ALLAHABAD_BANK",        "codeDescription": "Allahabad Bank"      },      {        "code": "ANDHRA_BANK",        "codeDescription": "Andhra Bank"      },      {        "code": "AXIS_BANK",        "codeDescription": "Axis Bank"      },      {        "code": "BANK_OF_BAHRAIN_AND_KUWAIT",        "codeDescription": "Bank of Bahrain and Kuwait"      },      {        "code": "BANK_OF_BARODA",        "codeDescription": "Bank of Baroda"      },      {        "code": "BANK_OF_INDIA",        "codeDescription": "Bank of India"      },      {        "code": "BANK_OF_KARNATAKA",        "codeDescription": "Bank of Karnataka"      },      {        "code": "BANK_OF_MAHARASHTRA",        "codeDescription": "Bank of Maharashtra"      },      {        "code": "CANARA_BANK",        "codeDescription": "Canara Bank"      },      {        "code": "CENTRAL_BANK_OF_INDIA",        "codeDescription": "Central Bank of India"      },      {        "code": "CITIBANK",        "codeDescription": "Citibank"      },      {        "code": "CITY_UNION_BANK_LTD",        "codeDescription": "City Union Bank Ltd"      },      {        "code": "CORPORATION_BANK",        "codeDescription": "Corporation Bank"      },      {        "code": "DCB_DEVELOPMENT_CREDIT_BANK",        "codeDescription": "DCB Development Credit Bank"      },      {        "code": "DENA_BANK",        "codeDescription": "Dena Bank"      },      {        "code": "HDFC_BANK",        "codeDescription": "HDFC Bank"      },      {        "code": "HSBC_BANK",        "codeDescription": "HSBC Bank"      },      {        "code": "ICICI_BANK",        "codeDescription": "ICICI Bank"      },      {        "code": "IDBI_BANK",        "codeDescription": "IDBI Bank"      },      {        "code": "INDIAN_BANK",        "codeDescription": "Indian Bank"      },      {        "code": "INDIAN_OVERSEAS_BANK",        "codeDescription": "Indian Overseas Bank"      },      {        "code": "INDUSIND_BANK",        "codeDescription": "IndusInd Bank"      },      {        "code": "ING_VYSYA_BANK_LTD",        "codeDescription": "ING Vysya Bank Ltd"      },      {        "code": "KARNATAKA_BANK",        "codeDescription": "Karnataka Bank"      },      {        "code": "KOTAK_MAHINDRA_BANK",        "codeDescription": "Kotak Mahindra Bank"      },      {        "code": "LAKSHMI_VILAS_BANK",        "codeDescription": "Lakshmi Vilas Bank"      },      {        "code": "MERCANTILE_BANK",        "codeDescription": "Mercantile Bank"      },      {        "code": "ORIENTAL_BANK_OF_COMMERCE",        "codeDescription": "Oriental Bank of Commerce"      },      {        "code": "PUNJAB_NATIONAL_BANK",        "codeDescription": "Punjab National Bank"      },      {        "code": "RATNAKAR_BANK_LTD",        "codeDescription": "Ratnakar Bank Ltd"      },      {        "code": "SOUTH_INDIAN_BANK",        "codeDescription": "South Indian Bank"      },      {        "code": "STANDARD_CHARTERED_BANK",        "codeDescription": "Standard Chartered Bank"      },      {        "code": "STATE_BANK_OF_BIKANER_JAIPUR",        "codeDescription": "State Bank of Bikaner and Jaipur"      },      {        "code": "STATE_BANK_OF_HYDERABAD",        "codeDescription": "State Bank of Hyderabad"      },      {        "code": "STATE_BANK_OF_INDIA",        "codeDescription": "State Bank of India"      },      {        "code": "STATE_BANK_OF_MYSORE",        "codeDescription": "State Bank of Mysore"      },      {        "code": "STATE_BANK_OF_PATIALA",        "codeDescription": "State Bank of Patiala"      },      {        "code": "STATE_BANK_OF_SAURASHTRA",        "codeDescription": "State Bank of Saurashtra"      },      {        "code": "STATE_BANK_OF_TAMIL_NADU",        "codeDescription": "State Bank of Tamil Nadu"      },      {        "code": "SYNDICATE_BANK",        "codeDescription": "Syndicate Bank"      },      {        "code": "THE_ANDHRA_PRADESH_STATE_CO_OP_BANK_LTD",        "codeDescription": "The Andhra Pradesh State Co Operative Bank Ltd"      },      {        "code": "THE_KARUR_VYSYA_BANK_PVT_LTD",        "codeDescription": "The Karur Vysya Bank Pvt Ltd"      },      {        "code": "UCO_BANK",        "codeDescription": "UCO Bank"      },      {        "code": "UNION_BANK_OF_INDIA",        "codeDescription": "Union Bank of India"      },      {        "code": "UNITED_BANK_OF_INDIA",        "codeDescription": "United Bank of India"      },      {        "code": "UNIT_TRUST_OF_INDIA",        "codeDescription": "Unit Trust of India"      },      {        "code": "VIJAYA_BANK",        "codeDescription": "Vijaya Bank"      },      {        "code": "YES_BANK",        "codeDescription": "Yes Bank"      },      {        "code": "OTHER",        "codeDescription": "Other"      }    ],    "minCheckStatusAttempts": "2",    "cardLastFourDigitsRequired": false,    "maxTxnAmount": "9999999999",    "paperReceiptEnabled": false,    "zeroValueTransactionAllowed": false,    "cashBackOption": "-1",    "offlineAPIEnabled": false,    "walletRefundEnabled": true,    "biEventEmail": "info@ezetap.com",    "smsReceiptEnabledForCnp": true,    "btReceiptEnabled": false,    "autoSyncOfflineEnabled": false,    "merchantBusinessHoursStart": "6",    "smsReceiptEnabledForWallet": true,    "autoSyncOfflineInterval": "180",    "smsReceiptEnabledForCash": true,    "rmpayWalletEnabled": false,    "chequePaymentEnabled": true,    "eSignatureEnabled": false,    "passRegexErrorDisplay": "Password shoud be Alphanumeric and length should be atleast 7 character"  },  "apps": [],  "enableRki": false,  "amount": "700",  "amountOriginal": "700",  "authCode": "831000",  "cardLastFourDigit": "1091",  "currencyCode": "INR",  "customerMobile": "9650540902",  "customerReceiptUrl": "http://d.eze.cc/r/o/RTqzIgfT/",  "externalRefNumber": "EZ202312140904455899",  "formattedPan": "4000-00XX-XXXX-1091",  "txnId": "231214090952989E010038533",  "merchantName": "Godrej-SFDC",  "mid": "",  "nonceStatus": "OPEN",  "orgCode": "GODREJSFDC_12400",  "merchantCode": "GODREJSFDC_12400",  "payerName": "SS",  "paymentCardBin": "400000",  "paymentCardBrand": "VISA",  "paymentCardType": "DEBIT",  "paymentMode": "CNP",  "postingDate": "1702564793000",  "processCode": "_DEF_PROC",  "rrNumber": "7025450020146837504012",  "settlementStatus": "SETTLED",  "status": "AUTHORIZED",  "states": [    "SETTLED"  ],  "tid": "",  "txnType": "REMOTE_PAY",  "dccOpted": false,  "cardHolderCurrencyExponent": "0",  "userAgreement": "",  "signable": false,  "voidable": false,  "refundable": true,  "chargeSlipDate": "2023-12-14T14:39:53+0530",  "readableChargeSlipDate": "14/12/2023 14:39:53",  "issuerCode": "HDFC",  "maximumPayAttemptsAllowed": "1",  "maximumSuccessfulPaymentAllowed": 1,  "noExpiryFlag": false,  "settlementTime": "1702564803000",  "receiptUrl": "http://d.eze.cc/r/o/RTqzIgfT/",  "signReqd": false,  "txnTypeDesc": "Remote payment",  "paymentGateway": "CYBERSOURCE",  "acquirerCode": "HDFC",  "createdTime": "1702564793000",  "customerNameAvailable": true,  "callbackEnabled": false,  "onlineRefundable": false,  "cardClassification": "ANY",  "shiftNo": "0",  "orderNumber": "EZ202312140904455899",  "reverseReferenceNumber": "7025450020146837504012",  "totalAmount": "700",  "displayPAN": "1091",  "nameOnCard": "SS",  "cardType": "VISA",  "tipEnabled": false,  "callTC": false,  "acquisitionId": "",  "acquisitionKey": "",  "processCronOutput": false,  "externalDevice": false,  "tipAdjusted": false,  "txnMetadata": [],  "middlewareStanNumber": "0",  "otpRequired": false,  "abstractPaymentStatus": "SUCCESS",  "twoStepConfirmPreAuth": false,  "reload": false,  "redirect": false}';
            
				Test.setMock(HttpCalloutMock.class, new EzetapMockFocResponse()); 
            	//AppliancesAdvancedPayment appliancesAdvancedPayment = new AppliancesAdvancedPayment(calloutType, refNumber, jsonPart);
				String backendstatushkjob = AppliancesAdvancedPayment.backendStatusCheckJob(calloutType, refNumber, jsonPart,expiryTime);
            	//EzeTapResponseParser.ParseResult parseResult = EzeTapResponseParser.parse(json);
            	EzeTapResponseParser parsedResult = EzeTapResponseParser.parse(json);
            
        		/*advpaymentdetail.Payment_Error_Message__c = 'Error msg';
            	advpaymentdetail.Payment_Error_Code__c = '67878';
            	advpaymentdetail.Payment_Message__c = 'Payment successful';
                update advpaymentdetail;  */
            	//AppliancesAdvancedPayment.execute()
               // AppliancesAdvancedPayment.execute(refNumber);
                    
            Test.stopTest();
        }
        
    }
    /*@isTest private static void updateAdvancedPaymentTest(){
         User testuserdup = [Select Id,LastName From User where username = 'test.AppuserAcc@godrej.com' Limit 1];
        System.runAs(testuserdup){
            Test.startTest();
            Order orderRecc = [select id from Order where Name = 'Testing AppOrder' Limit 1];
            //Advance_Payment_Details__c advpaymentdetail = [select id from Advance_Payment_Details__c where Order__c = orderRecc.id Limit 1 ];//where Order__c = orderRecc.id
            /*Advance_Payment_Details__c newAdvDetail = new Advance_Payment_Details__c();
                newAdvDetail.Order__c = orderRecc.id;
                newAdvDetail.Type_of_Transaction__c = 'Advance Receipt';
                newAdvDetail.Transaction_Type__c = '328';
                newAdvDetail.Amount__c = 890;
                newAdvDetail.Mode_of_Advance_Payment__c = 'Cash';
                insert newAdvDetail;
              //Double paymentresult = AppliancesAdvancedPayment.updateAdvancedPayment(advpaymentdetail.Id);
            	newAdvDetail.Amount__c = 700;
            boolean result = AppliancesAdvancedPayment.updateAdvancedPayment(newAdvDetail);
            //update advpaymentdetail;
            
            System.assertEquals(true,result);
            
            Test.stopTest();
            
        }
    }
    @isTest
    static void GetCurrentAdvancedPaymenttest() {
        User testuserdup = [Select Id,LastName From User where username = 'test.AppuserAcc@godrej.com' Limit 1];
        System.runAs(testuserdup){
            Test.startTest();
            Order orderduprec = [select id from Order where Name = 'Testing AppOrder' Limit 1];
            Advance_Payment_Details__c newAdvDetail = new Advance_Payment_Details__c();
                    newAdvDetail.Order__c = orderduprec.id;
                    newAdvDetail.Type_of_Transaction__c = 'Advance Receipt';
                    newAdvDetail.Transaction_Type__c = '328';
                    newAdvDetail.Amount__c = 890;
                    newAdvDetail.Mode_of_Advance_Payment__c = 'Cash';
                    insert newAdvDetail;
            String getcurrentadvpayment = AppliancesAdvancedPayment.getCurrentAdvancedPayment(newAdvDetail.Id);
            Test.stopTest();
        }
    }
    @isTest
    static void GetPhoneNumbertest() {
        User testuserdupp = [Select Id,LastName From User where username = 'test.AppuserAcc@godrej.com' Limit 1];
        System.runAs(testuserdupp){

            Test.startTest();
            Order testorderRec = [select id from Order where Name = 'Testing AppOrder' Limit 1];
            
            String phoneNumber = AppliancesAdvancedPayment.getPhoneNumber(testorderRec.Id);
            Test.stopTest();
        }
    }*/
      
}