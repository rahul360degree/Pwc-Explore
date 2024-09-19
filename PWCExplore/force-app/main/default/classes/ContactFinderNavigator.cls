public with sharing class ContactFinderNavigator {
    
    // public ContactFinderNavigator() {
    //     System.debug('param '+System.currentPageReference().getParameters());
    //     String callerNumber = System.currentPageReference().getParameters().get('contNum');
    //     System.debug('contact number '+callerNumber);

    //     List<Contact> b2bContactLst = [ SELECT Id, LastName, AccountId FROM Contact WHERE Phone=:callerNumber OR MobilePhone =:callerNumber ];
        
    //     // for(){

    //     // }

    //     //PersonAccounts
    //     List<Account>  b2cCustomerLst = [  SELECT Id, PersonMobilePhone, Mobile_Number__c, Mobile_Number_of_ASP_Supervisor__c, 
    //                                         Primary_Contact_Mobile__c, Whatsapp_Mobile_Number__c, IsPersonAccount
    //                                     FROM Account 
    //                                     WHERE  PersonMobilePhone =:callerNumber
    //                                 ];


    //     if( b2cCustomerLst.size() > 0 && b2cCustomerLst.size() == 1 ){
    //         String tRcrdId = b2cCustomerLst[0].Id;
    //         // window.parent.location = '/' + tRcrdId;
    //         String fullFileURL = URL.getOrgDomainURL().toExternalForm() + '/' + tRcrdId;
    //         // Window.open(fullFileURL);
    //         // PageReference pageRef = new PageReference(fullFileURL);
    //         // https://MyDomainName--PackageName.vf.force.com/apex/mySecondPage
    //     } else if( b2cCustomerLst.size() > 1 ){


    //     } else{


    //     }

    //     // if( conLst.size() > 0 && conLst.size() == 1){
    //     //     //Single unique Contact found


    //     // }   else if( conLst.size() > 1){
    //     //     //Multiple contact found


    //     // } else {
    //     //     //Contact create page - default page. 
    //     // }

    //     System.debug('after contact search ');
    // }


    // Redirect users to the self-service help site    
    public PageReference redirect() {

        String callerNumber = System.currentPageReference().getParameters().get('mobileNum');
        System.debug('contact number '+callerNumber);

        //Bussiness Account B2B
        List<Contact> b2bContactLst = [ SELECT Id, LastName, AccountId FROM Contact WHERE Phone=:callerNumber OR MobilePhone =:callerNumber ];
        

        // var searchterm = '8946862348';
        // var stringToEncode = '{"componentDef":"forceSearch:search","attributes":{"term":"'+searchterm+'","scopeMap":{"resultsCmp":"forceSearch:resultsTopResults","label":"Top Results","type":"TOP_RESULTS","cacheable":"Y","id":"TOP_RESULTS","labelPlural":"Top Results"},"context":{"disableSpellCorrection":false,"SEARCH_ACTIVITY":{"term":1234567890}}},"state":{}}';         
        
        //  var Base64={_keyStr:"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",encode:function(e){var t="";var n,r,i,s,o,u,a;var f=0;e=Base64._utf8_encode(e);while(f<e.length){n=e.charCodeAt(f++);r=e.charCodeAt(f++);i=e.charCodeAt(f++);s=n>>2;o=(n&3)<<4|r>>4;u=(r&15)<<2|i>>6;a=i&63;if(isNaN(r)){u=a=64}else if(isNaN(i)){a=64}t=t+this._keyStr.charAt(s)+this._keyStr.charAt(o)+this._keyStr.charAt(u)+this._keyStr.charAt(a)}return t},decode:function(e){var t="";var n,r,i;var s,o,u,a;var f=0;e=e.replace(/[^A-Za-z0-9+/=]/g,"");while(f<e.length){s=this._keyStr.indexOf(e.charAt(f++));o=this._keyStr.indexOf(e.charAt(f++));u=this._keyStr.indexOf(e.charAt(f++));a=this._keyStr.indexOf(e.charAt(f++));n=s<<2|o>>4;r=(o&15)<<4|u>>2;i=(u&3)<<6|a;t=t+String.fromCharCode(n);if(u!=64){t=t+String.fromCharCode(r)}if(a!=64){t=t+String.fromCharCode(i)}}t=Base64._utf8_decode(t);return t},_utf8_encode:function(e){e=e.replace(/rn/g,"n");var t="";for(var n=0;n<e.length;n++){var r=e.charCodeAt(n);if(r<128){t+=String.fromCharCode(r)}else if(r>127&&r<2048){t+=String.fromCharCode(r>>6|192);t+=String.fromCharCode(r&63|128)}else{t+=String.fromCharCode(r>>12|224);t+=String.fromCharCode(r>>6&63|128);t+=String.fromCharCode(r&63|128)}}return t},_utf8_decode:function(e){var t="";var n=0;var r=c1=c2=0;while(n<e.length){r=e.charCodeAt(n);if(r<128){t+=String.fromCharCode(r);n++}else if(r>191&&r<224){c2=e.charCodeAt(n+1);t+=String.fromCharCode((r&31)<<6|c2&63);n+=2}else{c2=e.charCodeAt(n+1);c3=e.charCodeAt(n+2);t+=String.fromCharCode((r&15)<<12|(c2&63)<<6|c3&63);n+=3}}return t}}

        // var searchcriteria = Base64.encode(stringToEncode);
        
        
        //redirect to the new URL
        //window.location.href='/one/one.app?source=alohaHeader#'+searchcriteria;

        // return new PageReference('/one/one.app?source=alohaHeader#'+searchcriteria);

        if( b2bContactLst.size() > 0 && b2bContactLst.size() == 1 ){
            String tRcrdId = b2bContactLst[0].AccountId;
            
            // return new PageReference('/apex/GlobalSearchPage?searchTerms='+callerNumber);
            return new PageReference('/'+tRcrdId);
            
            // window.parent.location = '/' + tRcrdId;
            // String fullFileURL = URL.getOrgDomainURL().toExternalForm() + '/' + tRcrdId;
            // Window.open(fullFileURL);
            // PageReference pageRef = new PageReference(fullFileURL);
            // https://MyDomainName--PackageName.vf.force.com/apex/mySecondPage
        } else if( b2bContactLst.size() > 1 ){
            //Global Serch result output

        } else{
            //Stay on Home page 
            //What will be the home page for the agent?

        }


        //PersonAccounts B2C
        List<Account>  b2cCustomerLst = [  SELECT Id, PersonMobilePhone, Mobile_Number__c, Mobile_Number_of_ASP_Supervisor__c, 
                                            Primary_Contact_Mobile__c, Whatsapp_Mobile_Number__c, IsPersonAccount
                                        FROM Account 
                                        WHERE  PersonMobilePhone =:callerNumber
                                    ];

        //Can be alternate number
        List<ContactPointPhone> b2cContactPoint = [ SELECT Id, ParentId FROM ContactPointPhone WHERE TelephoneNumber =:callerNumber ];

        System.debug('b2b '+b2bContactLst.size() + ' b2c '+b2cCustomerLst.size());
        final PageReference target ;
        if( b2cCustomerLst.size() > 0 && b2cCustomerLst.size() == 1 ){
            String tRcrdId = b2cCustomerLst[0].Id;
            // target = new
            // return new PageReference('/apex/GlobalSearchPage?searchTerms='+callerNumber);
            return new PageReference('/'+tRcrdId);
            
            // window.parent.location = '/' + tRcrdId;
            // String fullFileURL = URL.getOrgDomainURL().toExternalForm() + '/' + tRcrdId;
            // Window.open(fullFileURL);
            // PageReference pageRef = new PageReference(fullFileURL);
            // https://MyDomainName--PackageName.vf.force.com/apex/mySecondPage
        } else if( b2cCustomerLst.size() > 1 ){
            //Global logic

        } else{
            //Stay on home page

        }

        return null;
        // final PageReference target = new
        // PageReference(Site.getBaseSecureUrl() + '/SiteLogin');
        // target.setRedirect(true);
        // // This is a permanent redirection
        // target.setRedirectCode(301);
        // return target;


        // Working for classic 
        // String searchQuery = '8870863386';
        // String encodedQuery = EncodingUtil.urlEncode(searchQuery, 'UTF-8');
        // // Construct the search URL
        // // String searchURL = '/_ui/search/ui/UnifiedSearchResults?str=' + encodedQuery;
        // String searchURL = '/lightning/o/search/ui/UnifiedSearchResults?str=' + encodedQuery;
        // // Redirect to the search results page
        // PageReference searchPage = new PageReference(searchURL);
        // searchPage.setRedirect(true);
        // return searchPage;


        // Replace 'searchQuery' with your actual search term
    //    String searchQuery = '8870863386';
    //    String encodedQuery = EncodingUtil.urlEncode(searchQuery, 'UTF-8');
    //    // Construct the search URL for Lightning Experience
    // //    String searchURL = '/lightning/o/GlobalSearch/results?searchString=' + encodedQuery;

    //     String searchURL = '/one/one.app#sObject/search?searchTerm=' + encodedQuery;
    //    // Redirect to the Lightning global search results page
    //    PageReference searchPage = new PageReference(searchURL);
    //    searchPage.setRedirect(true);
    //    return searchPage;

    
    }
}