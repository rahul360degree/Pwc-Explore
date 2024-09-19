import { LightningElement, track, wire, api } from "lwc";
import getProductsWithOffset from "@salesforce/apex/ProductSearchCtrl.getProductsWithOffset";
import setProductsasLines from "@salesforce/apex/ProductSearchCtrl.addProductsAsLines";
import checkForRecordLock from "@salesforce/apex/ProductSearchCtrl.checkForRecordLock";
import iconsW from "@salesforce/resourceUrl/icons";
import FORM_FACTOR from '@salesforce/client/formFactor';
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import PRODUCT_OBJECT from "@salesforce/schema/Product2";
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import PRODUCT_TYPE from "@salesforce/schema/Product2.Family";
import productSearchTemplate from "./productSearch.html";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Record_Locked_ErrorMessage from '@salesforce/label/c.Record_Locked';

//Search Delay
const DELAY = 300;

//Cart Columns
const optionColumns = [
  {
    label: "Product name",
    fieldName: "productName",
    type: "text",
    sortable: true
  },
  {
    label: "Quantity",
    fieldName: "quantity",
    type: "number",
    cellAttributes: { alignment: `left` },
    sortable: true
  }
];

const RECORD_OPEN = 'RECORD_OPEN';
const RECORD_LOCKED = 'RECORD_LOCKED';

export default class ProductSearch extends LightningElement {
  @track filterv = false;
  @track counter;
  //Inititator Record id for Product Search
  @api recordId;
  @api
  get initmodal() {
    return this.counter;
  }
  set initmodal(value) {
    this.counter = value;
  }
  @track data = [];
  //Icons
  addURL = iconsW + "/utility-sprite/svg/symbols.svg#add";
  chkURL = iconsW + "/utility-sprite/svg/symbols.svg#check";
  cartURL = iconsW + "/utility-sprite/svg/symbols.svg#cart";

  isSearchActive = false;

  @track isMobile = false;
  @track showCartScreen = false;
  @track isLoadingProducts;
  @track optionColumns = optionColumns;
  @track selectedRows = [];
  @track selection = [];
  // @track allSelectedRows = [];
  @track recordsCount = 0;
  //Pagination vars
  @track pageSize = 20;
  @track pageNumber = 1;
  @track isLastPage = true;
  @track resultSize = 0;
  @track hasPageChanged = false;
  @track initialLoad = true;
  @track error;
  //Filtering vars
  @track searchKey = "";
  @track filterProductType = "";
  @track filterItemCode = "";
  //Selection vars
  @track configurableProdList = [];
  @track selectedBaseProd = [];

  connectedCallback() {
    this.isLoadingProducts = true;
    if(FORM_FACTOR.toLowerCase() == 'small') {
      this.isMobile = true;
    }
    checkForRecordLock({recordId: this.recordId})
    .then(result => {
      if(result == RECORD_OPEN) {
        this.getData();
      } else if(result == RECORD_LOCKED) {
        this.showToast('Error', Record_Locked_ErrorMessage, 'error');
        this.closeEvent();
      }
    })
    .catch(error => {
      this.showToast('Error', error.body.message, 'error');
      this.closeEvent();
    });
  }

  getData() {
    getProductsWithOffset({
      whereClause: this.searchKey,
      pageSize: this.pageSize,
      pageNumber: this.pageNumber,
      fltrProductCode: this.filterItemCode,
      fltrProductType: this.filterProductType
    })
    .then(data => {
      let accountData = JSON.parse(JSON.stringify(data));

      if (accountData.length > 0) {
        if (accountData[0].hasMore) {
          this.isLastPage = false;
        } else {
          this.isLastPage = true;
        }
      } else if(accountData && accountData.length == 0) {
        // Disable the next page pagination button if there is no data to be displayed.
        this.isLastPage = true;
      }
      this.resultSize = accountData.length;

      // Append records to data if it's a mobile screen and user has not searched for any specific product
      if(this.isMobile && !this.isSearchActive) {
        let newData = this.data.concat([...accountData]);
        this.data = newData;
      } else {
        this.data = [...accountData];
        this.isSearchActive = false;
      }

      if (this.selectedRows.length > 0) {
        this.chkData();
      }
      console.log("Reached: ", data);
      this.isLoadingProducts = false;
    })
    .catch(error => {
      this.isLoadingProducts = false;
      this.error = error;
      this.showToast('Error', error.body.message, 'error');
      this.closeEvent();
    });
  }

  //Wired to Product Object to get the Picklist values used in filter
  @wire(getObjectInfo, { objectApiName: PRODUCT_OBJECT })
  objectInfo;

  @wire(getPicklistValues, {
    recordTypeId: "$objectInfo.data.defaultRecordTypeId",
    fieldApiName: PRODUCT_TYPE
  })
  IndustryPicklistValues;

  //Apex method ProductSearchCtrl.addProductsAsLines to push selected Products and process
  @track selectedProcessedProds = [];
  addProductsAsLines() {
    this.isLoadingProducts = true;
    setProductsasLines({
      pWrapperBaseProdList: this.selectedRows,
      recordId: this.recordId
    })
      .then((result) => {
        this.selectedProcessedProds = [...result];
        let isConfig = false;
        if (isConfig) {
          this.showConfigTemplate();
        }
        this.showToast('Success', 'Successfully created records', 'success');
      })
      .catch((error) => {
        window.console.log("error in setProductsasLines" + JSON.stringify(error));
        this.error = error;
        this.showToast('Error', error.body.message, 'error');
      })
      .finally(() => {
        this.isLoadingProducts = false;
        this.closeEvent();
      });
  }

  handleQuantityChange(event) {
    let quantity = event.detail.value;
    let productId = event.currentTarget.name;

    // Update page data
    const updatedProducts = this.data.map((e) => {
      if (e.product2Id == productId) {
        e.quantity = quantity;
      }
      return { ...e };
    });
    this.data = [...updatedProducts];

    // Update selected rows data if any are present
    if(this.selectedRows && this.selectedRows.length > 0) {
      const updatedSelectedProducts = this.selectedRows.map((row) => {
        if(row.product2Id == productId) {
          row.quantity = quantity;
        }
        return {...row};
      });

      this.selectedRows = [...updatedSelectedProducts];
    }
  }

  //Selected Products chk
  chkData() {
    for (let i = 0; i < this.selectedRows.length; i++) {
      const selectedProds = this.data.map((e) => {
        if (
          e.product2Id == this.selectedRows[i].product2Id &&
          this.selectedRows[i].isSelected
        ) {
          return { ...e, isSelected: true };
        } else {
          return { ...e };
        }
      });
      this.data = [...selectedProds];
    }
  }

  // Show cart screen
  displayCartScreen(event) {
    this.showCartScreen = true;
  }

  // To handle page navigation between cart and main screen for mobile devices
  navigateToPrevMobileScreen(event) {
    if(this.showCartScreen) {
      this.showCartScreen = false;
    } else {
      this.closeEvent();
    }
  }

  //Pagination
  loadMoreData(event) {
    this.nextEve();
  }

  previousEve() {
    this.isLoadingProducts = true;
    //Setting current page number
    let pageNumber = this.pageNumber;
    this.pageNumber = pageNumber - 1;
    //Setting pageChange variable to true
    this.hasPageChanged = true;
    // get the data
    this.getData();
  }

  //Pagination
  nextEve() {
    this.isLoadingProducts = true;
    //get current page number
    let pageNumber = this.pageNumber;
    //Setting current page number
    this.pageNumber = pageNumber + 1;
    //Setting pageChange variable to true
    this.hasPageChanged = true;
    // get the data
    this.getData();
  }

  //Pagination
  get recordCount() {
    return (
      (this.pageNumber - 1) * this.pageSize +
      " to " +
      ((this.pageNumber - 1) * this.pageSize + this.resultSize)
    );
  }

  //Pagination
  get disPre() {
    return this.pageNumber === 1 ? true : false;
  }

  //Chk Cart size
  get cartEm() {
    if (this.recordsCount > 0) {
      return false;
    } else {
      return true;
    }
  }

  //On Product Select
  handleBaseSelect(event) {
    let ob = event.target.dataset.pr;
    window.console.log("selected dataset: " + JSON.stringify(ob));

    let chk = true;

    const selectedProds = this.data.map((e) => {
      if (e.product2Id == event.target.dataset.pr) {
        if (e.isSelected == false) {
          chk = true;
          return { ...e, isSelected: true };
        } else {
          chk = false;
          return { ...e, isSelected: false };
        }
      } else {
        return { ...e };
      }
    });

    this.data = [...selectedProds];
    const selRows = this.data.find(
      (x) => x.product2Id == event.target.dataset.pr
    );

    if (chk) {
      this.selectedRows.push(selRows);
      this.selectedRows = [...this.selectedRows];
    } else {
      const filteredProds = this.selectedRows.filter(
        (item) => item.product2Id !== event.target.dataset.pr
      );
      this.selectedRows = [...filteredProds];
    }
    this.recordsCount = this.selectedRows.length;
    window.console.log("updated selectedRows" + JSON.stringify(this.selectedRows));
  }

  //Product Search
  handleChange(event) {
    window.clearTimeout(this.delayTimeout);
    const searchKey = event.target.value;
    this.delayTimeout = setTimeout(() => {
      this.isLoadingProducts = true;
      this.searchKey = searchKey;
      this.isSearchActive = true;
      // Reset the page number on mobile screens to 1 if the searchKey is empty
      if(this.isMobile && searchKey.length == 0) {
        this.pageNumber = 1;
      }
      this.getData();
    }, DELAY);
  }

  //Cart
  opennav() {
    this.template.querySelector(".sidenav").style.width = "300px";
  }
  closeNav() {
    this.template.querySelector(".sidenav").style.width = "0px";
  }

  //Filtering
  @track filterState = false;
  getFilters() {
    this.filterState = !this.filterState;
    if (this.filterState) {
      this.template
        .querySelector(".slds-panel_docked")
        .classList.add("slds-is-open");
    } else {
      this.template
        .querySelector(".slds-panel_docked")
        .classList.remove("slds-is-open");
    }
  }

  //Filtering
  setFilters() {
    if (
      this.template.querySelector(".fltrptype").value != null &&
      this.template.querySelector(".fltrptype").value
    ) {
      this.filterProductType = this.template.querySelector(".fltrptype").value;
      this.isLoadingProducts = true;
      this.getData();
    }
    if (
      this.template.querySelector(".fltrItemcode").value != null &&
      this.template.querySelector(".fltrItemcode").value
    ) {
      this.filterItemCode = this.template.querySelector(".fltrItemcode").value;
      this.isLoadingProducts = true;
      this.getData();
    }
  }

  //Filtering
  clearFilters() {
    this.filterProductType = "";
    this.template.querySelector(".fltrptype").value = "";
    this.filterItemCode = "";
    this.template.querySelector(".fltrItemcode").value = "";
    this.isLoadingProducts = true;
    this.getData();
  }

  //To display a secondary template - if required
  @track showTemplate = productSearchTemplate;
  render() {
    return this.showTemplate;
  }

  //To display a secondary template - if required
  showConfigTemplate() {
    //this.showTemplate = productConfigTemplate;
  }

  // Function to show toast message.
  showToast(title, message, variant) {
    this.dispatchEvent(
        new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        }),
    );
  }

  //Event after product selection - if required
  closeEvent() {
    this.dispatchEvent(new CustomEvent("close"));
  }
}