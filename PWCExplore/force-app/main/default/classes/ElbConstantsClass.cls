/*------------------------------------------------------------------------
Author:        Jayasurya Gunasekharan
Company:       Stetig
Description:   Class for all Constants
Inputs:        NA
Last Modified: 28/12/2021
Test Class:    
----------------------------------------------------------------------------*/
public with sharing class ElbConstantsClass {
    
    /*String Values for Class BillingServices*/
    public static final String LOG_SUCCESS_MESSAGE_SHORT = 'S';
    public static final String LOG_ERROR_MESSAGE_SHORT = 'E';
    public static final String LOG_SUCCESS_MESSAGE = 'INFO';
    public static final String LOG_SUCCESS_MESSAGE_LONG = 'SUCCESS';
    public static final String LOG_ERROR_MESSAGE = 'ERROR';
    public static final String LOG_TYPE = 'INFO';
    public static final String LOG_CATEGORY = 'ELB- Monthly Billing Batch';
    public static final String LEASE_STATUS_ACTIVE = 'Active Lease';
    public static final String LEASE_STATUS_FREE = 'Rent Free Period';
    public static final String LEASE_STATUS_NA = 'Not Applicable';
    public static final String CHARGE_TYPE_LICENSE_FEE = 'Licensee Fee'; //Record Type Name for License Fee Billing
    public static final String CHARGE_TYPE_LICENSE_FEE_MONTHLY = 'License Fee Monthly';
    public static final String TYPE_BILLING_FIXED = 'Monthly fixed';
    public static final String BILLING_APPROVAL_NOT_SUBMIT = 'Not Submitted';
    public static final String BILLING_SYNC_STATUS_NOT_POST= 'Not Posted';
    public static final String LOG_SUCCESS_MESSAGE_SHORT25= 'S'; 
    public static final String TYPE_BILLING_VARIABLE = 'Monthly variable';
    public static final String BILLING_APPROVA_CONSUMPTION_NOT_ENTER = 'Consumption not entered';
    public static final String CHARGE_TYPES_LICENSE_FEE = 'License Fee';
    public static final String TYPE_BILLING_QUARTERLY_FIXED = 'Quarterly Fixed';
    public static final String TYPE_BILLING_YEARLY_FIXED = 'Yearly Fixed';
    
    public static final String CHARGE_TYPE_CAM = 'CAM';
    public static final String CHARGE_TYPE_CAM1 = 'CAM Charges';
    public static final String CHARGE_TYPE_NAME_CAM = 'ELB ITPrk C CAM Chrgs';
    
    public static final String CHARGE_TYPES_HOUSING = 'Housing';
    public static final String CHARGE_TYPES_RESIDENTIAL = 'Residential';//Added for Residential
    public static final String RECORD_TYPE_HOUSING = 'Housing Billing';
    public static final String RECORD_TYPE_RESIDENTIAL = 'Residential Rental Billing';//Added for Residential
    public static final String CHARGE_TYPE_CAR_PARK = 'Car Park';
    public static final String CHARGE_TYPES_CAR_PARK = 'Car Parking billing';
    
    public static final Integer BILLING_DATE = 25;
    public static final Integer BILLING_HOUSING_DATE = 10;
    
    
    /*String Values for Class CreateHOT*/
    public static final String RECORD_TYPE_PROPOSED_CLAUSES = 'Proposed Clauses Format';
    public static final String NO = 'NO';
    public static final String PATTERN = '(\\{(M1|M2|M3)\\})';
    public static final String PATTERN_M1 = '{M1}';
    public static final String PATTERN_M2 = '{M2}';
    public static final String PATTERN_M3 = '{M3}';
    public static final String LICENSOR_LOCKIN_PERIOD_MONTHS = 'Licensor_Lockin_period_in_months__c';
    public static final String LICENSEE_LOCKIN_PERIOD_MONTHS = 'Licensee_Lockin_period_in_months__c';
    public static final String LEASING_TERM_MONTHS = 'Leasing_Term_in_months__c';
    public static final String SEC_DEPOSIT_CALCULATION_TYPE = 'Security_Deposit_Calculation_Type__c';
    public static final String HANDOVER_DATE_PREMISE = 'Handover_date_of_Premises__c';
    public static final String SEC_DEPOSIT = 'Security_Deposit__c';
    public static final String SIMPLE = 'Simple';
    public static final String AVG = 'Average';
    public static final String HANDOVER_CONDITION = 'Handover Condition';
    public static final String HOST = 'Host';
    
    /*String VAlues for PowerReimbursementHandler */
    public static final String POWER_REIMBURSMENT = 'Power Reimbursement';
    public static final String POWER_REIMBURSMENT_DEV = 'Power_Reimbursement';
    public static final String RATE_1 = 'Rate 1';
    public static final String RATE_2 = 'Rate 2';
    public static final String RATE_3 = 'Rate 3';
    public static final String Additional_AC_Charges = 'Additional_AC_Charges';
    public static final String Water_Reimbursement_Charges = 'Water billing';
    
    /*String Values for premiseDocumentController */
    public static final String APPROVED = 'Approved';
    public static final String CAM_CHARGES = 'Common Area Maintenance (CAM) Charges';
    public static final String OFFERED_FLOOR_AREA = 'Offered Floor & Area';
    public static final String MONTHLY_COMP_FEE = 'Monthly Compensation Fees';
    public static final String SECURITY_DEPOSIT = 'Security Deposit';
    public static final String IMAGE_TITLE = 'Building';
    
    /*String Values for TalkingSheetController */
    public static final String RECORD_TYPE_STANDARD_CLAUSES = 'Standard_Clauses';
    
    /*String Values for changeAccountName */
    public static final String ACCOUNT_SERIES_CHILD = 'NIX';
    
    /*String Values for contractRenewal */
    public static final String EVENT_BLOCKED = 'Blocked';
    
    /*String Values for leasingProperty */
    public static final String FLOOR_STATUS_FULL_VACANT = 'Fully Vacant';
    public static final String FLOOR_STATUS_PARTLY_VACANT = 'Partly Vacant';
    public static final String FLOOR_STATUS_CHURN_EXPECTED = 'Churn Expected';
    public static final String FLOOR_STATUS_LEASED_OUT = 'Leased Out';
    public static final String UNIT_STATUS = 'Proposed';
    public static final String ACTIVE_STATUS = 'Leased';
    
    
    /*String Values for parentAccountSearchController */
    public static final String PARENT_ACCOUNT_BUSINESS_UNIT = 'Z';
    public static final String ACCOUNT_CODE_IPC = '1DR';
    public static final String ACCOUNT_TYPE_VENDOR = '1';
    public static final String LEAD_LEASING_B2B_DEV = 'B2B_Leasing_Lead';
    
    /*String Values for PrimaryRecordCreationHandler */
    public static final String SYNCED = 'Synced';
    public static final String READ_TO_BE_SYNCED = 'Ready to Sync';
    public static final String LOGISTICS_COMPANY_BRANCH = '2110';
    public static final String SALES_ORDER_SERIES = 'NOB';
    public static final String BUSINESS_UNIT_CONSTRUCTION_LEASING = 'N';
    public static final String ORDER_STATUS = 'Draft';
    public static final String SALES_OFFICE_CODE = 'NZER01';
    public static final String ORDER_TYPE_NOI = 'NOI';
    public static final String ORDER_ITEM_PRICE_ORIGIN_MANUAL = 'manual';
    public static final String USER_SALARY_CODE_RAJEEV = '44413';
    public static final String CONSTRUCTION_LEASING_PRICEBOOK = 'CON_2110 / CONSTRUCTION LEASING PB';
    
    /*Object API Names*/
    public static final String BILLING_API = 'Billing__c';
    public static final String HEAD_OF_TERMS_API = 'HEAD_OF_TERMS__c';
    public static final String LEAD_API = 'Lead';
    public static final String OPPORTUNITY_API = 'Opportunity';
    
    /*Record Types*/
    public static final String RECORD_TYPES_CHARGES_TYPE = 'Charges_Type__c';
    public static final String RECORD_TYPES_B2B_LEASING_LEAD = 'B2B Leasing Lead';
    public static final String ORDER_CONSTRUCTION_LEASING = 'Construction Leasing';
   // public static final String ACCOUNT_CONSTRUCTION_DIVISION = 'Construction Division';
    public static final String OPPORTUNITY_RECORD_TYPE_FINAL_LEASING = 'Marked_Final_Leasing_B2B';
    public static final String OPPORTUNITY_RECORD_TYPE_LEASING = 'Leasing_B2B';
    public static final String CASE_RECORD_TYPE_LEASING = 'Leasing_B2B_Service';
    
    /* FOR REVENUE PLANNING */
    public static final String CATEGORY_COMMERCIAL = 'Commercial';
    
    /* FOR FACILITY BOOKING */
    public static final String FACILITY_STATUS_CRMHEAD_APPROVAL = 'CRM head approval pending';
    public static final String FACILITY_SLOTBOOKING_FULLDAY = 'Full Day';
    public static final String FACILITY_STATUS_REJECTED = 'Rejected';
    public static final String FACILITY_STATUS_CANCELLED = 'Booking Canceled';
    
    
    /* FOR CASE */
    public static final String CASE_ASSIGNED = 'Assigned';
    public static final String CASE_WIP = 'wip';
    public static final String CASE_RESOLVED = 'resolved';
    
    /*String Values for TermCaluseHandller */
    public static final String NEGOTIATION_AGREED = 'Agreed';
    public static final String NEGOTIATION_DISAGREED = 'Disagreed';
    
    /*String Values for CalculationSheetController */
    public static final String VFPAGE_CALCULATIONSHEET = 'CalculationSheet';

    /*String Values for profileName */
    public static final String LEASING_PROFILE = 'Leasing Team Profile';
    public static final String BILLING_PROFILE = 'Leasing Billing Team';
    
    
}