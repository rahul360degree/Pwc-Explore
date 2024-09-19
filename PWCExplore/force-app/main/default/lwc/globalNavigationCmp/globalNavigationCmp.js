import { LightningElement } from 'lwc';
import { NavigationMixin } from "lightning/navigation";

export default class GlobalNavigationCmp extends NavigationMixin (LightningElement) {

    connectedCallback(){
      console.log('before navigation');
      // this.navigateToObjectHome();
      console.log('after navigation');
    }


    navigateToObjectHome() {
        console.log('button clicked ');
        // Navigate to the Case object home page.
        this[NavigationMixin.Navigate]({

          type: "standard__webPage",
          attributes: {
            url: 'https://gnb--pwcexplore.sandbox.lightning.force.com/one/one.app#search?searchTerm=789999'
          }

        });
    }
}