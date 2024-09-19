/*------------------------------------------------------------------------
Author:        Sai Kumar
Company:       PWC
Description:   Generic wrapper class for all REST APIs
Inputs:        NA
Test Class:    
History
28/03/2024      Sai Kumar     Initial Release
----------------------------------------------------------------------------*/
Global with sharing class RequestJSONWrapper {
    
    global class CustomerRequestWrapper{
        //public list<cls_data> data;
        public string firstname;
        public string lastname;
        public string Salutation;
        public string address;
        public string email;
        public string phone;
        public string name;
    }
    public class B2CCustomerRequestJSONWrapper {
    public string firstname;
    public string lastname;
    public string Salutation;
    public string address;
    public string Email;
    public string phone;
    public string name;
    public string city;
    public string postalcode;
    public string state;
    public string country;
    public string GUID;
    public string SubDivision;
}
        global class B2BCustomerRequestBody {
        public String Name { get; set; }
        public String ParentAccountCode { get; set; }
        public String AccountSeries { get; set; }
        public String AccountCode { get; set; }
        public String PrimaryAddress { get; set; }
        public String Language { get; set; }
        public String CustomerCurrency { get; set; }
        public String PAN { get; set; }
        public String CIN { get; set; }
        public String Phone { get; set; }
        public String BusinessPartnerStatus { get; set; }
        public Date StartDate { get; set; }
        public String SubDivision { get; set; }
        public String BusinessUnit { get; set; }
    }
    global class ServiceRequestWrapper{
        //public list<cls_data> data;
       // public string customerLastName;
       // public string customerFirstName;
       // public string Salutation;
       // public string customerPinCode;
        public string customerEmail;
        public string mobileNo;
        public string serviceRequiredFor;
        public string serviceRequestType;
        public string serviceRequestChannel;
        public string productCategory;
        public string GUID;
        public string division;
        public string Adhaar;
        public string city;
        public string state;
        public string address;
        public string building;
        public string serviceRequestBookedBy;
        public string serviceRequestBookedFor;
        public string Status;
        
        public string LNTransferOrderCompany;
        public string LNTransferOrderNumber;
    }
    public class ResponseWrapper{
        public boolean status;
        public string message;
        public string GUID;
       public string MSOLineitemID;
        
    }

}