/**
     * @description       : Used to prepare the formdata to make PC callout
     * @author            : Varun Rajpoot
     * @group             : 
     * @last modified on  : 11-06-2023
     * @last modified by  : Varun Rajpoot
    **/
export class splitCalloutClass {
  static handleCallout(result, selectedRows, attachMap, po_atobData, ho_atobData, supplier_atobData, sfQuotationPos) {
    let vertical='';
    if(result && result.quoteRec && result.quoteRec.Segment__c){
      if(result.quoteRec.Segment__c ==='Commercial'){
        vertical = 'COMC';
      }else if(result.quoteRec.Segment__c ==='Government'){
        vertical = 'GOVC';
      }else if(result.quoteRec.Segment__c ==='Hospitality'){
        vertical = 'HSPLTY';
      }else if(result.quoteRec.Segment__c ==='Key Accounts'){
        vertical = 'KAM';
      }else if(result.quoteRec.Segment__c ==='Logistics'){
        vertical = 'LOGIST';
      }else if(result.quoteRec.Segment__c ==='OEM'){
        vertical = 'OEM';
      }else if(result.quoteRec.Segment__c ==='Others'){
        vertical = 'OTH';
      }else if(result.quoteRec.Segment__c ==='Real Estate'){
        vertical = 'REALST';
      }else{
        vertical = result.quoteRec.Segment__c;
      }
    }
    var formdata = new FormData();
    formdata.append("customerCode", result.quoteRec.Account.Account_Code__c);
    formdata.append("billingAddress", result.quoteRec.Invoice_To_Address__r.Address_Code_Formula__c);
    formdata.append("deliveryAddress", result.quoteRec.Ship_To_Address__r.Address_Code_Formula__c);
    formdata.append("deliveryType", result.quoteRec.Delivery_Type__c);
    formdata.append("customerOrderNumber", result.quoteRec.Customer_Order_No__c ? result.quoteRec.Customer_Order_No__c : '');
    formdata.append("vertical", vertical);
    formdata.append("branchWarehouse", result.quoteRec.Branch_Locks_B2B__c);
    formdata.append("customerExpDelDate", result.quoteRec.Expected_Date_of_Delivery__c);
    let aidNumber = (result.quoteRec.Influencer__c && result.quoteRec.Influencer__r.Account_Code__c) ? result.quoteRec.Influencer__r.Account_Code__c : '';
    if (result.quoteRec.OEM__c && result.quoteRec.OEM__r.Name) {
      aidNumber += aidNumber ? '/' : '';
      aidNumber += result.quoteRec.OEM__r.Name;
    }
    formdata.append("aidNumber", aidNumber);
    formdata.append("commentsHO", result.quoteRec.Remarks__c);
    formdata.append("commentsMFG", result.quoteRec.Special_remarks__c);
    formdata.append("user", result.userId);
    formdata.append("channel", result.quoteRec.Channel__c);
    formdata.append("sfQuotationID", result.quoteRec.QuoteNumber);
    formdata.append("sfQuotationPos", sfQuotationPos);
    formdata.append("productDetails", result.lineItemData);

    if (attachMap.get('PO')) {
      let poData = attachMap.get('PO');
      let filename = poData.ContentDocument.LatestPublishedVersion.Title + '.' + poData.ContentDocument.LatestPublishedVersion.FileExtension;
      let mimetype = splitCalloutClass.getmimeType(poData.ContentDocument.LatestPublishedVersion.FileExtension);
      let blobData = splitCalloutClass.blobData(mimetype, po_atobData);
      formdata.append("Attachment1HOName", filename);
      formdata.append("Attachment1HOType", mimetype);
      formdata.append("Attachment1HOSize", "4000");
      formdata.append("Attachment1HO", blobData, "testfile.pdf");

    }

    if (attachMap.get('HO')) {
      let hoData = attachMap.get('HO');
      let filename = hoData.ContentDocument.LatestPublishedVersion.Title + '.' + hoData.ContentDocument.LatestPublishedVersion.FileExtension;
      let mimetype = splitCalloutClass.getmimeType(hoData.ContentDocument.LatestPublishedVersion.FileExtension);
      let blobData = splitCalloutClass.blobData(mimetype, ho_atobData);
      formdata.append("Attachment2HOName", filename);
      formdata.append("Attachment2HOType", mimetype);
      formdata.append("Attachment2HOSize", "4000");
      formdata.append("Attachment2HO", blobData, "testfile.pdf");
    }

    if (attachMap.get('Supplier')) {
      let supplierData = attachMap.get('Supplier');
      let filename = supplierData.ContentDocument.LatestPublishedVersion.Title + '.' + supplierData.ContentDocument.LatestPublishedVersion.FileExtension;
      let mimetype = splitCalloutClass.getmimeType(supplierData.ContentDocument.LatestPublishedVersion.FileExtension);
      let blobData = splitCalloutClass.blobData(mimetype, supplier_atobData);
      formdata.append("AttachmentSupplierName", filename);
      formdata.append("AttachmentSupplierType", mimetype);
      formdata.append("AttachmentSupplierSize", "4000");
      formdata.append("AttachmentSupplier", blobData, "testfile.pdf");
    }
    formdata.append("", "");

    let token = result.accessToken;
    var requestOptions = {
      method: 'POST',
      headers: {
        'X-Skip-Encryption': '',
        'Authorization': 'Bearer ' + token,
        'mode': 'no-cors'
      },
      'X-Skip-Encryption': '',
      'Authorization': 'Bearer ' + token,
      body: formdata,
      redirect: 'follow'

    };
      return requestOptions;
      console.log('Exit splitCalloutClass.handleCallout');
  }

  //get the MIME type
  static getmimeType(fileType) {
    let mimeType;
    if (fileType.toLowerCase() == 'png') {
      mimeType = 'image/png';
    } else if (fileType.toLowerCase() == 'jpg' || fileType.toLowerCase() == 'jpeg') {
      mimeType = 'image/jpg';
    } else if (fileType.toLowerCase() == 'pgm') {
      mimeType = 'image/x-portable-graymap';
    } else if (fileType.toLowerCase() == 'ppm') {
      mimeType = 'image/x-portable-pixmap';
    } else if (fileType.toLowerCase() == 'pdf') {
      mimeType = 'application/pdf';
    } else if (fileType.toLowerCase() == 'msg') {
      mimeType = 'application/vnd.ms-outlook';
    } else if (fileType.toLowerCase() == 'eml') {
      mimeType = 'message/rfc822';
    }
    return mimeType;
  }

//prepare the array for the blob
  static blobData(mimeType, versiondata) {
    var sliceSize = 1024;
    var byteCharacters = versiondata;
    var bytesLength = byteCharacters.length;
    var slicesCount = Math.ceil(bytesLength / sliceSize);
    var byteArrays = new Array(slicesCount);
    for (var sliceIndex = 0; sliceIndex < slicesCount; ++sliceIndex) {
      var begin = sliceIndex * sliceSize;
      var end = Math.min(begin + sliceSize, bytesLength);

      var bytes = new Array(end - begin);
      for (var offset = begin, i = 0; offset < end; ++i, ++offset) {
        bytes[i] = byteCharacters[offset].charCodeAt(0);
      }
      byteArrays[sliceIndex] = new Uint8Array(bytes);
    }
    return new Blob(byteArrays, { type: mimeType });
  }



}