public class AmazonWebServiceTestThree {
    
    /*
     * "Pricebook2Id": "01s2x000005I17YAAS"
         "access_token": "00DC4000000agIT!AQEAQH0CkepF_ISqTjMXApenM7DqZOky7Fnc6UBUD3FrzYP_bscPH40MH3OvVCSmtmqGvm2oYQMpHNJXU9BwtOjlb2exeGaL",
    

// Record types
Service Request Appliance - Service Request Type - General,Install, Demo, Break Fix,Preventive Maintance 
Service Request Interio - Service Request Type - General,Install, Demo, Break Fix,Preventive Maintance
Service Request Locks - Service Request Type - General,Install, Demo, Break Fix,Preventive Maintance
Service Request SSD - Service Request Type - General,Install, Demo, Break Fix,Preventive Maintance


//GenericOrderInbound class payload

  [{
    "accountId": "001C400000CjxUrIAJ",
    "salutation": "Mr",
    "firstName": "Test",
    "lastName": "salesorder",
    "personMobilePhone": "8125829237",
    "subDivision": "B2B",
    "personEmail": "customer1@gmail.com",
    "RecordTypeId": "0122x000000QDhkAAG",
    "type": "SOT",
    "paymentTerms": "30",
    "lineOfBusiness": "01s2x000005I17YAAS",
    "Ship_To_Address__c": "a06C4000008PB3jIAG",
    "Ship_To_Account__c": "001C400000C7XMwIAN",
    "Ship_to_Area_code__c": "SX1",
    "Sold_to_Business_Partner__c": "001C400000C7XMwIAN",
    "Sold_To_Address__c": "a06C4000008PB3jIAG",
    "MHE_Division__c": "Contracts",
    "Logistics_Company_Branch__c": "5000",
    "Line_of_Business__c": "DLR",
    "Area__c": "SX1",
    "Sales_Office__c": "a0SC40000009ABRMA2",
    "Sales_Order_Series__c": "KOS",
    "Order_Currency__c": "INR",
    "Order": {
      "type": "SOT",
      "Pricebook2Id": "01s2x000005I17YAAS",
      "paymentTerms": "30",
      "effectiveDate": "2024-10-10",
      "status": "Draft",
      "shiptoAreacode": "SX1",
      "MHEDivision": "Contracts",
      "logisticsCompanyBranch": "5000",
      "lineofBusiness": "DLR",
      "area": "SX1",
      "salesOrderSeries": "KOS",
      "businessUnit": "K",
      "subDivision": "B2B",
      "orderCurrency": "INR",
      "RecordTypeId": "012C4000000ZconIAC"
    },
    "OrderItems": [
      {
        "Quantity": "1",
        "Product2Id": "01t2x000000euxVAAQ",
        "ListPrice": "89",
        "PricebookEntryId": "01u2x000000xlCUAAY",
        "UnitPrice": "50"
      },
      {
        "Quantity": "1",
        "Product2Id": "01t2x000000euxVAAQ",
        "ListPrice": "89",
        "PricebookEntryId": "01u2x000000xlCUAAY",
        "UnitPrice": "50"
      }
    ]
  }
]



// second get point json response
 

{
    "requests": {
        "222": {
            "status": "Closed",
            "lineItemId": "222-ABCDEFGHIJKL",
            "id": "222",
            "crmTicketId": "srn-222"
        },
        "111": {
            "status": "Closed",
            "lineItemId": "111-ABCDEFGHIJKL",
            "id": "111",
            "crmTicketId": "srn-111"
        }
    },
    "lineItems": {
        "222-ABCD12": {
            "orderId": "222",
            "mailingAddress": {
                "postalCode": "114599",
                "city": "Bengaluru",
                "address": "addresline2, addressline3, city - 114599, state, country"
            },
            "item": {
                "title": "Philips Viva Collection HR1831/00 Juicer, 1.5-Litre, Ink Black",
                "modelNumber": "Viva Collection HR1831/00",
                "category": "DVD",
                "brand": "Philips"
            },
            "estimatedDeliveryDate": 1625267876,
            "customer": {
                "phoneNumber": "8125819437",
                "name": "customer1",
                "email": "abc@xyz1.com"
            }
        },
        "111-ABCD12": {
            "orderId": "111",
            "mailingAddress": {
                "postalCode": "114599",
                "city": "Bengaluru",
                "address": "addresline2, addressline3, city - 114599, state, country"
            },
            "item": {
                "title": "Philips Viva Collection HR1831/00 Juicer, 1.5-Litre, Ink Black",
                "modelNumber": "Viva Collection HR1831/00",
                "category": "DVD",
                "brand": "Philips"
            },
            "estimatedDeliveryDate": 1625267876,
            "customer": {
                "phoneNumber": "8125819437",
                "name": "customer1",
                "email": "abc@xyz1.com"
            }
        }
    },
    "failedRequestIds": [
        {
            "recoverable": false,
            "failedId": "123-9998765-987654-9",
            "errorMsg": "Requested InstallationRequestId 123-9998765-987654-9 doesn't exist in tracking table for vendor vikas.jain@lge.com"
        }
    ]
}


// Hub Sample Res
[
    {
    "Salutation":"Mr",
    "customerFirstName":"Sai5",
    "customerLastName":"servicereq",
    "mobileNo" : "8125829238",
    "customerEmail":"test@gmail12.com",
    "serviceRequiredFor":"Not Working",
    "customerPinCode":"400709",
    "serviceRequestType":"Install and Demo",
    "serviceRequestChannel":"web",
    "productCategory":"REFRIGERATOR",
    "GUID":"",
    "division":"Appliance",
    "city":"hyd",
    "state":"",
    "address":"",
    "building":"",
    "serviceRequestBookedBy":"",
    "serviceRequestBookedFor":"",
    "Status":"New",
    "Adhaar":"505260604041"

}
]


*/
    
    //AmazonWebServiceTest(Post) => '{ "acknowledgements": [ { "id": "171-0003757-0903519-1" }, { "id": "171-0003757-0903519-2"}, { "id": "171-0003757-0903519-3", "crmTicketId": "srn-1502" }, { "id": "200-0003757-0903519-1", "crmTicketId": "srn-1600" } ] }';

    /*
    //HUB
    //
   <SyncSmartnetServiceRequestBookingHUB_GB>
<ApplicationArea>
<Sender>
<LogicalID>lid://infor.file.interiorental_inbound</LogicalID>
<ComponentID>erp</ComponentID>
<ConfirmationCode>OnError</ConfirmationCode>
</Sender>
<CreationDateTime>2023-06-12T12:50:09Z</CreationDateTime>
<BODID>interiorental:Infor:1000:1000:000000348#1-2023-06-12T12:50:09Z:?SmartnetServiceRequestBookingHUB_GB&amp;amp;verb=Sync</BODID>
</ApplicationArea>
<DataArea>
<Sync>
<TenantID>Infor</TenantID>
<AccountingEntityID>1000</AccountingEntityID>
<LocationID />
<ActionCriteria>
<ActionExpression actionCode="Add" />
</ActionCriteria>
</Sync>
<SmartnetServiceRequestBookingHUB_GB>
<DocumentID>
<ID>000000348#1</ID>
</DocumentID>
<CustomerMobileNo>9820509030</CustomerMobileNo>
<Division>INT</Division>
<CustomerType>NOR</CustomerType>
<Title>Mr.</Title>
<CustomerFirstName>Francina</CustomerFirstName>
<CustomerLastName>Dias</CustomerLastName>
<Email>merlin2682@gmail.com</Email>
<AlternateNo />
<AddressLine1>1/2 Shri Sai Mathura Prasad </AddressLine1>
<AddressLine2>Co-op Hsg Soc Ltd.</AddressLine2>
<AddressLine3>Mahim</AddressLine3>
<AddressLine4 />
<PinCode>400016</PinCode>
<ServiceRequiredFor>Assembly</ServiceRequiredFor>
<ServiceRequestType>Assembly Installation</ServiceRequestType>
<GodrejHUBCustomerID>624</GodrejHUBCustomerID>
<LNTransferOrderCompany>5010</LNTransferOrderCompany>
<LNTransferOrderNumber>ZNR000453</LNTransferOrderNumber>
<ItemCode1>56101515SD00122</ItemCode1>
<ItemQty1>1</ItemQty1>
</SmartnetServiceRequestBookingHUB_GB>
</DataArea>
</SyncSmartnetServiceRequestBookingHUB_GB>



Customer Details
{
Customer Type - B2B / B2C
IF B2B - BP Code
If B2C - Address Code
}
Service Request
{
Record Type -= Interio Service Request 
ServiceReq Type = Installation/Break Fix/Dismantel
	{
		Item Code = "dfadfa"
		Item Quantity 
	}
	{
		Item Code = "dfadfa"
		Item Quantity 
	}
	{
		Item Code = "dfadfa"
		Item Quantity 
	}
	{
		Item Code = "dfadfa"
		Item Quantity 
	}
}



[
    {
        "CustomerDetails": {
            "CustomerType": "B2C",
            "SubDivision": "B2C",
            "BPCode": "",
            "AddressCode": "1234",
            "Salutation": "Mr",
            "FirstName": "Sai5",
            "LastName": "servicereq",
            "PersonMobilePhone": "8125829238",
            "PersonEmail": "test@gmail12.com",
            "Adhaar": "505260604041"
        },
        "ServiceRequest": {
            "RecordType": "Hub Service Req/Interio Service Request",
            "ServiceReqFor": "REFRIGERATOR",
            "ServiceReqType": "Install and Demo",
            "Subject": "Case 1 from webservice",
            "Items": [
                {
                    "ItemCode": "dfadfa1",
                    "Name": "asset name",
                    "AreaCode": "BAN / BANGALORE",
                    "ItemQuantity": 3
                },
                {
                    "ItemCode": "dfadfa3",
                    "Name": "asset name",
                    "AreaCode": "BAN / BANGALORE",
                    "ItemQuantity": 3
                }
            ]
        }
    },
    {
        "CustomerDetails": {
            "Customer_Type": "B2B",
            "SubDivision": "B2B",
            "BPCode": "3455",
            "AddressCode": "",
            "Salutation": "Mr",
            "FirstName": "Sai5",
            "LastName": "servicereq",
            "PersonMobilePhone": "8125829238",
            "PersonEmail": "test@gmail12.com",
            "Adhaar": ""
        },
        "ServiceRequest": {
            "RecordType": "Hub Service Req/Interio Service Request",
            "ServiceReqFor": "AC",
            "ServiceReqType": "Install and Demo",
            "Subject": "Case 2 from webservice",
            "Items": [
                {
                    "ItemCode": "dfadfa1",
                    "Name": "asset name",
                    "AreaCode": "BAN / BANGALORE",
                    "ItemQuantity": 2
                },
                {
                    "ItemCode": "dfadfa2",
                    "Name": "asset name",
                    "AreaCode": "BAN / BANGALORE",
                    "ItemQuantity": 1
                }
            ]
        }
    },
    {
        "CustomerDetails": {
            "Customer_Type": "B2B",
            "SubDivision": "B2B",
            "BPCode": "3455889",
            "AddressCode": "",
            "Salutation": "Mr",
            "FirstName": "Sai5",
            "LastName": "servicereq",
            "PersonMobilePhone": "8125829238",
            "PersonEmail": "test@gmail12.com",
            "Adhaar": ""
        },
        "ServiceRequest": {
            "RecordType": "Hub Service Req/Interio Service Request",
            "ServiceReqFor": "AC",
            "ServiceReqType": "Install and Demo",
            "Subject": "Case 2 from webservice",
            "Items": [
                {
                    "ItemCode": "dfadfa1",
                    "Name": "asset name",
                    "AreaCode": "BAN / BANGALORE",
                    "ItemQuantity": 2
                },
                {
                    "ItemCode": "dfadfa2",
                    "Name": "asset name",
                    "AreaCode": "BAN / BANGALORE",
                    "ItemQuantity": 1
                }
            ]
        }
    },
    {
        "CustomerDetails": {
            "CustomerType": "B2C",
            "SubDivision": "B2C",
            "BPCode": "",
            "AddressCode": "123456",
            "Salutation": "Mr",
            "FirstName": "Sai5",
            "LastName": "servicereq",
            "PersonMobilePhone": "8125829238",
            "PersonEmail": "test@gmail12.com",
            "Adhaar": "505260604041"
        },
        "ServiceRequest": {
            "RecordType": "Hub Service Req/Interio Service Request",
            "ServiceReqFor": "REFRIGERATOR",
            "ServiceReqType": "Install and Demo",
            "Subject": "Case 1 from webservice",
            "Items": [
                {
                    "ItemCode": "dfadfa1",
                    "Name": "asset name",
                    "AreaCode": "BAN / BANGALORE",
                    "ItemQuantity": 3
                },
                {
                    "ItemCode": "dfadfa3",
                    "Name": "asset name",
                    "AreaCode": "BAN / BANGALORE",
                    "ItemQuantity": 3
                }
            ]
        }
    }
]



HUB:
	
Customer:
	
	B2B
		BP Code
		SOQL -> Account
		Map with Service Request
  		Map with Assets
		
		

	B2C
		Address code
		SOQL -> Contact Point Address
		Take out Person Account
		Map with Service Request
		Map with Assets

		
		Service Request:
			linked with Account/Person Account
			recordtype - Interio
			
		
		Assets:
			link with Account/Person Account
			SOQL -> product based on item code
			store it in Product Code Field
			Lookup
			

	After this:
		WO / WOLI
		
--------------------------------------------------------------------
Sales Order(Inbound):
	Bulk Products - Appliances
	
	SO(Order) request with Product Details(Order Products)
	Approval
	
	Payload -->  Sales Order
	Different Class - SalesOrder
	
	Item Codes:
		SOQL -> product based on item code
		store it in Product Code Field
		Lookup
====================================================================

	{
    "Customer_Type": "B2B",
    "SubDivision": "B2B",
    "BPCode": "7565",
    "AddressCode": "",
    "Salutation": "Mr",
    "FirstName": "Sai5",
    "LastName": "servicereq",
    "PersonMobilePhone": "8125829238",
    "PersonEmail": "test@gmail12.com",
    "Adhaar": "",
        "ServiceRequest": {
        "ReferenceNo": "CASE101123",
        "RecordType": "Hub Service Req/Interio Service Request",
        "ServiceReqFor": "AC",
        "ServiceReqType": "Install and Demo",
        "Subject": "Case 4:16 from webservice 10MAY",
        "Items": [
            {
                "ReferenceNo": "CASE101123",
                "ItemCode": "1",
                "Name": "case 4:16 asset 1 10MAY",
                "AreaCode": "BAN / BANGALORE",
                "ItemQuantity": 2
            },
            {
                "ReferenceNo": "CASE101123",
                "ItemCode": "10O100",
                "Name": "case 4:16 asset 2 10MAY",
                "AreaCode": "BAN / BANGALORE",
                "ItemQuantity": 1
            }
        ]
    }
}

======================================================

{
    "CustomerType": "B2C",
    "BPCode": "",
    "AddressCode": "1234",
    "Salutation": "Mr",
    "FirstName": "Sai5",
    "LastName": "servicereq",
    "PersonMobilePhone": "8125829238",
    "PersonEmail": "test@gmail12.com",
    "ServiceRequest": {
        "Division": "Hub",
        "ServiceReqFor": "REFRIGERATOR",
        "ServiceReqType": "Install and Demo",
        "Items": [
            { 
                "ItemCode": "1",
                "AreaCode": "BAN / BANGALORE",
                "ItemQuantity": 3,
                "RentalAggStartDate": "14/05/2024",
                "RentalAggEndDate": "20/02/2024"
            },
            {
                "ItemCode": "10O100",
                "AreaCode": "BAN / BANGALORE",
                "ItemQuantity": 3,
                "RentalAggStartDate": "14/05/2024",
                "RentalAggEndDate": "20/02/2024"
            }
        ]
    }
}





{
    "CustomerType": "B2C",
    "BPCode": "",
    "AddressCode": "1234",
    "Salutation": "Mr",
    "FirstName": "Sai5",
    "LastName": "servicereq",
    "PersonMobilePhone": "8125829238",
    "PersonEmail": "test@gmail12.com",
    "AddressLine1": "Shri Sai Mathura Prasad", 
    "AddressLine2": "Hsg Soc Ltd.",
    "AddressLine3": "Mahim",
    "AddressLine4": "",
    "PinCode": "400016",
    "ServiceRequest": {
     	 "Division": "Hub", 
"ServiceReqFor": "REFRIGERATOR",
        "ServiceReqType": "Install and Demo",
        "Items": [
            {
                "ItemCode": "1",
                "AreaCode": "BAN / BANGALORE",
                "ItemQuantity": 3,
                "RentalAggStartDate": "14/05/2024",
                "RentalAggEndDate": "20/05/2024"
            },
            {
                "ItemCode": "10O100",
                "AreaCode": "BAN / BANGALORE",
                "ItemQuantity": 3,
                "RentalAggStartDate": "14/05/2024",
                "RentalAggEndDate": "20/05/2024"

            }
        ]
    }
}



//24/May
{
    "CustomerType": "B2C",
    "BPCode": "",
    "AddressCode": "1234",
    "Salutation": "Mr",
    "FirstName": "Sai5",
    "LastName": "servicereq",
    "PersonMobilePhone": "8125829238",
    "PersonEmail": "test@gmail12.com",
    "AddressLine1": "Shri Sai Mathura Prasad", 
    "AddressLine2": "Hsg Soc Ltd.",
    "AddressLine3": "Mahim",
    "AddressLine4": "",
    "PinCode": "400016",
    "ServiceRequest": {
     	 "Division": "Hub", 
"ServiceReqFor": "REFRIGERATOR",
        "ServiceReqType": "Install and Demo",
        "Items": [
            {
                "ItemCode": "1",
                "AreaCode": "BAN / BANGALORE",
                "ItemQuantity": 3,
                "RentalAggStartDate": "14/05/2024",
                "RentalAggEndDate": "20/05/2024"
            },
            {
                "ItemCode": "10O100",
                "AreaCode": "BAN / BANGALORE",
                "ItemQuantity": 3,
                "RentalAggStartDate": "14/05/2024",
                "RentalAggEndDate": "20/05/2024"

            }
        ]
    }
}




    */

}