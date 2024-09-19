/*------------------------------------------------------------------------
Author:        Kishor Kumar
Company:       Salesforce
Description:   Class to contains all the Constants value to reduce hardcoding
Inputs:        NA
Test Class:   

History
20-03-2020      Kishor Kumar     Initial Release
----------------------------------------------------------------------------*/
public with sharing class GlobalConstants {
    
    /*Record Type Names*/
    public static final String ACCOUNT_RECORDTYPE_DEALER = 'Dealer';
    public static final String ACCOUNT_RECORDTYPE_RETAILER = 'Retailer';
    public static final String ACCOUNT_RECORDTYPE_INFLUENCER = 'Influencer';
    public static final String DEALER_VISIT_RECORDTYPE_INTERIO_B2C = 'Interio B2C';
    public static final String DEALER_VISIT_RECORDTYPE_APPLIANCES = 'Appliances';
    public static final String CASE_RECORDTYPE_MHE_SERIVCE_REQUEST = 'MHE_Service_Request'; 
    public static final String CASE_RECORDTYPE_SERIVCE_REQUEST = 'Service_Request'; // added y Sai Kumar Eluvaka on 22-04-2024 
    public static final String QUOTE_RECORDTYPE_MHE_EQUIPMENTS = 'MHE Equipments';
    public static final String QUOTE_RECORDTYPE_MHE_PARTS = 'MHE Parts';
    public static final String QUOTE_RECORDTYPE_MHE_CONTRACTS = 'MHE Contracts';
    public static final String QUOTE_RECORDTYPE_MHE_RENTALS = 'Godrej RenTRUST';
    public static final String QUOTE_RECORDTYPE_INTERIO_B2C_VFD='Interio_B2C_VFD';
    public static final String QUOTE_RECORDTYPE_INTERIO_KITCHEN='Interio_Kitchen';
    public static final String QUOTE_RECORDTYPE_INTERIO_SCRIPT='Interio_Script';
    public static final String QUOTE_RECORDTYPE_APPLIANCE='Appliances'; //Added by Namrata and Shreela on 24th August 2022 for SAEPB - 44 Appliance B2B
    public static final String RECORDTYPE_Locks_B2B ='Locks_B2B';
    public static final String RECORDTYPE_Construction_B2B ='Construction_Materials';
    public static final String OPPORTUNITY_RECORDTYPE_MHE = 'MHE';
    public static final String QUOTE_RECORDTYPE_SSG = 'SSG';
    public static final String CLAIM_REQUEST_CONTRACTS = 'Contracts';
    public static final String CLAIM_REQUEST_INVOICE_SUBMISSION_REQUEST = 'Invoice_Submission_Request';
    public static final String CLAIM_REQUEST_WARRANTY = 'Warranty';
    public static final String CLAIM_REQUEST_RECORDTYPE_CREDIT_NOTE = 'Credit_Note';
    public static final String CLAIM_REQUEST_RECORDTYPE_ADHOC = 'Ad_hoc';
    public static final String CLAIM_REQUEST_RECORDTYPE_SCC = 'SCC';
    public static final String CLAIM_REQUEST_RECORDTYPE_CLAIM_REQUEST = 'Claim_Request';
    public static final String RECEIVABLE_TARGET='Target';
    public static final String RECEIVABLE_RECORDTYPE='Receivable';
    public static final String RECEIVABLE_ACTUAL='Actual';
    public static final String RECEIVABLE_INVOICE='Invoice';
    public static final String CASE_RECORDTYPE_SSG_SERIVCE_REQUEST = 'SSG_Service_Request';
    public static final String CASE_RECORDTYPE_MHE_RENTAL_SERIVCE_REQUEST = 'Godrej_RenTRUST';
    public static final String ASSET_RECORDTYPE_MHE_RENTAL_SERIVCE_REQUEST = 'Godrej_RenTRUST';
    public static final String QUOTE_RECORDTYPE_MHE_RENTAL = 'MHE_Rental';
    public static final String TASK_RECORDTYPE_Interio_B2C_LDM = 'Interio_B2C_LDM';//Added by Ashwin for SFMC On 13-02-2024 
    public static final String TASK_SOBJECT_TYPE = 'Task';//Added by Ashwin for SFMC On 13-02-2024 
    Public static final String PM_Handover_RECORDTYPE_SSG = 'Final_Commissioning_and_Handover';//Added by pankaj on 24 Oct 2021 for milestonewiseDueDateCalculation
    //profile names
    public static final String SYSTEM_ADMIN_PROFILE_NAME='System Administrator';
    public static final String INTEGRATION_ADMINISTRATOR_PROFILE_NAME='Integration Administrator';
    public static final String ApplianceDoorToDoorUserSyncProfile = 'Appliances Door to Door Sales exec Partner Sync User'; // Added by Alpana on 21st Sept 22 for Jira #SAEPB-42[SAF-133]
    public static final String MHE_CSG_HEAD_USER_PROFILE_NAME = 'MHE CSG Head User'; //Added by Alpana on 3rd Oct 2022 for Jira #SMEPB-46[SMF-83]
    public static final String MHE_SALES_USER_PROFILE_NAME = 'MHE Sales User'; //Added by Alpana on 3rd Oct 2022 for Jira #SMEPB-46[SMF-83]
    public static final String MHE_SALES_KAM_FUNCTIONAL_USER_PROFILE_NAME = 'MHE Sales KAM Functional Head User'; //Added by Alpana on 3rd Oct 2022 for Jira #SMEPB-46[SMF-83]
    public static final String MHE_DEALER_SALES_MANAGER_PARTNER_USER_PROFILE_NAME = 'MHE Dealer Sales Manager Partner User';//Added by Namrata on 16th jan 2023 for Jira SMEPB-59[SMF-86-II]
    public static final String MHE_DEALER_SALES_REP_PARTNER_USER_PROFILE_NAME = 'MHE Dealer Sales Rep Partner User';//Added by Namrata on 16th jan 2023 for Jira SMEPB-59[SMF-86-II]
    public static final String interCallCenterProfile = 'Interio B2C Call Center User';
    //integration user SF ID- added on 31-March-2022 to bypass checks for Integration User
    public static final String INTEGRATION_USER_SF_ID ='0052x000002YHRwAAO';
    
    
    /*Lead Record Types*/
    public static final String LEAD_RECORDTYPE_OTHER_BU='Other_BU';
    public static final String LEAD_RECORDTYPE_Interio_B2C='Interio_B2C_Lead';

    // Product Component Types
    public static final String BASE_PRODUCT_COMPONENT_TYPE = 'Base Product';
    public static final String ATTACHMENT_PRODUCT_COMPONENT_TYPE = 'Attachments';
    public static final String VARIANT_PRODUCT_COMPONENT_TYPE = 'Variants';
    public static final String MANPOWER_COMMON = 'Supervisor;Technician';
    public static final String EQUIPMENT_ROLL_UP_VARIANTS = 'Mast;Tyre;Battery';
    
    // Construction Product Type -Added by Anupam Mishra
    public static final String TUFF_Duroplast_Landed_Rate = 'TUFF_Duroplast_Landed_Rate';
    public static final String TUFF_Easy_Fix_Landed_Rate = 'TUFF_Easy_Fix_Landed_Rate';
    public static final String Broken_Blocks = 'Broken_Blocks';
    public static final String TUFF_ACC_Block_Landed_Rate = 'TUFF_ACC_Block_Landed_Rate';
    public static final String TUFF_TILE_FIX_PREMIUM_20_KG = 'TUFF_TILE_FIX_PREMIUM_20_KG';             //Added by poonam (SCF- 102)
    public static final String TUFF_TILEFIX_PREMIUM_40_KG = 'TUFF_TILEFIX_PREMIUM_40_KG';
    public static final String TUFF_TILEFIX_SUPREME_20_KG = 'TUFF_TILEFIX_SUPREME_20_KG';
    public static final String TUFF_TILEFIX_SUPREME_40_KG = 'TUFF_TILEFIX_SUPREME_40_KG';
    public static final String TUFF_TILEFIX_SUPREME_PLUS_20_KG = 'TUFF_TILEFIX_SUPREME_PLUS_20_KG';
    public static final String TUFF_TILEFIX_SUPREME_PLUS_40_KG = 'TUFF_TILEFIX_SUPREME_PLUS_40_KG';

    //Quote Record Type API Names
    public static final String QUOTE_MHE_CONTRACTS_RECORDTYPE_APINAME = 'MHE_Contracts';
    public static final String QUOTE_MHE_RENTALS_RECORDTYPE_APINAME = 'MHE_Rental';
    
    // Quote key for Interio Kitchen 
    public static final String QUOTE_INTERIO_KITCHEN_QUOTEKEY = 'Interio_Kitchen-Secondary';
    
    //Opportunity Record Type API Names
    public static final String OPPORTUNITY_MHE_RENTALS_RECORDTYPE_APINAME = 'MHE_Rental';
    public static final String OPPORTUNITY_INTERIO_B2C_APPLIANCES_APINAME = 'Interio_B2C_Appliances';
    public static final String OPPORTUNITY_FACILITY_BOOKING_RECORDTYPE = 'Facility_Booking';
    public static final String OPPORTUNITY_Interio_B2B_RECORDTYPE = 'Interio_B2B';

    // Type Of Equipment
    public static final String QUOTE_TYPE_OF_EQUIPMENT_NEW = 'NEW EQUIPMENT';

    // Service Contract Record types
    public static final String SERVICECONTRACT_RECORDTYPE_NAME = 'Contract';

    // Sales Office Record types
    public static final String SERVICE_OFFICE_RECORDTYPE_NAME = 'Service_Office';

    // Characters For Business Code
    public static final String Character_X= 'X';
    public static final String Character_Y = 'Y';
    
    //MHE Divisions
    public static final String BUSINESS_UNIT_MHE_DIVISION = 'K'; 
    public static final String MHE_DIVISION_EQUIPMENT_CONTAINS = 'OUTRIGHT SALES';
    
    //price orign
    public static final String PRICE_ORIGIN_MANUAL='manual';
    public static final String PRICE_ORIGIN_EXTERNAL='extern';
    
    /*order Record Type API Names*/
    public static final String INTERIO_VFD_SECONDARY='Interio_VFD_Secondary';
    public static final String INTERIO_B2C_VFD_PRIMARY='Interio_B2C_VFD_Primary';
    public static final String INTERIO_B2C_KITCHEN='Interio_B2C_Kitchen';
    public static final String INTERIO_B2C_SCRIPT='Interio_B2C_SCRIPT';
    public static final String APPLIANCE_PRIMARY='Appliance_Primary';
    public static final String APPLIANCE_SECONDARY = 'Appliance_Secondary';
    public static final String SSG_PRIMARY = 'SSG_Primary';
    public static final String MHE_PRIMARY = 'MHE_Order_Primary';
    public static final String MHE_SECONDARY = 'MHE_Order_Secondary';
    public static final String FINISHED_GOODS_PRIMARY = 'Interio_B2B_Finished_Goods_Primary';
    public static final String APPLIANCE_TERTIARY = 'Appliance_Tertiary';
    public static final String INTERIO_BMR = 'Interio_BMR';
    //Added for Appliances Direct Billing Order
    public static final String APPLIANCE_DIRECT_BILLING ='Direct_Billing_Order_Appliances';
    
    public static final string ACCOUNTOBJAPINAME = 'Account';
    public static final string DealerAccountRt = ACCOUNT_RECORDTYPE_DEALER;
    public static final string CustomerAccountRt = 'Customer'; 
    public static final string BUSINESS_ACCOUNT_RT ='Business_Account';
    public static final String QUOTE_SOBJECT_API_NAME = 'Quote';
    public static final String ORDER_SOBJECT_API_NAME = 'Order';
    public static final String USER_SOBJECT_API_NAME = 'User';
    public static final String BRANCH_SOBJECT_API_NAME = 'Branch__c';
    public static final String ORDER_ITEM_SOBJECT_API_NAME = 'OrderItem';
    public static final String QUOTE_LINE_ITEM_SOBJECT_API_NAME = 'QuoteLineItem';
    public static final String OPPORTUNITY_SOBJECT_API_NAME = 'Opportunity';
    public static final String CONTACT_SOBJECT_API_NAME = 'Contact';
    public static final String CASE_SOBJECT_API_NAME = 'Case';
    public static final String ATTENDANCE_SOBJECT_API_NAME = 'Attendance__c';
    public static final String ORDER_DEFAULT_STATUS = 'Draft';
    public static final Date ORDER_DEFAULT_STARTDATE = Date.today(); 
    public static final String ORDER_MAPPING_METADATA = 'SObject_To_Order_Mapping__mdt';
    public static final String ORDER_LINE_ITEM_MAPPING_METADATA = 'QuoteLine_To_OrderLine_Mapping__mdt';
    public static final String ACCOUNT_ORDER_MAPPING_METADATA = 'Account_to_Order_Mapping__mdt';
    public static final String QUOTE_ORDER_MAPPING_UNIQUE_FIELD = 'Id';
    public static final Map<String,String> TRANSACTION_TYPE = new Map<String,String>{
                                                                'Primary'=>'Primary',
                                                                'Secondary'=>'Secondary'
                                                            };
    public static final Map<String,String> TRANSACTION_TYPE_INTERIO_B2B = new Map<String,String>{
                                                                System.label.Interio_B2B_Parimary =>'Primary',
                                                                System.label.Interio_B2B_Secondary =>'Secondary'
                                                            };

    public static final String ALL_TRANSACTION_TYPE = 'All';
    public static final String QUOTE_STATUS_FINALIZED = 'Finalized';
    public static final String CUSTOMER_QUOTE_TYPE = 'Customer Facing';
    
    /*Order Type(Transaction_Type__c on Order) API Names*/
    public static final String ORDER_TYPE_SECONDARY = 'Secondary';
    public static final String ORDER_TYPE_PRIMARY = 'Primary';
    public static final String ACTIVE='Active'; //Renamed DISCOUNT_MATRIX_ACTIVE_STAGE to ACTIVE By Ankush
    /* discount matrix stages*/
    public static final String DISCOUNT_MATRIX_INACTIVE_STAGE='Inactive';
    
    /* order sales type values*/
    public static final String SALES_TYPE_PRIMARY='Primary';
    public static final String SALES_TYPE_SECONDARY='Secondary';
    
    /*Order Interation status synced*/
    public static final String INTEGRATION_STATUS_SYNCED = 'Synced';
    public static final String INTEGRATION_STATUS_DRAFT = 'Draft';
    public static final String INTEGRATION_STATUS_READY_TO_SYNC = 'Ready to Sync';
    public static final String INTEGRATION_STATUS_SYNC_FAILED = 'Sync Failed';
    public static final String INTEGRATION_STATUS_CAPTURED = 'Captured';
    public static final String INTEGRATION_STATUS_BLOCKED = 'Blocked';
    public static final String INTEGRATION_STATUS_NOT_SYNCED = 'Not Synced';
    
    /*Quote Line Item Approval Status */
    public static final String APPROVAL_NOT_REQUIRED_STATUS = 'Approval Not Required';
    public static final String APPROVAL_REQUIRED_STATUS = 'Approval Required';
    public static final String APPROVED_STATUS = 'Approved';
    public static final String STATUS_Resubmitted = 'Resubmitted';
    
    //Logging Types
    public Enum LOG_TYPE {ERROR, DEBUG, INFO}

    public static final string Submitted_for_Approval = 'Submitted for Approval';
    public static final string APPROVED = 'Approved';
    public static final string Rejected = 'Rejected'; 
    public static final string Approval_Required = 'Approval Required';
    public static final string Approval_Not_Required = 'Approval Not Required';
    public static final string kitchenRecordTypeName='Interio_Kitchen'; 
    public static final string DRAFT = 'Draft';
    public static final String POSTED_TO_FINANCE='Posted to Finance';
    public static final string CANCELLED = 'Cancelled';

    
    //Use this parameter to avoid trigger recursive execution 
    public static Boolean EXECUTE_METHOD = true;  
    public static Boolean ALLOW_TRIGGER_TO_EXECUTE = true; 
    public static Boolean SKIP_QUOTE_LOCK=false; // Added by rohit jadhav to skip quote record lock for Interio_B2B_Finished_Good
    public static Boolean SKIP_Recursion=false; //Added by Shreela for SMEPB 111 on 21st Dec 2023
            
    public static final string RECORD_LOCK_ERROR_MSG = 'Record submitted for Approval. This record is locked from editing';
 
    public static final string DUPLICATE_RECORD_FOUND = 'Duplicate record Found'; //Added by Mrunali chaudhari on 23/01/2023
    
    public static final Map<String,String> ACCOUNT_TYPE_VS_RT = new Map<String,String>{
                                                                'D'=>'Dealer',
                                                                'F'=>'Dealer',
                                                                '1'=>'Vendor'
                                                            };

    public static final string LEAD_ASSIGNMENT_DEFAULT_QUEUE='Default_Queue';
    public static final string LEAD_SOURCE_FACEBOOK_INSTAGRAM='Facebook/ Instagram'; //Added by Srini on 25th April 2023
    public static final string LEAD_SOURCE_GODREJ_WEBSITE='Godrej Website'; //Added by Srini on 25th April 2023    
    public static final string LEAD_SOURCE_INDIAMART = 'IndiaMart' ; //Added by Alpana on 8th Feb 2024 for SMF-182
    public static final string LEAD_SOURCE_SEM = 'SEM- Search Engine Marketing' ; //Added by Alpana on 8th Feb 2024 for SMF-182    
    //Dealer Visit Status (Dealer Visit Object) Api Names
    public static final string DEALER_VISIT_STATUS_COMPLETE = 'Completed';
    
    //CONTRACT TYPE api names
    public static final string CONTRACT_TYPE_PLATINUM = 'Platinum';
    public static final string CONTRACT_TYPE_TITANIUM = 'Titanium';
    
     //Service Contract Types
    public static final string AMC_CONTRACT_TYPE = 'AMC';
    public static final string CMC_CONTRACT_TYPE = 'CMC';
    public static final string CMT_CONTRACT_TYPE = 'CMT';
    public static final string CMP_CONTRACT_TYPE = 'CMP';
    public static final string CMD_CONTRACT_TYPE = 'CMD';
    public static final string CMG_CONTRACT_TYPE = 'CMG';
    public static final string PMC_CONTRACT_TYPE = 'PMC';
    public static final string EWP_CONTRACT_TYPE = 'EWP';

    //MHE Division type api names
    public static final string MHE_DIVISION_CONTRACTS = 'Contracts';
    public static final string Opp_StageName_Inquiry = 'Inquiry';
    public static final string Competitor1_None = 'None';
    
    //Business Units api Names
    // Business unit for Locks is added by Anupam on 21-01-2022
    // Business unit for Construction is added by Anupam on 21-01-2022
    public static final string INTERIO_BUSINESS_UNIT='W'; 
    public static final string APPLIANCE_BUSINESS_UNIT = 'H';
    public static final string SSG_BUSINESS_UNIT = 'G';
    public static final string MHE_BUSINESS_UNIT = 'K';
    public static final string Locks_BUSINESS_UNIT = 'L';
    public static final string Construction_BUSINESS_UNIT = 'N';
    public static final string INTERIO_BMR_BUSINESS_UNIT = 'B';
    public static final string PES_BUSINESS_UNIT = 'Q'; //Added by Shreela on 6th March 2023 
     
    //Sub Division API Names
    public static final string B2B_SUBDIVISION = 'B2B'; //Added by Shreela on 22nd September 2022  for SAEPB - 44 Appliance B2B
    public static final string B2C_SUBDIVISION = 'B2C';
    public static final string Franchisee = 'F';
    public static final string ChannelFranchisee = 'FRA';
    public static final string ChannelKitchen = 'KIT';
    public static final string ChannelCocoStores = 'COC'; //Added by Alpana for SIF-76 on 29th September 2022
    public static final string ChannelDealer = 'COC'; 
    //Interio Sub Division API Names
    public static final string B2B_INTERIO_SUBDIVISION = 'B2B';
    public static final string INTERIO_SCRIPT='Scripts';
    public static final String INTERIO_VFD='VFD';
    public static final String INTERIO_KITCHEN='Kitchen';
    
    //Batch class Names
    public static final string LEAD_ASSIGNER_BATCH_CLASS = 'AssignLeadsBatch';
    public static final string CASE_GENERATOR_BATCH_CLASS = 'AssignContractLineItemsBatch';
    public static final string ASSET_BENEFIT_PURGER_BATCH_CLASS = 'UnusedAssetBenefitPurgerBatch';
    
    //Roles Used in PJP Creation
    public static final List<String> PJP_CREATION_ROLES = new List<String>{'TSI Area Manager', 'Visual Merchandiser', 'Channel Expansion', 'Zonal head', 'RSO', 'ASM'};
        
    //QLI Metadata field type Vs Field
        public static final Map<String, Boolean> FIELDTYPE_VS_ELIGIBILITY = new Map<String, Boolean>{
            'checkbox' => false,
            'boolean'  => false,
            'text' => false,
            'decimal' => true,
            'integer' => true
        };
    
    //Quote record type use for Approval
    public static final set<String> QUOTE_RT_FOR_APPROVAL = new set<String>{'Appliances','Interio_B2C_VFD','Interio_Script', 'SSG', 
                                                    'Interio_Kitchen','Interio_B2B_APO','Interio_B2B_Finished_Good',
                                                      'MHE_Equipments', 'MHE_Parts', 'MHE_Contracts', 'MHE_Rental','Locks_B2C_ISTD'}; //Added Appliances by Shreela on 7th September 2022  for SAEPB - 44 Appliance B2B
          
    public static final String DIRECT_BILLING_TO_CUSTOMER = 'Direct billing to customer';
    public static final String DIRECT_BILLING_TO_CUSTOMER_WITH_ORC_TO_DEALER = 'Direct billing to customer (With ORC to Dealer)';
    public static final String DIRECT_BILLING_TO_CUSTOMER_R_SERIES = 'Direct billing to customer (R series)';
    public static final String DIRECT_BILLING_TO_DEALER_PRIMARY_WITH_SCHEME = 'Direct Billing To Dealer(primary with scheme)';
    public static final String BILLING_TO_DEALER_WITH_ADDITIONAL_DISCOUNT = 'Billing to dealer (With additional discount )';
    public static final String DIRECT_BILLING_TO_DEALER_WITH_NO_DISCOUNT = 'Direct Billing to dealer(With No Discount)';
    public static final String DIRECT_BILLING_ORDER_APPLIANCES = 'Direct Billing Order Appliances';
    public static final String DIRECT_BILLING_TO_CUSTOMER_W_SERIES = 'Direct Billing To Customer (W Series)';
    
    public static final Integer OLI_SEQUENCE_FIRST_NUMBER = 10;
    public static final String MHE_SUB_DIVISION_EQUIPMENT = 'Outright Sales';
    public static final String MHE_SUB_DIVISION_CONTRACT = 'Contracts';
    public static final String MHE_SUB_DIVISION_RENTAL = 'Godrej RenTRUST';
    public static final String MHE_SUB_DIVISION_PARTS = 'Spare Parts';
    public static final String MHE_DIVISION_CODE = 'K';
    public static final String COMPONENT_TYPE_BASE_PRODUCT = 'Base Product';
    public static final String COMPONENT_TYPE_ATTACHMENTS = 'Attachments';
    public static final String COMPONENT_TYPE_ACCESSORIES = 'Accessories';
    public static final String QUOTE_RECORDTYPE_DEV_NAME_MHE_EQUIPMENTS = 'MHE_Equipments';
    public static final String QUOTE_RECORDTYPE_DEV_NAME_MHE_PARTS = 'MHE_Parts';
    public static final String QUOTE_RECORDTYPE_DEV_NAME_MHE_CONTRACTS = 'MHE_Contracts';
    public static final String QUOTE_RECORDTYPE_DEV_NAME_MHE_RENTAL = 'MHE_Rental';
    
    
    
    public static final String MHE_MARKETING_MANAGER_PERSONA = 'MHE Sales-Marketing Manager';
    public static final String MHE_LOB_HEAD_PERSONA = 'MHE Sales-LOB / KAM Head';
    public static final String MHE_SALES_MANAGER_PERSONA = 'MHE Sales-Sales Manager';
    public static final String MHE_SALES_ENGINEER_PERSONA = 'MHE Sales-Sales Engineer (Common / ADJ / Hirer);MHE Sales-KAM';
    public static final String MHE_LOB_HEAD_PERSONA2 = 'MHE SOSer-LOB / KAM Head';
    public static final String MHE_MARKETING_MANAGER_PERSONA2 = 'MHE SOSer-Marketing Manager (Product Manager)';
    public static final String MHE_FUNCTIONAL_HEAD_PERSONA = 'MHE Sales-Functional Head';
    public static final String MHE_FUNCTIONAL_HEAD_PERSONA2 = 'MHE SOSer-Functional Head';
    public static final String MHE_SALES_ENGINEER_PERSONA2 = 'MHE Sales-Sales Engineer (Common / ADJ / Hirer)';
    public static final String MHE_CSG_HEAD_PERSONA = 'MHE SOSer-CSG - Head'; //Added MHE_SALES_ENGINEER_PERSONA2 and CSG_HEAD_PERSONA by Shreela on 12th May 2022
    public static final String APPL_REG_MANAGER_PERSONA = 'Appliances- Regional Service Manager - D2D';
    public static final String APPL_DSM_PERSONA = 'Appliances- Direct Sales Manager (DSM)';
    public static final String APPL_HO_PERSONA = 'Appliances- HO (Head Office)-D2D'; //Added APPL_REG_MANAGER_PERSONA,APPL_DSM_PERSONA and APPL_HO_PERSONA by Shreela on 16th Sept 2022 for SAEPB - 44 Appliance B2B
    public static final String Interio_VP_PERSONA = 'Vice President';
    public static final String Interio_BH_PERSONA = 'Business Head';
    public static final String Interio_HO_PERSONA = 'Head Officer';
    public static final String Interio_RM_PERSONA = 'Regional Manager';
    public static final String Interio_ZH_PERSONA = 'Zonal Head';
    // Channel Names
    public static final String D2D_CHANNEL = 'D2D';
	
    public static final String APPLIANCES_CLUSTER_HEAD_DIRECT_SALES = 'Appliances- Cluster Head direct sales';
    public static final String APPLIANCES_DIRECT_SALESMANAGER_PERSONA = 'Appliances- Direct Sales Manager (DSM)';
    public static final String APPLIANCES_TRADE_MANAGERS_SERVICE_REV_PERSONA = 'Appliances- Trade Managers (Service Revenue)';
    public static final String APPLIANCES_SPARE_PART_DEALERS_PERSONA = 'Appliances- Spare part dealers';
    public static final List<String> APPLIANCES_PERSONAS_APPROVAL_REQUIRED = new List<String>{ 'Appliances- Cluster Head direct sales', 'Appliances- Direct Sales Manager (DSM)',
                                                                                               'Appliances- Spare part dealers'};
    public static final List<String> APPLIANCES_PERSONAS_NO_APPROVAL_REQUIRED = new List<String>{'Appliances- Regional Service Manager - D2D', 'Appliances- HO (Head Office)-D2D', 'Appliances- Area Sales Manager',
                                                                                                 'Appliances- RBH (Regional Branch Head)', 'Appliances- ZBH (Zonal Branch Head)', 'Appliances- HO (Head Office)-Sales',
                                                                                                 'Appliances- Service Revenue Manager', 'Appliances- Regional Service Manager', 'Appliances- HO (Head Office) - Service Revenue',
                                                                                                 'Appliances- Trade Managers (Service Revenue)'};
                                                                                                     
                                                                                                     
    //Account Series Constants
    public static final String PARENT_ACCOUNT_SERIES_FIRST_2_CHARACTER = '9P';
    
    public static final String OLI_SOBJECT_API_NAME = 'OpportunityLineItem';
    
    public static final Map<String, String> OPPORTUNITY_TYPE_TO_ORDER_TYPE_MAPPING = new Map<String, String>{
        'GFA' => 'NOG'
    };
        
    //opportunity stage name
    public static final String OPPORTUNITY_STAGE_OFFER = 'Offer';
    public static final String OPPORTUNITY_STAGE_NEGOTIATION= 'Negotiation/Review';
    
    public static final String ADDRESSTYPE_B2C = 'B2C';
    
    //interio B2C sub division
    public static final Set<String> interioB2CSubDivisions=new Set<String>{
        'Scripts',
        'Kitchen',
        'VFD'
    };
    
    //Default Batch Size
    public static final Integer DEFAULT_BATCH_SIZE = 100;   
    public static final String CASE_ASSIGNMENT_DEFAULT_QUEUE = 'Default_Queue_MHE_Cases';
    public static final String G_B_BUSINESS_HOURS = 'G&B Business Hours';
    public static final String CASE_INTERIO_B2C_RECORD_TYPE_DEV_NAME = 'Interio_B2C';
    public static final String CASE_MHE_RECORD_TYPE_DEV_NAME = 'MHE_Service_Request';
    public static final String CALENDAR_EVENT_TYPE = 'Calendar';

    //BU Division
    public static final String MHE_BU_DIVISION = 'MHE';
    
    //Service Request type (Case)
    public static final String SERVICE_REQUEST_TYPE_REPAIR = 'Repair';
    public static final String SERVICE_REQUEST_TYPE_DEMO_INSTALLATION = 'Install and Demo';
    
    //Service Request Status (Case)
    public static final String ON_HOLD = 'On Hold';
    public static final String RESUME = 'Resume';
    
    //Case Record Type Name
    public static final String CASE_RECORDTYPE_SERVICE_REQUEST = 'Service_Request';

    //Asset status values for Scrapped
    public static final List<String> ASSET_SCRAPPED_STATUS = new List<String>{'Scrapped'};
    public static final String ATT_MISSING_ATTENDANCE = 'Missing Attendance';
    public static final String ATT_LEAVE = 'Leave';
    public static final String ATT_LEAVE_Full_Day = 'Full Day';
    public static final String ATT_LEAVE_First_half = 'First Half';
    public static final String ATT_LEAVE_second_half = 'Second Half';
    public static final String ATTENDANCE_LOCATION_RESET_REQUEST = 'Base Location Reset Request';
    public static final String ATT_REGULAR = 'Regular';

    public static final String SERVICE_CONTRACT_ACTIVE_STATUS = 'Open';
    public static final String INFOR_SALES_ORDER_STATUS= 'Open';//added for SAF-196
    //Attendance record type
    public static final String BASE_LOCATION_RESET_REQUEST_RECORD_TYPE = 'Base_Location_Reset_Request';

    //chatter messages
    public static final String START_OF_DAY_ATTENDANCE_REMINDER_CHATTER_MESSAGE = 'Capture Start of Day Attendance';
    public static final String END_OF_DAY_ATTENDANCE_REMINDER_CHATTER_MESSAGE = 'Capture End of Day Attendance';
    
    //all Channels for Zip Code Rule
    public static final String ALL_CHANNELS = 'ALL';
    public static final List<String> ASSET_STATUS = new List<String>{'Purchased','Shipped','Installed','Registered','Obsolete'};
    
    public static final List<String> CALL_PENDING_REASONS_LIST = new List<String>{'spares not available','technician not available','technical support required',
                        'vendor dependency'};
        
    public static final String YES_CONSTANT = 'Yes';
    public static final String NO_CONSTANT = 'No';
    public static final String CUSTOMIZED_CONSTANT = 'Customized';
    public static final String NEW_CONSTANT = 'New';
    public static final String OLD_CONSTANT = 'Old';
    public static final String PM_CONSTANT = 'PM';
    public static final String BM_CONSTANT = 'BM';
    public static final String AUDIT_CONSTANT = 'Audit';
    public static final String COMISSIONING = 'Commissioning';
    //advance payment modes
    public static final String PAYMENT_MODE_EMI = 'EMI';
    
    public static final String PAYMENT_MODE_OTHERS = 'Others';
    //Added by namrata on 21-02-2023
    public static final String PAYMENT_MODE_CASH = 'Cash';
    
    //APD Record Types
    public static final String APD_INTERIO_RECORDTYPE_NAME = 'Interio_B2C';
    //BC Code and Lob Head Mappings (required for MHE write-off receivable approvals)
    public static final Map<String, String> BC_CODE_VS_LOB = new Map<String, String>{
        'KA' => 'Clean',
        'KZ' => 'Common',
        'KK' => 'Trucks',
        'KC' => 'Contracts',
        'KV' => 'Parts',
        'KH' => 'Rental',
        'KG' => 'Operations',
        'KW' => 'Warehouse',
        'GC' => 'Common',
        'GH' => 'Common',
        'GI' => 'Common',
        'GS' => 'Common',
        'GV' => 'Common',
        'GW' => 'Common',
        'GZ' => 'Common'
    };

    //map of Billing Frequency Vs Quanity
    public static Map<String,Integer> billingFreqVsQuantity=new Map<String,Integer>{
        'Yearly: Y20'=>1,
        'Half Yearly: H20'=>2,
        'Half Yearly: H10'=>2,
        'Quarterly: Q20'=>4,
        'Quarterly: Q10'=>4
    };
    
//MHE Division Vs LOB
    public static final Map<String, String> MHE_Division_Vs_LOB = new Map<String, String>{
            'Outright Equipment' => 'Equipments',
            'Spare Parts'=> 'Parts',
            'Contracts'=> 'Contracts',
            'Equipment Rental'=> 'Rentals',
            'Godrej RenTRUST'=> 'Rentals',
            'Outright Sales' => 'Equipments'
        };
    //MHE Division Vs LOB Names in Metadata
    public static final Map<String, String> MHE_Division_Vs_MetadataLOB = new Map<String, String>{
            'Outright Equipment' => 'WriteOff_Receivable_LOB_Equipments',
            'Spare Parts'=> 'WriteOff_Receivable_LOB_Parts_Contracts',
            'Contracts'=> 'WriteOff_Receivable_LOB_Parts_Contracts',
            'Equipment Rental'=> 'WriteOff_Receivable_LOB_Rentals',
            'Godrej RenTRUST'=> 'WriteOff_Receivable_LOB_Rentals',
            'Outright Sales' => 'WriteOff_Receivable_LOB_Equipments'
        };
     //MHE Division Vs Checker Names in Metadata
    public static final Map<String, String> MHE_Division_Vs_MetadataChecker = new Map<String, String>{
            'Outright Equipment' => 'WriteOff_Receivable_Checker_Equipments',
            'Spare Parts'=> 'WriteOff_Receivable_Checker_Parts',
            'Contracts'=> 'WriteOff_Receivable_Checker_Contracts',
            'Equipment Rental'=> 'WriteOff_Receivable_Checker_Rentals',
            'Godrej RenTRUST'=> 'WriteOff_Receivable_Checker_Rentals',
            'Outright Sales' => 'WriteOff_Receivable_Checker_Equipments'
        };
    
    //Service Contract Billing frequencies
    public static final String BILLING_FREQUENCY_SPECIAL = 'Special';
    public static final String BILLING_FREQUENCY_MONTHLY_M20 = 'Monthly: M20';
    public static final String BILLING_FREQUENCY_MONTHLY_M10 = 'Monthly: M10';
        
    //Personas (required for SSG Write-Off receivable approvals)
    public static final String SSG_TERRITORY_SALES_MANAGER = 'Territory Sales Manager';
    public static final String SSG_REGIONAL_SALES_MANAGER = 'Regional sales manager';
    public static final String SSG_NATIONAL_SALES_MANAGER = 'National sales manager';
    public static final String SSG_SALES_AND_MARKETING_HEAD = 'Sales & Marketing Head';
        
    //Application settings Name
    public static final String CONTRACT_EXECUTION_MANAGER = 'Contract Execution Manager';
    public static final String MARKETING_MANAGER_CONTRACTS = 'Marketing Manager - Contracts';
    public static final String MHE_CSG_HEAD = 'MHE CSG Head';
    public static final String LEVEL_2_ISR_APPROVER_WARRANTY_CONTRACTS='Level 2 ISR Approver Contracts/Warranty';

    //Applicaton settings Developer Names
    public static final String CONTRACT_EXECUTION_MANAGER_DEV_NAME = 'Contract_Execution_Manager';
    public static final String MHE_CONTRACT_RENTAL_CLAIM_REQUEST_APPROVER = 'Marketing_Manager_Rentals';
    public static final String MHE_CONTRACT_CONTRACT_CLAIM_REQUEST_APPROVER = 'MHE_Contract_C_Request_Contract_Approver';
    public static final String WRITEOFF_RECEIVABLE_LOB_PARTS_CONTRACTS = 'WriteOff_Receivable_LOB_Parts_Contracts';
    
    //receivable type
    public static final String RECEIVABLE_TYPE_OUTSTANDING = 'Outstanding';
    public static final String RECEIVABLE_TYPE_NORM = 'Norm based OS';
    public static final String NOT_DUE_STATUS = 'Not Due';

    public static final String ASSET_STATUS_SHIPPED = 'Shipped';
    public static final String CASE_ORIGIN_AUTOMATED = 'Automated';
    public static final String CASE_CLASSIFICATION_INSTALLATION = 'Installation';
    public static final String CASE_STATUS_REGISTERED = 'Registered';
    public static final String CASE_TYPE_COMMISSIONING = 'Commissioning';
    public static final String CASE_CALL_CATEGORY_COURTESY = 'Courtesy';
    public static final List<String> INSTALLATION_CASE_ACCOUNT_RT = new List<String>{'Business_Account','Key_Account','Customer'};
    public static final String ASSET_ACTIVE_STATUS = 'Active';
    public static final List<String> OPPORTUNITY_CLOSE_STAGES = new List<String>{'Closed Won', 'Closed Lost'};
    public static final Set<String> CALL_PENDING_REASONS_BRANCH_HEADS = new Set<String>{'Technician not available','Technical Support required','Vendor dependency','Spares not available'};
    public static final String SPARE_NOT_AVAILABLE = 'Spares not available';
    public static final String MHE_EMAIL_WEB_QUEUE = 'Default_Queue_MHE_Cases';
    public static final String CONTACT_ROLE_SUPERVISOR = 'Supervisor';
    public static final String MHE_GODREJ_BRANCH_CHAMPION = 'MHE Godrej Branch Champion';
    public static final String MHE_ASSET_RECORD_TYPE_DEV_NAME ='MHE_Asset';
    public static final String ASSET_UNREGISTERED_STATUS ='Unregistered';
    public static final String ASSET_ENROLLEMENT = 'Asset Enrollment';
    public static final String CASE_ASSET_DISPOSAL = 'Asset Disposal';
    public static final String CASE_STATUS_ASSET_VERIFICATION = 'Asset Verification';
    public static final String CASE_CALL_CATEGORY_SERVICE_AUDIT = 'Service Audit';
    public static final String CASE_TYPE_ASSET_MOVEMENT = 'Asset_Movement';
    public static final String CASE_TYPE_ASSET_HEALTH_CHECKUP = 'Health Checkup';
    public static final String CASE_TYPE_SERVICE_CONTRACT_MODIFICATION = 'Service Contract Modification';
    
    public static final Set<String> ASSET_CLASSIFICATION = new Set<String>{'Asset Modification Request','Asset Enrollment'};
    public static final List<String> PROJECT_MILESTONE_RECORD_TYPES = new List<String>{'Booking','Design_Clearance','Final_Commissioning_and_Handover','Site_Verification'};
    public static final String PROJECT_MILESTONE_COMPLETED_STATUS = 'Completed';
    public static final String PROJECT_MILESTONE_HO_PROJECT_PERSONA = 'SSG- Sales Engineer';

    public static final String ASSET_OBJECT_API_NAME = 'Asset';
    public static final String KEY_ACCOUNT_RECORDTYPE_DEV_NAME = 'Key_Account';
    public static final String ASSET_STD_WARRANTY = 'Std Warranty';
    public static final String ASSET_SILVER_EWP_WARRANTY = 'Silver(EWP)';

    
    //Service Form Recordtypes
    public static final String SERVICE_FORM_PM1_RECORD_TYPE_DEV_NAME = 'PM_Checklist_Electric';
    public static final String SERVICE_FORM_PM2_RECORD_TYPE_DEV_NAME = 'PM_Checklist_Diesel';
    public static final String SERVICE_FORM_COMMISSIONING_RECORD_TYPE_DEV_NAME = 'Commissioning_Checklist';
    public static final String SERVICE_FORM_JOB_CARD_RECORD_TYPE_DEV_NAME = 'Job_Card';
    public static final String SERVICE_FORM_FEEDBACK_RECORD_TYPE_DEV_NAME = 'Service_Case_Feedback';

    public static final Set<String> BYPASS_VALIDATION_FOR_CASE_ORIGIN = new Set<String>{'Web','Email','Automated'};
    public static final String CASE_STATUS_ASSIGNED = 'Assigned';
    public static final String CASE_STATUS_PENDING = 'Pending';
    public static final String CASE_STATUS_RESOLVED = 'Resolved';
    public static final String CASE_STATUS_CLOSED = 'Closed';

    public static final String SERVICE_FORM_STATUS_IN_PROGRESS = 'In Progress';
    public static final String SERVICE_FORM_STATUS_SUBMITTED = 'Submitted';

    public static final String MHE_DEALER_SUPERVISOR = 'MHE Dealer Supervisor';

    //MR Types
    public static final String MRTYPE_Service = 'Service';
    public static final String MRType_Sales = 'Sales';

    //Product Type Values
    public static final String PRODUCT_TYPE_INCLUSION = 'Inclusion';
    public static final String PRODUCT_TYPE_DC = 'Dealer consumption order';
    
    //email trigger for file explorer
    public static final String EMAIL_SUB = 'File Explorer- file upload alert :';
    public static final String DEAR_TEAM = 'Dear Team,';
    public static final String EMAIL_BODY = 'Please be informed that ';
    public static final String EMAIL_BODY1 = ') has uploaded file on ';
    public static final String Email_Interio_date_format = 'MMMMM dd, yyyy hh:mm:ss a';
    public static final String Full_stop = '.';
    public static final String Commas = ',';
    public static final String Bracket_open = ' ( ';
    public static final String Bracket_close = ' ) ';
    public static final String ATstr  = ' at ';
    public static final String Branchstr1  = ' Branch ';
    public static final String Folderstr1  = ' Folder)';
    public static final String strSemiColon = ';';
    public static final String kamAccount = ' Kam Account ';
    public static final String onn = ' on ';
    public static final String Underscore = '_';
    
    
    
    

    //Order Record Types
    public static final String ORDER_MHE_ORDER_PRIMARY_RECORD_TYPES = 'MHE Order - Primary';
    public static final String ORDER_MHE_ORDER_SECONDARY_RECORD_TYPES = 'MHE Order - Secondary';


    //MR- Order Type Mapping
    public static final Map<String, String> ORDER_TYPE_MAPPING = new Map<String, String>{
        'S10 / Normal (With Freight)'=> 'S10',
        'S16 / War Issue & Receipt with Freight'=>'S16',
        'S01 / Normal'            => 'S01',
        'S02 / Repair Warranty'   =>'S02',
        'S03 / Emergency'         => 'S03',
        'S04 / Warranty'          => 'S04',
        'S05 / Supplier Claim'    => 'S05',
        'S06 / Customer Claim'     => 'S06',
        'S07 / Project'            => 'S07',
        'S08 / TRP'               => 'S08',
        'S09 / Transport Service'  => 'S09'
  };

    // Default Warehouse Code for Sales MR Type
    public static final String WAREHOUSE_CODE_MRTYPE_SALES = 'Z2F18S';

    //Default Sales Office Code for Sales MR Type
    public static final String SALESOFFICE_CODE_MRTYPE_SALES = 'K2Y001';

    public static final Map<String,String> PRODUCT_CATEGORY_WITH_EQUIPMENT_CATEGORY = new Map<String,String>{
        'Light Diesel'=>'CB-D',
        'Medium Diesel'=>'CB-D',
        'Heavy Diesel'=>'HE',
        'Electric'=>'CB-E',
        'HPT'=>'WE',
        'BOPT'=>'WE',
        'Stacker'=>'WE',
        'Platform Truck'=>'WE', 
        'Tow Truck'=>'WE',
        'Reach Truck'=>'HE',
        'Stock Picker'=>'HE',
        'Turret Stock Picker'=>'HE',    
        'Articulated FLT'=> 'HE',   
        'Sweeper'=>'AD',    
        'Scrubber'=>'AD',   
        'Access Equipment'=>'AD',   
        'Rough Terrain'=>'HE',  
        'Dock Leveler'=>'WE',   
        'Side Loader'=>'AD'
    };
    
    //Account Team Member Role for appliances added by pankaj on 21 oct 2021
    public static final String ACCOUNT_TEAM_MEMBER_ROLE_ASM = 'ASM';
    public static final String ACCOUNT_TEAM_MEMBER_ROLE_RSO = 'RSO';
    public static final String ACCOUNT_TEAM_MEMBER_ROLE_VM = 'Visual Merchandiser';
    public static final String SALES_SERVICE_MANAGER_ROLE = 'Sales/Service Manager';

    public static final String SALES_MANAGER_ROLE_1 = 'MHE_Sales_Engineer_Comm_AD_Hi_KLKATA_1';
    public static final String SALES_MANAGER_ROLE_2 = 'MHE_Sales_Manager_INDR';
    public static final String SALES_MANAGER_ROLE_3 = 'MHE_Sales_Manager_LUCK'; //Added SALES MANAGER ROLE 1,2 and 3 for MHE  by Shreela on 12th May 2022
    public static final String SALES_MANAGER_ROLE_4 = 'MHE_Sales_Manager_GUWHT';    //added by Shreela on 22nd July 2022 for Tkt#30551942
        
    //Milestonewise due date calculation for SSG added by pankaj on 24 oct 2021
    Public static final Id RECEIVABLE_RECORDTYPE_ID = Schema.SObjectType.Receivable__c.getRecordTypeInfosByDeveloperName().get(RECEIVABLE_RECORDTYPE).getRecordTypeId();
    Public static final Id PM_Handover_RECORDTYPE_ID = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(PM_Handover_RECORDTYPE_SSG).getRecordTypeId();
    Public static final Id INVOICE_RECORDTYPE_ID = Schema.SObjectType.Receivable__c.getRecordTypeInfosByDeveloperName().get(RECEIVABLE_INVOICE).getRecordTypeId();
    
    //Added for automatic Case(SR) generation for SSG
    public static final String SUPPLY_AND_MATERIAL_PULL_PLAN= 'Supply_and_Material_Pull_Plan';
    Public static final Id PM_SupplynMaterial_RECORDTYPE_ID = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(SUPPLY_AND_MATERIAL_PULL_PLAN).getRecordTypeId();
    
    //Added for retrieving Sales Manager used in Approval Process for Construction B2B 
    public static final String const_engineer_persona  = 'Construction-Sales Engineer';
    public static final String const_manager_persona  = 'Construction-Sales Manager';
    
   //Added for retrieving Sales Manager used in Approval Process for Locks B2B
    public static final String locks_bde_persona  = 'Locks-BDE';
    public static final String locks_bdm_persona  = 'Locks-BDM';
    public static final String locks_zm_persona = 'Locks-ZM'; //Added by Srini for Zonal manager on 10th May 2023
    public static final String locks_rm_persona = 'Locks-RM';//Added by mrunali chaudhari on 03/08/2023 for SLF-123
    public static final String locks_zh_persona = 'Locks-ZH';
       
    //Added for Construction LOB
    public static final String Construction_LOB_WPS  = 'WPS';
    public static final String Construction_LOB_RMC  = 'RMC';
    public static final String Construction_Prod_SubCategory_AAC  = 'AAC';
    public static final String Construction_Prod_SubCategory_RCM  = 'RCM';
    
    //Project milestone recordTypes Added for SSG SSF-41 added by pankaj on 1 june 2022
    public static final String SUPPLY_AND_MATERIAL_PULL_PLAN_RECORD_TYPE_ID= 'Supply_and_Material_Pull_Plan';
    public static final String DESIGN_CLEARANCE_RECORD_TYPE_ID= 'Design_Clearance';
    public static final String HO_PROJECTS_RECORD_TYPE_ID= 'Execution_2';
    public static final String EXECUTION_RECORD_TYPE_ID='Execution';
    Public static final Id Supply_milestone_RECORDTYPE_ID = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(SUPPLY_AND_MATERIAL_PULL_PLAN_RECORD_TYPE_ID).getRecordTypeId();
    Public static final Id Design_milestone_RECORDTYPE_ID = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(DESIGN_CLEARANCE_RECORD_TYPE_ID).getRecordTypeId();
    Public static final Id Ho_Project_milestone_RECORDTYPE_ID = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(HO_PROJECTS_RECORD_TYPE_ID).getRecordTypeId();
    Public static final Id Execution_milestone_RECORDTYPE_ID = Schema.SObjectType.Project_milestone__c.getRecordTypeInfosByDeveloperName().get(EXECUTION_RECORD_TYPE_ID).getRecordTypeId();
    
    public static final String PROJECTMILESTONE_COMPLETED_STATUS = 'Completed';    
    //Email Alerts
      public static final String SUPPLY_MILESTONE_OVERDUE_EMAIL_ALERT = 'Overdue_Supply_and_Material_Pull_Plan_Milestone_Notification';  
      public static final String DESIGN_MILESTONE_OVERDUE_EMAIL_ALERT = 'Overdue_Milestone_Notification';
      public static final String HO_PROJECTS_MILESTONE_OVERDUE_EMAIL_ALERT = 'Overdue_HO_Projects_Milestone_Notification';
    
    //SSG Roles
    public static final String SSG_HO_PROJECTS_ROLE = 'SSG HO Projects';
    public static final String SSG_CHEN_Mgr_ROLE = 'SSG CHEN Mgr – PPC AGM';
    
    //MHE Equipments product
    public static final String Other_Attachments = 'GMD_FLT_attachments';
    
     //Construction RMC and WPS value, Added by Sreekanth Jujare
    public static final String NOT_APPLICABLE = 'Not Applicable';
        
    public static final String OPP_STAGE_WON = 'Closed Won' ;  //Added by Shreela on 23rd September 2022 for SAEPB - 44 Appliance B2B
    
    //Added by Pankaj on 28th September 2022 for interio B2B 
    public static final String Interio_Sub_Division_B2B_KAM = 'B2B-KAM';
    public static final String Interio_Sub_Division_B2B_NON_KAM = 'B2B-NON KAM';
    public static final String Interio_Sub_Division_B2B_BD = 'B2B-BD';
    public static final String Transaction_Type_GEM = 'GEM';
    public static final String Transaction_Type_GEM_RC = 'GEM+RC';
    public static final String Transaction_Type_GEM_PAC = 'GEM-PAC';
    public static final String Product_Line_DESKING = 'W11';
    public static final String Product_Line_SEATING = 'W12';
    public static final String Product_Line_STORAGE = 'W13';
    public static final String Product_Line_OPOS = 'W14';
    public static final String Product_Line_LAB = 'W15';
    public static final String Product_Line_HEALTHCARE = 'W17';
    public static final String Product_Line_B2C = 'B2C';
    public static final String Product_Line_WSA = 'WSA';// Added by snehal w 15/06/2023
    public static final String Interio_B2B_APO_RT ='Interio_B2B_APO';
    public static final String Interio_B2B_Finished_Good_RT ='Interio_B2B_Finished_Good';
    
    //Interio B2B queues
    public static final String Interio_B2B_KAM_QUEUE = 'KAM Queue - Interio B2B Division';
    public static final String Interio_B2B_SEATING_QUEUE = 'Interio B2B Seating';
    public static final String Interio_B2B_DESKING_QUEUE = 'Interio B2B Desking';
    public static final String Interio_B2B_OPOS_QUEUE = 'Interio B2B OPOS';
    public static final String Interio_B2B_LAB_QUEUE = 'Interio B2B Lab';
    public static final String Interio_B2B_HEALTHCARE_QUEUE = 'Interio B2B Health Care';
    public static final String Interio_B2B_BD_QUEUE = 'Interio B2B BD';
    public static final String Interio_B2B_GEM_RC_QUEUE = 'Interio B2B Gem';
    public static final String Interio_B2B_B2C_QUEUE = 'Interio B2B B2C';
    public static final String Interio_B2B_STORAGE_QUEUE = 'Interio B2B Storage';// Added by Snehal W 12/06/2023
    

    
    //Interio B2B Transaction Types
    public static final String Transaction_Type_Scheme = 'Scheme';
    public static final String Transaction_Type_WD_Display = 'WD Display';
    public static final String Transaction_Type_Stock_Liquidation = 'Stock Liquidation';
    
        //Trigger Context Variable added by shreela on 16th November 2022 for SAEPB-44
    public static final String Context_Variable_Before = 'before';
    public static final String Context_Variable_After = 'after';
    public static final String Context_Variable_Update= 'update';
    public static final String Context_Variable_Insert= 'insert';//Added by Shreela on 16th Jan 2023
    
    //Payment terms values in Quote (Added by Shreela on 17th November 2022  for SAEPB-44)
    public static final String Payment_Terms_Value_Adv_Payment = 'Advance Payment';
    public static final String Payment_Terms_Value_Within_7_Days = 'Within 7 days of Invoice submission';
    public static final String Payment_Terms_Value_Greater_than_25_Days= 'Greater than 25 days'; //Added by Shreela on 13th Dec 2022
    public static final String Payment_Terms_Value_C28 = 'C28'; //Added by Shreela on 19th Dec 2022
    
    //Requested Customer Discount Range values added by Shreela on 21st November 2022 for SAEPB - 44
    public static final Decimal Req_Cust_Disc_Value_1 = 0.0;
    public static final Decimal Req_Cust_Disc_Value_2 = 0.5;
    public static final Decimal Req_Cust_Disc_Value_3 = 4;
    
    //No of Days Approved value added by Shreela on 21st November 2022 for SAEPB - 44
    public static final Integer No_of_Days_Check = 15;
    
    // Interio B2B 
    public static final String PERSONA_VP ='Vice President';
    public static final String PERSONA_SalesPerson ='Sales Person';
    public static final String PERSONA_CST = 'CST';
    
    public static final String QUALIFIED = 'Qualified';
    public static final String UNQUALIFIED = 'Unqualified'; //Added by Sreekanth Jujare on 14/12/2022
    //Added by pankaj on 7 Dec 2022 for MHE equipments - SMEPB-48
    public static Boolean isBeforeInsert = False;
    public static final String Logistics_Company_Branch_2000 = '2000';
    public static final String Logistics_Company_Branch_2010 = '2010';
    public static final String Warehouse_code_KAF11S = 'KAF11S';
    public static final String Warehouse_code_KBF11S = 'KBF11S';
    public static final String Sales_Office_code_KZA016 = 'D_KZA016';
    public static final String Sales_Office_code_KZASD1 = 'D_KZASD1';
    public static final String Order_Type_NOR = 'NOR';
    public static final String Order_Type_NOF = 'NOF';
    public static final String Delivery_Term_EW1 = 'EW1';
    public static final String Delivery_Term_EW4 = 'EW4';
    public static final String Delivery_Term_EW5 = 'EW5';
    public static final String Delivery_Term_EW6 = 'EW6';
    
     //Added by rohit on 20 Dec 2022 for Interio B2b Email Notification
    public static final String Interio_B2B_Submitted_For_Approval_Template='Interio B2B Submitted For Approval';
    public static final String Interio_B2B_Approval_Status_Change_Template='Interio B2B Approval Status Change';
    public static final String One_CRM='OneCRM';
    //Added by snehal w on 28th feb 2023 for Interio B2b
    public static  Boolean interioB2BPage = True;   

    public static final String STATUS_REQUESTED = 'Requested';
    public static final String QLI_Won_Status = 'Won' ;
    //Added by snehal w on 16 feb 2023 for PES Report
    public static final String PES_Report_Template='PES Report';
    public static final String PES_QUARTERLY_Report_Template='PES Quarterly Report';
    public static final String PES_BiYearly_Report_Template='PES Biyearly Report';//Added by Shreela  for SGF-53
    public static final String PES_9Months_Report_Template='9-Month Consolidated Sales Report'; //Added by Shreela on 14th Nov 2023 for SPEP - 34
    public static final String PES_YearEnd_Report_Template='Fiscal Year-end  Sales Report'; //Added by Shreela on 14th Nov 2023 for SPEP - 34
    public static final String PES_Common_Email_Template='Common PES Report'; //Added by Shreela on 28th Nov 2023 for SPEP - 34
    public static final String  OPPORTUNITY_QUOTED = 'Quoted(Result Awaited)';
    public static final String  OPPORTUNITY_INPROCESS = 'In Process';
    public static final String  OPPORTUNITY_REGRET = 'Regret';
    public static final String  OPPORTUNITY_SHELVED = 'Shelved';
    public static final String  OPPORTUNITY_CLOSEDWON = 'Closed Won';
    public static final String  OPPORTUNITY_CLOSEDLOST = 'Closed Lost';
    public static final String OPPORTUNITY_FIRM = 'firm';
    public static final String OPPORTUNITY_BQ = 'BQ';
    
    public static final String OPPORTUNITY_SECTOR = 'Others';
    public static final String OPPORTUNITY_RECORD_TYPE = 'PES';
    public static final String OPPORTUNITY_NO_CONSTANT_GPE = 'GPE';
    public static final String QUOTE_RECORDTYPE_SSD = 'Security_Solutions_B2B'; //Added by Sreekanth Jujare for SSD
    public static final string SSD_BUSINESS_UNIT = 'U'; //Added by Sreekanth Jujare for SSD
    public static final Decimal FORTY = 40.0; //Added by Sreekanth jujare for SSD
    public static final String DEALER_PRICE = 'Dealer Price'; //Added by Sreekanth Jujare
    public static final String DIRECT_BILLING_TO_DEALER = 'Direct Billing to Dealer'; //Added by Sreekanth Jujare
    public static final String DIRECT_SCHEME_BILLING = 'Direct Scheme Billing';//Added by Sreekanth Jujare
    public static final String R_SERIES_BILLING = 'R series Billing';//Added by Sreekanth Jujare
    public static final String RSR_ORDER_TYPE = 'RSR';//Added by Sreekanth Jujare
    public static final String STARTED = 'Started'; //Added by Sreekanth Jujare
    public static final String SUBMITTED = 'Submitted'; //Added by Sreekanth Jujare
    public static final String PENDING = 'Pending'; //Added by Sreekanth Jujare
     //Added by pankaj on 13 March 2023 for SSG
    public static final String Regular_Category = 'Regular';
    public static final String Key_Category = 'Key';
    public static final String Lcs_Category = 'Life Cycle Services';
    public static final String Key_Lcs_Category = 'Key - Life cycle services';
    public static final String Opportunity_type_Swift = 'Swift';
    public static final String Opportunity_type_Non_Swift = 'Non-Swift';
    public static final String Opportunity_type_Service = 'Service';
    
    //Added by rohit on 23/03/2023 for Locks B2C ISTD
    public static final String RECORDTYPE_Locks_B2C_ISTD ='Locks_B2C_ISTD';
    public static final String QliLostStatus = 'Lost';
    public static final String QliWonStatus = 'Won';
    public static final String B2C_ISTD='B2C ISTD';
    
    //Added by rohit on 23/03/2023 for MHE Knowlege Article
    public static final Set<String> MHE_External_User_Profiles = new Set<String>{'MHE Dealer Sales Rep Partner User','MHE Dealer Supervisor Partner User','MHE Dealer Sales Manager Partner User','MHE Dealer Service Rep Partner User',
                                                                                'MHE Service Dealer Manager Partner User','MHE Dealer Technician Partner User','MHE Sales KAM Functional Head User'};
        
    public static final Set<String> MHE_Internal_User_Profiles = new Set<String>{'MHE Godrej Technicians','MHE Sales KAM FUNCTIONAL HEAD user','MHE SOSER Engineer','MHE Godrej Branch Champion',
                                                                                'MHE Service KAM Head User','Service head and manager user','MHE Sales User','MHE Sales KAM Functional Head User - View All','MHE HO Support'};
    public static final String MHE_Internal_User_Knowledge_Published = 'MHE_Internal_User_Knowledge_Published';   
    public static final String MHE_External_User_Knowledge_Published = 'MHE_External_User_Knowledge_Published';

    public static final String statements_Attached = 'Statements Attached';
    
    //Added by Shreela on 3rd May 2023 for SPBSCI-29    
    public static final String openingBracket = '(';    
    public static final String closingBracket = ')';
    
         //Added by Pankaj on 3rd May 2023 for SCEP-27
    public static final String Hyphen = '-';
    public static final String Level_Str = 'Level';
    public static final String Construction_subLOB_WPS_MUM  = 'WPS-MUM';
    public static final String Construction_subLOB_WPS_PUNE  = 'WPS-PUNE';
    public static final String Construction_subLOB_RMC_MUM  = 'RMC-MUM';
    public static final String Construction_subLOB_RMC_AMB  = 'RMC-AMB';
    public static final String Construction_subLOB_RMC_PUNE_EAST  = 'RMC-PUNE-EAST';
    public static final String Construction_subLOB_RMC_PUNE_WEST  = 'RMC-PUNE-WEST';
 
    public static final String ONECRMEMAIL = 'onecrm@godrej.com';
    public static final String CM_Lead_Reminder_Template = 'CM_Lead_Reminder';
    
    
    public Static final String CLUSTER_MUMBAI = 'MUM';
    public Static final String CLUSTER_MMR = 'MMR';
    public Static final String CLUSTER_PUNE_EAST = 'Pune East';
    public Static final String CLUSTER_PUNE_WEST = 'Pune West';
    public Static final String CLUSTER_WPS = 'WPS';
    public static final String SSD_Reminder_Template ='SSD_Quote_Approval_template_to_immediate_approver_1679570131184';//Added by Snehal waghmare
    public static final String Lead_SObject='Lead'; //Added by Namrata on 16th May 2023 for SPEP-4
    public static final String Opp_SObject='Opportunity'; //Added by Namrata on 16th May 2023 for SPEP-4
    //Added by Shreela on 24th May 2023 for SPEP-3,4,7 and 8
    public static final String PES_Lead_RecordType='PES_Lead'; 
    public static final String PES_Opp_RecordType='PES'; 
    public static final String FileType_Notes_Value = 'SNOTE';
    
    //Added by Rohit Jadhav on 25th May 2023.
    public static final String Locks_B2B_Quote_Approval_Template ='Locks_B2B_Quote_Approval_Template_1684301325224';
    public static final String USER_PREFIX = '005';//Added by Snehal W on 24/07/2023
    
    //Added by Ashwin Thale on 01th Nov 2023.
    public static final String Locks_B2B_Weekly_Quotes_Expiration_Template ='Locks_B2B_Weekly_Quotes_Expiration_Template';
    public static final String OrgWideEmailAddressDisplayName ='OneCRM';

    //Added by Shreela on 4th August 2023
    public static final String SOA_Object = 'Statement_of_Account__c';
    
    //Added by Shreela on 11th September 2023 for SPEP -24
    public static final String User_Object = 'User';
    public static final String contextIdValue = 'pesLookup';

    public static final String BSO_Object = 'Billed_Sales_Outstandings__c'; //Added by Shreela on 18th Sept 2023 for SMEPB - 119
    public static final Id Interio_BMR_RECORDTYPE = Schema.SObjectType.task.getRecordTypeInfosByDeveloperName().get(INTERIO_BMR).getRecordTypeId();
    
    //Added by Shreela on 4th October 2023 for SMEPB - 123/124
    public static final String caseReadTeamAccess = 'Read only Agent';
    public static final String SR_Account_Creation = 'Account_Creation_Request';
    public static final String Queue_Type = 'Queue';
    public static final String Assigned_Syncing_Required_Queue ='Assign_Sync_Required_Queue';
    public static final String Status_SR_Type_1 = 'New';
    public static final String Status_SR_Type_2 = 'Working';
    public static final String Status_SR_Type_3 = 'Roll Back for Clarity';
    public static final String Status_SR_Type_4 = 'Syncing Required';
    
    //Added by rohit on 05/07/2023 for PED
    public static final String PED_Lead_RT ='PED_Lead';
    public static final String PED_QUOTE_RT ='PED';
    public static final String PED_ORDER_RT ='PED';
    public static final String PED_BQ_OPPORTUNITY_RT ='PED_BQ';
    public static final String PED_FIRM_OPPORTUNITY_RT ='PED_Firm';
    public static final String PED_BQ ='Budgetary';
    public static final String PED_FIRM ='Firm';
    public static final String PED_PED_Head_Sales_E_Band ='PED Head Sales - E Band';
    public static final String PED_Head_Sales_T_Band ='PED Head Sales - T Band';
    public static final String PED_Manager_P_Band ='PED Manager - P Band';
    public static final String PED_PED_Asst_Manager_O_Band ='PED Asst Manager - O Band';
    public static final String Conductive ='Conducive';
    public static final String Unit_Million='Million';
    public static final String PED_POWER_Sector  ='POWER';
    public static final String PED_DOMESTIC_Region ='DOMESTIC';
    public static final String PED_MEA_Region ='MEA';
    public static final String PED_SEFE_Region ='SEFE';
    public static final String PED_AMERICAS_Region ='AMERICAS';
    public static final String PED_EUROPE_Region ='EUROPE';
    public static final String PED_POWER_Team ='POWER Team';
    public static final String PED_DOMESTIC_Team ='DOMESTIC Team';
    public static final String PED_MEA_Team ='MEA Team';
    public static final String PED_SEFE_Team ='SEFE Team';
    public static final String PED_AMERICAS_EUROPE_Team ='AMERICAS & EUROPE Team';
    public static final String PED_IB_INSURANCE_RT ='PED_Insurance';
    public static final String PED_IB_BG_RT ='PED_Bank_Guarantee';
    public static final String PED_SalesTeam_Queue_RT ='PED_Bank_Guarantee';
    public static final String Like_PED ='%PED%';
    public static final String PED_Equipment_Type_FIRM ='FIRM';
    public static final String PED_Equipment_Type_BUDGETARY ='BUDGETARY';
    public static final String Currency_INR ='INR';
    public static final String Currency_USD ='USD';
    public static final String Currency_EURO ='EUR';
    
    public static final Set<String> PED_Intimation_To_Sales_Template_Set = new Set<String>{'Intimation_to_Sales_After_BG_Expiry_1690890044695',
                                                                                           'Intimation_to_Sales_Before_BG_Expiry_1690889982360',
                                                                                           'Intimation_To_Sales_After_Insurance_Expiry_1690889816140',
                                                                                           'Intimation_to_Sales_before_Insurance_Expiry_1690889660689'};                                                                                               
    public static final String PED_Intimation_to_Sales_After_BG_Expiry_Template ='Intimation_to_Sales_After_BG_Expiry_1690890044695';
    public static final String PED_Intimation_to_Sales_Before_BG_Expiry_Template ='Intimation_to_Sales_Before_BG_Expiry_1690889982360';
    public static final String PED_Intimation_To_Sales_After_Insurance_Expiry_Template ='Intimation_To_Sales_After_Insurance_Expiry_1690889816140';
    public static final String PED_Intimation_to_Sales_Before_Insurance_Expiry_Template ='Intimation_to_Sales_before_Insurance_Expiry_1690889660689';
    public static final String PED_Follow_up_email_to_Finance_for_BG_Request_Template ='Follow_up_email_to_Finance_for_BG_Request_1691035626088';
    public static final Set<String> PED_Sales_Role_Name_Set = new Set<String>{'Global Power','OGC & Power','Domestic OGC','Europe & Americas OGC','MEA OGC','SEFE OGC'};
    
    public static final List<String> UNITS = new List<String>{ '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine' };
    public static final List<String> TEENS = new List<String>{ 'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen' };
    public static final List<String> TENS = new List<String>{ '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety' };
    public static final String HUNDRED = 'Hundred';
    public static final String THOUSAND = 'Thousand';
    public static final String LAKH = 'Lakh';
    public static final String CRORE = 'Crore';
    public static final String MILLION = 'Million ';  
    public static final String BILLION = 'Billion';  
    public static final String TRILLION = 'Trillion';  
    public static final String One_Trillion='1000000000000';
    public static final String Quote_Status_Order_Risk_Matrix_Form_Completed='Order Risk Matrix Form Completed';
    public static final String PED_Quote_Approval_Email_Template='PED_Quote_Approval_Email_Template_1699515927493';
    public static final String Low = 'Low';
    
    public static final String SOUTH = 'STH'; //Added by Sreekanth Jujare
    public static final String NORTH = 'NOR'; //Added by Sreekanth Jujare
    public static final String EAST = 'EST'; //Added by Sreekanth Jujare
    public static final String WEST = 'WST'; //Added by Sreekanth Jujare
    public static final String Interio_B2B_DOCUMENT_TRANSACTION_MODIFIED='Interio B2B Document Transaction Modified';
    
    public static final Integer Product_Category_A = 1; //Added by Shreela on 18th Dec 2023 for SMEPB 111
    public static final Integer Product_Category_B = 2; //Added by Shreela on 18th Dec 2023 for SMEPB 111
    public static final Integer Product_Category_AB_C =3; //Added by Shreela on 18th Dec 2023 for SMEPB 111
    public static final Boolean False_Constant=false;  //Added by Shreela on 20th Dec 2023 for SMEPB 111
    public static final Boolean True_Constant=true;  //Added by Shreela on 20th Dec 2023 for SMEPB 111
    public static final String DPP_List_Price='MHE DPP SALES PRICE LIST A'; //Added by Shreela on 20th Dec 2023 for SMEPB 111
    public static final String FG_List_Price='MHE FG SALES PRICE LIST'; //Added by Shreela on 20th Dec 2023 for SMEPB 111
    
    public static final String Sales_Branch_1000='1000'; // Added by Rohit on 20th Dec 2023 for SLEPBS-57
    public static final String Sales_Branch_1030='1030'; // Added by Rohit on 20th Dec 2023 for SLEPBS-57
    
    public static final String BUSINESS_UNIT_PED_DIVISION='P';    
}