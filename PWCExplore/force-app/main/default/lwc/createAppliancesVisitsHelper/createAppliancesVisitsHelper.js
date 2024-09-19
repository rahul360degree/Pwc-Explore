/**
 * @Description       : 
 * @Author            : Varun Rajpoot
 * @last modified on  : 10-11-2023
 * @last modified by  : Varun Rajpoot
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   09-26-2023   Varun Rajpoot   Initial Version
**/
import { LightningElement,api,track } from 'lwc';

export default class CreateAppliancesVisitsHelper extends LightningElement {
    @api week;
    @api holiday;
    @track isHoliday;
    @track tdClass;
    @api startDay;
    @api rowIndex;
    connectedCallback(){
        this.applyCSS();
        this.holiday = JSON.parse(JSON.stringify(this.holiday));
        console.log(this.startDay);
    }
    handleHoliday(event){
        let holidayValue = parseInt(event.currentTarget.dataset.id);
        if(holidayValue <= parseInt(this.startDay)){
            return;
        }
        // if include holiday then remove else add to holiday list
        if(this.holiday.includes(holidayValue)){
            this.holiday = this.holiday.filter(v=>{
                    if(v != holidayValue){
                        return v;
                    };
            });
        }else{
            this.holiday.push(holidayValue);
        }

         this.dispatchEvent(new CustomEvent('dayclick', {
             detail: {'holiday':this.holiday}
         }));
    
        this.applyCSS();

    }

    applyCSS(){
        if(this.holiday.includes(this.week)){
            this.isHoliday = true;
            this.tdClass = 'holiday commonCSS';
        }else if(parseInt(this.rowIndex)===1){
            this.tdClass = 'dayCSS commonCSS';
        }
        else{
            this.isHoliday = false;
            this.tdClass = 'non-holiday commonCSS';
        }
    }

}