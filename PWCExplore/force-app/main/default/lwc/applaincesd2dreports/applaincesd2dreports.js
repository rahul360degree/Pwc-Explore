/**
 * @description       : 
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 11-02-2022
 * @last modified by  : vrajpoot@godrej.com
**/
import { LightningElement,track } from 'lwc';
import getReports from'@salesforce/apex/AppliancesPartnerReport.getReports'
import { NavigationMixin } from 'lightning/navigation';
export default class Applaincesd2dreports  extends NavigationMixin(LightningElement){
    @track folderWithReport=[];
    connectedCallback(){
        this.fetchReports();        
    }

    fetchReports(){
        getReports()
        .then(records=>{
            let folderMap = new Map();
            if(records){
                for(var rec of records){
                    let reportRecords = [];
                    const folderName = rec.FolderName?rec.FolderName:'Common';
                    if(folderMap && folderMap.get(folderName)){
                        reportRecords = folderMap.get(folderName);
                    }
                    reportRecords.push(rec);
                    folderMap.set(folderName,reportRecords);
                }

                for(const [key,value] of folderMap){
                    this.folderWithReport.push({
                        'folderName' : key,
                        "reports":value
                    });
                }
                
                console.log(this.folderWithReport);


            }
        })
        .catch(error=>{
            console.log(error);
        })
    }
    displayReport(event){
        this[NavigationMixin.GenerateUrl]({
            type: "standard__recordPage",
            attributes: {
                recordId: event.currentTarget.dataset.id,
                objectApiName: 'Report',
                actionName: 'view'
            }
        }).then(url => {
            window.open(url, "_blank");
        });
    }
}