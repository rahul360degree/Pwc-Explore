/**
 * @description       : 
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 12-06-2022
 * @last modified by  : vrajpoot@godrej.com
**/
import { LightningElement,api } from 'lwc';

export default class CreatedealervisitInput extends LightningElement {
    @api apiname;
    @api value;
    @api paddingClass;
    @api increamentalValue=1;
    handleChangeEvent(event){        
        console.log(this.value);
        this.value = event.target.value?event.target.value:0;
        this.parseValueHelper();
        console.log(this.value);
        this.fireCustomEvent();
    }

    handleIncrement(){       
        if(typeof this.value ==undefined || isNaN(this.value)){
            this.value =  0;
        }else{
            this.value = parseInt(this.value);
        }
        this.value = this.value + this.increamentalValue;
        console.log(this.value);
        this.fireCustomEvent();
    }

    handleDecement(){
        if(typeof this.value ==undefined || isNaN(this.value)){
            this.value =  0;
        }else{
            this.value = parseInt(this.value);
        }
        
        if(this.value >0 && this.value > this.increamentalValue){
            this.value = this.value - this.increamentalValue;
        }else{
            this.value = 0;
        }
        this.fireCustomEvent();
    }

    parseValueHelper(){
        this.value = parseInt(this.value);
    }

    fireCustomEvent(){
        const arrayData = {fieldapi:this.apiname, value:this.value};
        const valueChange = new CustomEvent("valuechange",{
            detail:arrayData
        })
        this.dispatchEvent(valueChange);
    }
}