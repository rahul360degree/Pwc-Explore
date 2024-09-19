import { LightningElement, track } from 'lwc';  
 export default class AssetLookup extends LightningElement {  
   @track assetName;  
   @track assetRecordId;  

   onAssetSelection(event){  
   this.assetName = event.detail.selectedValue;  
   this.assetRecordId = event.detail.selectedRecordId;  
   }  
 }