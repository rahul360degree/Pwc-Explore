/**
 * @description       : Helper class
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 06-10-2022
 * @last modified by  : vrajpoot@godrej.com
**/
public with sharing class QuoteApprovalHandler_Helper {
    public static boolean isAutoApproved_SSG_Regular(Pricing_approval_request__c par){
        Id userId = userInfo.getUserId();
        User user = [Select Id,Persona__c from User where Id = :userId];
        if(par.Requested_Customer_discount_max__c <=15){
            return true;
        }else if(user.Persona__c =='SSG- Territory Sales Manager' && par.Requested_Customer_discount_max__c <=20 ){
            return true;
        }else if(user.Persona__c =='SSG- Regional sales manager (Domestic )' && par.Requested_Customer_discount_max__c <= 30){
            return true;
        }else if(user.Persona__c =='SSG- National sales manager (Regular)' && par.Requested_Customer_discount_max__c <= 40){
            return true;
        }else if(user.Persona__c =='SSG- Sales & Marketing Head'){
            return true;
        }else{
            return false;
        }        
    }

    public static boolean isAutoApproved_SSG_Key(Pricing_approval_request__c par){
        Id userId = userInfo.getUserId();
        User user = [Select Id,Persona__c from User where Id = :userId];

        if(user.Persona__c =='SSG- Sales & Marketing Head'){
            return true;
        }
        else if(
            !(par.Dealer_Margin_Dealer_order__c > 15
                &&( (par.Scope_of_Installation__c=='Godrej' && par.Dealer_Margin_Dealer_order__c>6) || (par.Scope_of_Installation__c=='Dealer' && par.Dealer_Margin_Dealer_order__c>11) )
            )
        ){
            if(user.Persona__c =='SSG- Territory Sales Manager' && par.Requested_Customer_discount_max__c <=20 ){
                return true;
            }else if(user.Persona__c =='SSG- Regional sales manager (Domestic )' && par.Requested_Customer_discount_max__c <= 40){
                return true;
            }else{
                return false;    
            }
        }    
        else{
            return false;
        }     
    }


    public static boolean isAutoApproved_SSG_LCS(Pricing_approval_request__c par){
        Id userId = userInfo.getUserId();
        User user = [Select Id,Persona__c from User where Id = :userId];
        if(par.Requested_Customer_discount_max__c <=15){
            return true;
        }else if(user.Persona__c =='SSG- Territory Sales Manager' && par.Requested_Customer_discount_max__c <=20 ){
            return true;
        }else if(user.Persona__c =='SSG- Regional sales manager (Domestic )' && par.Requested_Customer_discount_max__c <= 25){
            return true;
        }else if(user.Persona__c =='SSG- National sales manager (Regular)' && par.Requested_Customer_discount_max__c <= 25){
            return true;
        }else if(user.Persona__c =='SSG- Sales & Marketing Head'){
            return true;
        }else{
            return false;
        }        
    }
}