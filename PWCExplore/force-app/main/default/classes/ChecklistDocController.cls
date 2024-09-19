public without sharing class ChecklistDocController {
    public class ChecklistDocException extends Exception {} 

    public class fieldWrapper{
        public String label{get;set;}
        public Object value{get;set;}
        public String type{get;set;}
        public String apiName{get;set;}
        
        public fieldWrapper(String label, String type, String apiName)
        {
            this.label = label;
            this.type = type;
            this.apiName = apiName;
            if(String.isNotBlank(type) && type.equalsIgnoreCase('REFERENCE') && label.contains(' ID'))
                this.label = label.removeEnd(' ID');

        }
    }
    
    public class pcWrapper{
        public String Logo_Static{get;set;}
        public String Title{get;set;}
        public String Logo_Field{get;set;}
        public String Address_Field{get;set;}
        public String Footer_text{get;set;}
        public String Customer_Name_Field{get;set;}
        public String Time_Entry_Name_Field{get;set;}
        public String Feedback_Remarks_Field{get;set;}
        public String Feedback_Rating_Field{get;set;}
        
        public pcWrapper(Service_Form_PDF__mdt primaryConfig)
        {
            this.Logo_Static = primaryConfig.Logo_Static__c;
            this.Title = primaryConfig.Title__c;
            this.Logo_Field = primaryConfig.Logo_Field__c;
            this.Address_Field = primaryConfig.Address_Field__c;
            this.Footer_text = primaryConfig.Footer_text__c;
            this.Customer_Name_Field = primaryConfig.Customer_Name_Field__c;
            this.Time_Entry_Name_Field = primaryConfig.Time_Entry_Name_Field__c;
            this.Feedback_Remarks_Field = primaryConfig.Feedback_Remarks_Field__c;
            this.Feedback_Rating_Field = primaryConfig.Feedback_Rating_Field__c;

        }
    }

    
    public static ID checklistId{get;set;}
    public static SObject  checklistVar{get;set;}
    public static Map<String, Service_Form_PDF__mdt> configMap;
    public static Service_Form_PDF__mdt primaryConfig{get;set;}
    public static pcWrapper primaryConfigW{get;set;}
    public static Map<String, List<fieldWrapper>> sectionsWithFields{get;set;}
    public static List<String> sectionsList{get;set;}
    public static Integer SizeOfMap{get;set;}
    public static Set<String> allFields;
    public static Map<ID, SObject> secondaryForms;
    public static Map<ID, SObject> serviceFormMap{get;set;}
    public static Map<ID, SObject> signatureMap{get;set;}
    public static List<ID> signatureList{get;set;}
    
    public static Integer SizeOfTEMap{get;set;}
    public static Map<String, List<fieldWrapper>> timeEntrySectionsWithFields{get;set;}
    public static List<String> timeEntrySectionList{get;set;}
    public static Map<ID, SObject> timeEntryMap{get;set;}


    public ChecklistDocController(ApexPages.StandardController stdController) {
         checklistId = (ID)stdController.getRecord().get('id');
        
         if(String.isNotBlank(checklistId)){
         configMap = new Map<String, Service_Form_PDF__mdt>();
         secondaryForms = new Map<ID, SObject>();
         sectionsWithFields = new Map<String, List<fieldWrapper>>();
         allFields = new Set<String>();
         serviceFormMap = new Map<ID, SObject>();
         signatureMap = new Map<ID, SObject>();
         signatureList = new List<ID>();
                     
         getServiceFormConfigurations();
         getChecklistRecord();        
         getCheckListSections();
         getSecondaryCheckListSections();
         SizeOfMap = sectionsWithFields.size();
         sectionsList = new List<String>(sectionsWithFields.keySet());
         queryFields();
         getSignature();
        
         timeEntrySectionsWithFields = new Map<String, List<fieldWrapper>>();
         timeEntrySectionList = new List<String>();
         timeEntryMap = new Map<ID, SObject>();
         SizeOfTEMap = 0;
         getTimeEntries();
         SizeOfTEMap = timeEntrySectionsWithFields.size();
         timeEntrySectionList = new List<String>(timeEntrySectionsWithFields.keySet());
         }
    }
    
    public static void getChecklistRecord()
    {
        String sQuery = 'SELECT ID, RecordType.DeveloperName FROM ' + System.Label.Default_Object_API_Name
                         + ' WHERE ID = :checklistId';
        checklistVar = Database.query(sQuery);
        string rec = (String)checklistVar.getSObject('RecordType').get('DeveloperName');
        if(configMap.get(rec) == NULL)
        {
            throw new ChecklistDocException(System.Label.ConfigError);
        }
        primaryconfig = configMap.get(rec);
        System.debug('Primary Config : '+ primaryconfig);
        allFields.add(primaryconfig.Customer_Name_Field__c ); 
        if(String.isNotBlank(primaryconfig.Logo_Field__c)){
           allFields.add(primaryconfig.Logo_Field__c ); 
        }
        if(String.isNotBlank(primaryconfig.Address_Field__c )){
           allFields.add(primaryconfig.Address_Field__c ); 
        }
        if(String.isNotBlank(primaryconfig.Feedback_Rating_Field__c  )){
           allFields.add(primaryconfig.Feedback_Rating_Field__c  ); 
        }
        if(String.isNotBlank(primaryconfig.Feedback_Remarks_Field__c  )){
           allFields.add(primaryconfig.Feedback_Remarks_Field__c  ); 
        }


		primaryConfigW = new ChecklistDocController.pcWrapper(primaryconfig);
    }
    
    public static void getServiceFormConfigurations()
    {
       /* List<Service_Form_PDF__mdt> configList = new List<Service_Form_PDF__mdt>([SELECT DeveloperName,
                                                                                            Title__c,
                                                                                            Service_Form_Field_Sets__c,
                                                                                            Secondary_Field_Sets__c,
                                                                                            Logo_Static__c,
                                                                                            Logo_Field__c,
                                                                                            Service_Form_RecordType__c,
                                                                                            Object_API_Name__c,
                                                                                            Customer_Name_Field__c,
                                                                                            Merge_Other_Forms__c,
                                                                                            Parent_ID__c,
                                                                                            Footer_text__c,
                                                                                            Address_Field__c,
                                                                                  			Time_Entry_API_Name__c,
                                                                                  			Time_Entry_Parent_ID__c,
                                                                                  			Time_Entry_Field_Set__c,
                                                                                  			Time_Entry_Name_Field__c,
                                                                                            Feedback_Rating_Field__c,
                                                                                            Feedback_Remarks_Field__c
                                                                                  FROM Service_Form_PDF__mdt LIMIT 49999]); */
        List<Service_Form_PDF__mdt> configList = Service_Form_PDF__mdt.getAll().values();
        if(!configList.isEmpty())
        {
            for(Service_Form_PDF__mdt sfc : configList)
            {
                configMap.put(sfc.Service_Form_RecordType__c , sfc);
            }
        }
    }
    
    
    public static void getCheckListSections()
    {
        Schema.DescribeSObjectResult DescribeSObjectResultObj = getDescribe(primaryConfig.Object_API_Name__c);
        if(String.isNotBlank(primaryConfig.Service_Form_Field_Sets__c))
        {
            List<String> fieldSetList = primaryConfig.Service_Form_Field_Sets__c.split(',');
            if(String.isNotBlank(primaryConfig.Secondary_Field_Sets__c)){
                fieldSetList.addAll(primaryConfig.Secondary_Field_Sets__c.split(','));
            }
            for(String fieldSetDevName : fieldSetList)
            {
                fieldSetDevName = fieldSetDevName.trim();
                Schema.FieldSet checklistFieldSet = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetDevName);
                if(checklistFieldSet <> NULL)
                {
                    List<Schema.FieldSetMember> checklistFields = checklistFieldSet.getFields();
                    //System.Debug(checklistFieldSet);
                    List<fieldWrapper> checklistFieldWs = new List<fieldWrapper>();
                    for(Schema.FieldSetMember fm : checklistFields)
                    {
                        checklistFieldWs.add(new ChecklistDocController.fieldWrapper(fm.getLabel(),String.ValueOf(fm.getType()),fm.getFieldPath()));
                        allFields.add(fm.getFieldPath());
                    }
                    sectionsWithFields.put(checklistFieldSet.getLabel()+'~'+checklistId,checklistFieldWs);
                }
            }
        }
    }
        
    public static void getSecondaryCheckListSections()
    {
        Schema.DescribeSObjectResult DescribeSObjectResultObj = getDescribe(primaryConfig.Object_API_Name__c);
        if((primaryConfig.Merge_Other_Forms__c == TRUE) && String.isNotBlank( primaryConfig.Parent_ID__c ))
        {
            
            //Query 1 : To get the parent ID on current record
            String sQuery = 'SELECT ID, RecordType.DeveloperName, '+ primaryConfig.Parent_ID__c + ' FROM ' + primaryConfig.Object_API_Name__c
                             + ' WHERE ID = :checklistId';
            checklistVar = Database.query(sQuery);
            String parentID = (String)checklistVar.get(primaryConfig.Parent_ID__c);
            String primaryFormRecordType = (String)checklistVar.getSObject('RecordType').get('DeveloperName');
            if(String.isNotBlank(parentID)){
                //Query 2 : To get other records under the same parent ID
                String s2Query = 'SELECT ID, RecordType.DeveloperName FROM ' + primaryConfig.Object_API_Name__c
                                + ' WHERE ' + primaryConfig.Parent_ID__c + '= :parentID'
                                + ' AND ID != :checklistId AND RecordType.DeveloperName != :primaryFormRecordType';
                secondaryForms = new Map<ID,SObject>(Database.query(s2Query));
            }
        }
        //If other forms were found against the Parent ID, add secondary sections only for those.
        if(secondaryForms.size()>0)
        {
            for(ID secondaryFormId : secondaryForms.keySet())
            {
                Service_Form_PDF__mdt secondaryFormConfig = new Service_Form_PDF__mdt();
                String secondaryFormRecordType = (String)secondaryForms.get(secondaryFormId).getSObject('RecordType').get('DeveloperName');
                secondaryFormConfig = configMap.get(secondaryFormRecordType);
                if( (secondaryFormConfig<>NULL) && String.isNotBlank(secondaryFormConfig.Secondary_Field_Sets__c))
                {
                    //Carry on gathering fieldsets against every secondary form
                    List<String> secfieldSetList = secondaryFormConfig.Secondary_Field_Sets__c.split(',');
    
                    for(String fieldSetDevName : secfieldSetList)
                    {
                        //System.debug('field set: '+ fieldSetDevName);
                        fieldSetDevName = fieldSetDevName.trim();
                        Schema.FieldSet checklistFieldSet = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetDevName);
                        if(checklistFieldSet <> NULL)
                        {
                            List<Schema.FieldSetMember> checklistFields = checklistFieldSet.getFields();
                            //System.Debug(checklistFieldSet);
                            List<fieldWrapper> checklistFieldWs = new List<fieldWrapper>();
                            for(Schema.FieldSetMember fm : checklistFields)
                            {
                                checklistFieldWs.add(new ChecklistDocController.fieldWrapper(fm.getLabel(),String.ValueOf(fm.getType()),fm.getFieldPath()));
                                allFields.add(fm.getFieldPath());
                            }
                            sectionsWithFields.put(checklistFieldSet.getLabel()+'~'+secondaryFormId,checklistFieldWs);
                        }
                    }

                }

            }
        }
    }

    public static void getTimeEntries()
    {
        Set<String> timeEntryAllFields = new Set<String>();
        if(String.isNotBlank(primaryConfig.Time_Entry_Field_Set__c) 
           && String.isNotBlank(primaryConfig.Time_Entry_API_Name__c )
           && String.isNotBlank(primaryConfig.Time_Entry_Parent_ID__c)
           && String.isNotBlank(primaryConfig.Time_Entry_Name_Field__c)
          )
        {
        	Schema.DescribeSObjectResult DescribeSObjectResultObj = getDescribe(primaryConfig.Time_Entry_API_Name__c);
            Schema.FieldSet timeEntryFieldSet = DescribeSObjectResultObj.FieldSets.getMap().get(primaryConfig.Time_Entry_Field_Set__c.trim());
            List<Schema.FieldSetMember> timeEntryFields = timeEntryFieldSet.getFields();
            List<fieldWrapper> timeEntryFieldWs = new List<fieldWrapper>();
            for(Schema.FieldSetMember fm : timeEntryFields)
            {
                timeEntryFieldWs.add(new ChecklistDocController.fieldWrapper(fm.getLabel(),String.ValueOf(fm.getType()),fm.getFieldPath()));
                timeEntryAllFields.add(fm.getFieldPath());
            }
            if(timeEntryAllFields.size()>0)
            {
                timeEntryAllFields.add('Id');
                timeEntryAllFields.add('Name');
                timeEntryAllFields.add(primaryConfig.Time_Entry_Name_Field__c);
            	List<String> te_allFieldsList = new List<String>(timeEntryAllFields);
                String tedynamicQ = 'SELECT ' + String.join(te_allFieldsList, ',') 
                                   	 + ' FROM ' + primaryConfig.Time_Entry_API_Name__c
                                     + ' WHERE ' + primaryConfig.Time_Entry_Parent_ID__c+ ' = :checklistId' ;
                System.Debug('Query :');
                System.Debug(tedynamicQ);
                timeEntryMap = new Map<ID, SObject>(Database.query(tedynamicQ));
                
                if(timeEntryMap.size()>0)
                {
                    for(ID te_ID : timeEntryMap.keyset() )
                    {
                      timeEntrySectionsWithFields.put(timeEntryFieldSet.getLabel()+'~'+te_ID,timeEntryFieldWs);
                    }
                }
            }
        }
    }
    
    
    public static Schema.DescribeSObjectResult getDescribe(String ObjectName)
    {
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();    
        return DescribeSObjectResultObj; 
    } 

    
    public void queryFields()
    {
        if(allFields.size()>0)
        {
            allFields.add('Id');
            allFields.add('Name');
            allFields.add('RecordType.Name');
            List<String> allFieldsList = new List<String>(allFields);
            
            List<ID> allRequiredForms = new List<ID>();
            allRequiredForms.add(checklistId);
            allRequiredForms.addAll(secondaryForms.keySet());
            
            String dynamicQ = 'SELECT ' + String.join(allFieldsList, ',') 
                               + ' FROM ' + primaryConfig.Object_API_Name__c
                               + ' WHERE Id IN :allRequiredForms' ;
            System.Debug('Query :');
            System.Debug(dynamicQ);
            serviceFormMap = new Map<ID, SObject>(Database.query(dynamicQ));

        }
    }
    
    public void getSignature(){
        String signatureprefix = System.Label.Signature_Prefix + '%';
        List<ID> allRequiredForms = new List<ID>();
        allRequiredForms.add(checklistId);
        allRequiredForms.addAll(secondaryForms.keySet());

        List<ContentDocumentLink> cdl = new List<ContentDocumentLink>([SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.LatestPublishedVersionId,
                                                                              ContentDocument.LatestPublishedVersion.Title, ContentDocument.CreatedDate
                                                                       FROM ContentDocumentLink 
                                                                       WHERE LinkedEntityId IN :allRequiredForms 
                                                                       AND ContentDocument.Title LIKE :signatureprefix 
                                                                       AND ContentDocument.LatestPublishedVersion.Is_System_Generated_Signature__c = TRUE
                                                                       ORDER BY ContentDocument.CreatedDate Desc]);
        if(!cdl.isEmpty())
        {
            for(ContentDocumentLink link : cdl)
            {
                if(!signatureMap.containsKey(link.LinkedEntityId)){
                    signatureMap.put(link.LinkedEntityId, link);
                }
            }
            if(signatureMap.size()>0)
                signatureList = new List<ID>(signatureMap.keySet());
        }
    }
    
    @AuraEnabled
    public static Boolean generatePDF(String serviceFormId, boolean isSaveDisabled) {
        try{
            List<Service_Form__c> caseRec = [Select Id,Case__c FROM Service_Form__c WHERE Id =: serviceFormId LIMIT 1];
            if(caseRec.size() > 0){
                // create a virtual page
                PageReference page = new PageReference('/apex/ChecklistDoc');
                // add our record id
                page.getParameters().put('id', serviceFormId);
        
                // generate and PDF blob
                // You can save this blob as a file, document, or attachment!
                Blob b;
                if(Test.isRunningTest()) {
                    b = blob.valueOf('Unit.Test');
                }else{
                    b = page.getContent();
                }
                String draftPrefix = System.Label.Draft_Prefix + serviceFormId + '_';
                //Delete the draft versions created
                if(isSaveDisabled == false){
                    String cmpVar = draftPrefix + '%';
                    List<ContentDocumentLink> draftCDL = new List<ContentDocumentLink>([SELECT Id,ContentDocumentId 
                                                                                        FROM ContentDocumentLink 
                                                                                        WHERE LinkedEntityId = :caseRec[0].Case__c
                                                                                        AND ContentDocument.Title LIKE :cmpVar ]);
                    if(!draftCDL.isEmpty()){
                        List<ContentDocument> docsToBeDeleted = new List<ContentDocument>();
                        for(ContentDocumentLink cdl : draftCDL){
                            docsToBeDeleted.add(new ContentDocument(id=cdl.ContentDocumentId));
                        }
                        delete docsToBeDeleted;
                    }
                }
                String docName = ( isSaveDisabled ? draftPrefix : '') + ChecklistDocController.getDocName(caseRec[0].Case__c);
                //Create Document
                ContentVersion cv = new ContentVersion();
                cv.Title =  docName ;
                cv.PathOnClient = docName +'.pdf';
                cv.VersionData = b;
                cv.IsMajorVersion = true;
                insert cv;
         
                //Get Content Documents
                Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
                
                //Create ContentDocumentLink 
                ContentDocumentLink cdl = New ContentDocumentLink();
                cdl.LinkedEntityId = caseRec[0].Case__c;
                cdl.ContentDocumentId = conDocId;
                cdl.shareType = 'V';
                insert cdl;
            }           
        }catch(Exception ex){
            System.debug('Exception :: ' +ex.getMessage());
            Logger.logError('ChecklistDocController', 'generatePDF', serviceFormId, ex);
            return false;
        }
        return true;
    }
    
    /*
     * Description : Returns the name for the PDF document
     * 				 * Uses the recordtype name for a checklist(pm/commissioning) - if available
     * 				 * In the absence of a checklist - label : SERVICE_FORM_PDF_NAME
     * 				 * Appends the datetime stamp
     */
    public static String getDocName(ID caseID) {
        String docName = System.Label.SERVICE_FORM_PDF_NAME;
        
        List<String> recTypes = new List<String>{GlobalConstants.SERVICE_FORM_PM1_RECORD_TYPE_DEV_NAME,
                                                 GlobalConstants.SERVICE_FORM_PM2_RECORD_TYPE_DEV_NAME,
                                                 GlobalConstants.SERVICE_FORM_COMMISSIONING_RECORD_TYPE_DEV_NAME};
                                                     
        List<Service_Form__c> checklist = new List<Service_Form__c>([Select Id,Recordtype.Name FROM Service_Form__c 
                                                                     WHERE Case__c = :caseID  
                                                                     AND Recordtype.DeveloperName IN :recTypes
                                                                     ORDER BY LastModifiedDate]);
        
        if(checklist.size()>0){
            docName = checklist[0].Recordtype.Name;
        }
        return (docName +' '+DateTime.now().format('dd_MM_yyyy hh_mm'));

    }
    
    @AuraEnabled
    public static Boolean disableSave(String serviceFormId) {
		Boolean returnVal = true;
        //check if signature is available
        String signatureprefix = System.Label.Signature_Prefix + '%';
        List<ContentDocumentLink> cdl = new List<ContentDocumentLink>([SELECT Id, LinkedEntityId
                                                                       FROM ContentDocumentLink 
                                                                       WHERE LinkedEntityId = :serviceFormId 
                                                                       AND ContentDocument.Title LIKE :signatureprefix 
                                                                       AND ContentDocument.LatestPublishedVersion.Is_System_Generated_Signature__c = TRUE]);
        List<Service_Form__c> sfl = new List<Service_Form__c>([Select Id from Service_Form__c 
                                                               WHERE ID = :serviceFormId 
                                                               AND Status__c = :GlobalConstants.SERVICE_FORM_STATUS_SUBMITTED]);
        if(cdl.size()>0 && sfl.size()>0)
        {
            returnVal = false;
        }
        System.Debug('returnVal : '+returnVal);
        return returnVal;
    }



}