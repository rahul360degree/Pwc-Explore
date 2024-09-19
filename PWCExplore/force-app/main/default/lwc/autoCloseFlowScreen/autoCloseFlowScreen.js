/**
 * @description       : This component will close flow screen automatically.
 * @author            : meshramp@godrej.com
 * @group             : 
 * @last modified on  : 28-06-2023
 * @last modified by  : meshramp@godrej.com
 * Component used in  : Order_Sync_To_Infor_Flow
**/
import { LightningElement } from 'lwc';
import { FlowNavigationFinishEvent } from 'lightning/flowSupport';
export default class AutoCloseFlowScreen extends LightningElement {
		connectedCallback(){
				setTimeout(() =>{
				const finishEvent = new FlowNavigationFinishEvent('FINISHED');
				this.dispatchEvent(finishEvent);
				},3000);
		}
}