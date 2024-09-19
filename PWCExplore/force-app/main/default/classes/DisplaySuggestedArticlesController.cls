/*------------------------------------------------------------------------
Author:        Amit Shingavi
Company:       Salesforce
Description:   Display Knowledge Articles 
Inputs:        
Test Class:    DisplaySuggestedArticlesControllerTest

History
28-12-2019      Amit Shingavi    Initial Release
----------------------------------------------------------------------------*/

public with sharing class DisplaySuggestedArticlesController {

    /*-----------------------------------------------------------------------------------
    Author:        Amit Shingavi 
    Description:   Method to pull the article list
    -------------------------------------------------------------------------------------
    History
    28-12-2019      Amit     Initial Release
    -------------------------------------------------------------------------------------*/
    @AuraEnabled(cacheable=true)
    public static List<KnowledgeArticle> getArticles(string caseId) {
        List<Case> caseLst = [SELECT Id, Subject FROM Case WHERE Id =: caseId];
        
        string fieldName = [SELECT Id,Label,Value__c FROM Application_Settings__mdt WHERE Label='Suggested Articles search fields'].get(0).Value__c;
        
        String qry = 'Select Id,'+fieldName+' FROM Case WHERE Id=\''+caseId+'\'';

        list<string> searchFields = new list<string>();


        for(case acct : Database.query(qry)){
            for(string s: fieldName.split(',')){
                searchFields.add(string.valueOf(acct.get(s)));
            }
        }


        string s1 = (String.join(searchFields,' OR '));

       
        List<List<SObject>> articles = [FIND :s1 
                                    RETURNING KnowledgeArticleVersion
                                    (Id, ArticleNumber,Summary,Title  
                                    WHERE PublishStatus='online' AND Language = 'en_US')];
        
        return articles[0];

    }   
    
    /*-----------------------------------------------------------------------------------
    Author:        Amit Shingavi 
    Description:   Method to create case articles based on the selected knowledg articles
    -------------------------------------------------------------------------------------
    History
    28-12-2019      Amit     Initial Release
    -------------------------------------------------------------------------------------*/
    @AuraEnabled
	public static Boolean createCaseArticle(List<Id> articleIds, Id caseId){
        Boolean savedResult = false;
       List<CaseArticle> articleLst = new List<CaseArticle>();
       
       try{
       for(KnowledgeArticleVersion idItr :[SELECT KnowledgeArticleId FROM KnowledgeArticleVersion WHERE Id IN: articleIds]){
           system.debug(idItr);
	   		articleLst.add(new CaseArticle(CaseId = caseId, KnowledgeArticleId = idItr.KnowledgeArticleId));
       }
       insert articleLst;
       savedResult = true;
       }catch(Exception  e){
            Logger.logError('DisplaySuggestedArticlesController', 'createCaseArticle', '', e);
       }   
       return savedResult;
    }

    /*-----------------------------------------------------------------------------------
    Author:        Mahith Madwesh
    Description:   Method to get case articles based on the search Term
    -------------------------------------------------------------------------------------
    History
    21-01-2021      Amit     Initial Release
    -------------------------------------------------------------------------------------*/
    @AuraEnabled
    public static List<KnowledgeArticle> getArticlesBySearch(string searchInput){

    string searchTerm = '%' + searchInput + '%';

    List<List<SObject>> articles = [FIND :searchTerm 
                                    RETURNING KnowledgeArticleVersion
                                    (Id, ArticleNumber,Summary,Title  
                                    WHERE PublishStatus='online' AND Language = 'en_US')];
        
        return articles[0];
        
    }
}