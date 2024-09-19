/**
 * @description       : This component will display company information based on GSTN
 * @author            : Varun Rajpoot
 * @group             : 
 * @last modified on  : 12-07-2023
 * @last modified by  : Varun Rajpoot
**/
import { LightningElement, api, wire, track } from 'lwc';
import getcallout from "@salesforce/apex/GSTNCallout.getcallout";
import gstnCSS from '@salesforce/resourceUrl/GSTN';
import { loadStyle } from "lightning/platformResourceLoader";
import { getRecord } from 'lightning/uiRecordApi';
import Id from '@salesforce/user/Id';
//import BUSINESS_UNIT_FIELD from '@salesforce/schema/User.Business_Unit__c';
import getUserInfo from '@salesforce/apex/UserInfoController.getUserInfo';

export default class Companydetailbygstn extends LightningElement {
    @track company;
    @api company_archive;
    @api recordId;
    @api gstn;
    @api error;
    @api primary_bno;
    @api primary_flno;
    @api primary_loc;
    @api primary_st;
		@api primary_stcd;
    @api primary_pncd;
    @api gstn_name;
    @api gstn_registrationDate;
    @api primary_bnm;
    @api showSpinner = false;
    @api company_status;
    @api tradename;
    @api new_address;//Added by pankaj
    @api new_address_list = [];//Added by pankaj not in use
    @api new_bno;//Added by pankaj
    @api new_flno;//Added by pankaj
    @api new_bnm;//Added by pankaj
    @api new_loc;//Added by pankaj
    @api new_st;//Added by pankaj
    @api new_pncd;//Added by pankaj
    @api Business_Unit;//Added by pankaj
    @track error;//Added by pankaj
    @api addressList=[]; // Added by rohit 
    @api pinCodeList=[]; // Added by rohit
		
    connectedCallback() {				
        loadStyle(this, gstnCSS + '/GSTN.css')
            .then(() => {
                console.log('Files loaded');
            });

        this.handleSearch();
    }
		
		 //Added by pankaj to get Loggedin user details
		@wire(getUserInfo)
		wiredUserInfo({error,data}){
				if(data){						
						if(data.Business_Unit__c==='G'){
								this.Business_Unit = data.Business_Unit__c;	
								
						}											
				}
				else if(error){
						console.log(error);
				}
		}
		
    //find the company information based on GSTN
    handleSearch() {
        getcallout({ gstn: this.gstn })
            .then(result => {
                this.new_bno = result;
                this.company = JSON.parse(result);                
                if (this.company.status_code == 0 && (typeof this.company.error != undefined)) {
                    this.error = this.company.error;
                    this.showSpinner = true;
                    this.company = null;
                    //return;

                } else {
                    let counter = 0;                    
                    if (this.company && this.company.adadr) {
                        this.company.adadr.filter(v => {
                            v.addr.indexCount = counter;
                            counter++;
                            v.addr.isPrimary = false;
                            console.log('this.company.adadr',v);
                            console.log('this.company.adadr.addr.bno',v.addr.bno);
                            console.log('this.company.adadr.addr.bnm',v.addr.bnm);
                            console.log('this.company.adadr.addr.stcd',v.addr.stcd);
                            console.log('this.company.adadr.addr.flno',v.addr.flno);
                            console.log('this.company.adadr.addr.loc',v.addr.loc);
                            console.log('this.company.adadr.addr.st',v.addr.st);

                            let obj = {
                                sobjectType: 'Address__c',
                                Building__c: v.addr.st.substring(0, 30),
                                Street2__c: v.addr.bnm.substring(30),
                                Floor__c: v.addr.st.substring(30),
                                Unit__c: v.addr.loc,
                                Street__c: v.addr.bnm.substring(0, 30),
                                Pincode__c: v.addr.pncd,
                                StateName__c: v.addr.stcd                            
                            };
                            this.addressList.push(obj);
                            this.pinCodeList.push(v.addr.pncd);
                            
                            return v;
                        });
                    }

                    //end by pankaj
                    this.gstn_name = this.company.name;
                    this.gstn_registrationDate = this.company.registrationDate;
                    this.company_status = this.company.status;
                    this.tradename = this.company.tradename;
                    this.primaryAddressHelper();
                    this.showSpinner = true;
                }
            })
            .catch(error => {
                this.error = error;
                this.showSpinner = true;
            });


        /*
                    this.company = JSON.parse(this.testData());
                        this.gstn_name = this.company.name;
                        this.gstn_registrationDate = this.company.registrationDate;
                        this.company_status = this.company.status;
                        this.tradename = this.company.tradename;
                        this.primaryAddressHelper();
                        this.showSpinner = true;
                        */
    }

    // Setup primary address attributes
    primaryAddressHelper() {
        this.calloutHelper(this.company.pradr);
    }

    // Setup primary address attributes
    calloutHelper(primaryAddress) {
        this.primary_bno = primaryAddress.bno;
        this.primary_bnm = primaryAddress.bnm;
        this.primary_flno = primaryAddress.flno;
        this.primary_loc = primaryAddress.loc;
        this.primary_st = primaryAddress.st;
        this.primary_pncd = primaryAddress.pncd;
				this.primary_stcd = primaryAddress.stcd;
        console.log(this.primary_bno);
    }

    //update the primary address attributes
    primaryaddrchange(event) {
        let address_index = event.detail.addr.indexCount;
        this.company.adadr.filter(v => {
            v.addr.isPrimary = v.addr.indexCount == address_index ? true : false;
            return v;
        });
        this.calloutHelper(event.detail.addr);
    }

    additionaladdrchange(event) {
        let address_index = event.detail.addr.indexCount;
        this.company.adadr.filter(v => {
            v.addr.isPrimary = v.addr.indexCount == address_index ? true : false;
            return v;
        });
        this.calloutHelperNew(event.detail.addr);
    }

    calloutHelperNew(primaryAddress1) {
        this.new_bno = primaryAddress1.bno;
        this.new_bnm = primaryAddress1.bnm;
        this.new_flno = primaryAddress1.flno;
        this.new_loc = primaryAddress1.loc;
        this.new_st = primaryAddress1.st;        
        this.new_pncd = primaryAddress1.pncd;
        console.log(this.new_bno);        
    }

   
		
}