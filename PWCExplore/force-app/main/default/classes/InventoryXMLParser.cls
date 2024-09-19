/*------------------------------------------------------------------------
Author:        Kartik Shetty
Company:       Salesforce
Description:   Utility class to perform parse XML response received from Infor after stock check for BDE approach.
Inputs:        NA
Test Class:    BDEInventoryExtenstionTest
History
15-10-2020      Kartik Shetty     Initial Release
----------------------------------------------------------------------------*/
public without sharing class InventoryXMLParser {
    public static BDEResponseMapper responseMapperObject;

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to generate XML request structure
    Inputs:        BDERequestMapper requestMapperObj
    Output:        Dom.Document
    History
    ----------------------------------------------------------------------------*/
    public Dom.Document generateXMLRequestStructure(BDERequestMapper requestMapperObj) {
        DOM.Document doc = new DOM.Document();
        
        String soapNS = 'http://schemas.xmlsoap.org/soap/envelope/';
        String inv = 'http://www.infor.com/businessinterface/InventoryVisibility_GB';
        String serviceNS = 'http://www.myservice.com/services/MyService/';
        
        DOM.XmlNode envelope = doc.createRootElement('Envelope', soapNS, 'soapenv');
        envelope.setNamespace('inv', inv);
        
        DOM.XmlNode header = envelope.addChildElement('Header', soapNS, null);
        header.addChildElement('Activation', inv, 'inv').addChildElement('company', null, null).addTextNode(requestMapperObj.company);

        DOM.XmlNode body = envelope.addChildElement('Body', soapNS, null);
        DOM.XmlNode showRequest = body.addChildElement('Show', inv, 'inv').addChildElement('ShowRequest', null, null);
        DOM.XmlNode inventoryVisibility = showRequest.addChildElement('DataArea', null, null).addChildElement('InventoryVisibility_GB', null, null);

        
        inventoryVisibility.addChildElement('OrganizationID', null, null).addTextNode(requestMapperObj.organizationId);

        DOM.XmlNode wareHouse = inventoryVisibility.addChildElement('Warehouse', null, null);
        if(requestMapperObj.warehouse != null) {
            wareHouse.addTextNode(requestMapperObj.warehouse);
        }

        DOM.XmlNode itemCode = inventoryVisibility.addChildElement('ItemCode', null, null);
        if(requestMapperObj.itemCode != null) {
            itemCode.addTextNode(requestMapperObj.itemCode);
        }

        DOM.XmlNode project = inventoryVisibility.addChildElement('Project', null, null);
        if(requestMapperObj.project != null) {
            project.addTextNode(requestMapperObj.project);
        }

        DOM.XmlNode company = inventoryVisibility.addChildElement('Company', null, null);
        if(requestMapperObj.company != null) {
            company.addTextNode(requestMapperObj.company);
        }
        
        return doc;
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Method to parse the XML string response and return it in a proper format.
    Inputs:        String XMLString
    Output:        BDEResponseMapper
    History
    ----------------------------------------------------------------------------*/
    public BDEResponseMapper parseXMLResponse(String XMLString) { 
        responseMapperObject = new BDEResponseMapper();
        DOM.Document doc = new DOM.Document();
        doc.load(XMLString);
        DOM.XmlNode rootNode = doc.getRootElement();
        
        parseXML(rootNode);
        return responseMapperObject;
    }

    /*------------------------------------------------------------------------
    Author:        Kartik Shetty
    Company:       Salesforce
    Description:   Recursive method to get the content from an XML node.
    Inputs:        DOM.XmlNode node
    Output:        
    History
    ----------------------------------------------------------------------------*/
    private void parseXML(DOM.XmlNode node) {
            System.debug('node.getName() '+node.getName()+' node.getText().trim() '+node.getText().trim());   //Added by Varun on 25-02-2022         
            if(node.getName() == 'OrganizationID') {
                responseMapperObject.OrganizationID = node.getText().trim();
            }
            else if(node.getName() == 'Itemcode') {
                responseMapperObject.Itemcode = node.getText().trim();
            }
            else if(node.getName() == 'ItemDescription') {
                responseMapperObject.Description = node.getText().trim();
            }
            else if(node.getName() == 'Project') {
                responseMapperObject.Project = node.getText().trim();
            }
            else if(node.getName() == 'Warehouse') {
                responseMapperObject.Warehouse = node.getText().trim();
            }
            else if(node.getName() == 'WarehouseDesc') {
                responseMapperObject.WarehouseDesc = node.getText().trim();
            }
            else if(node.getName() == 'WarehouseType') {
                responseMapperObject.WarehouseType = node.getText().trim();
            }
            else if(node.getName() == 'BusinessCode') {
                responseMapperObject.BusinessCode = node.getText().trim();
            }
            else if(node.getName() == 'BusinessName') {
                responseMapperObject.BusinessName = node.getText().trim();
            }
            else if(node.getName() == 'InvUnit') {
                responseMapperObject.InvUnit = node.getText().trim();
            }
            else if(node.getName() == 'Company') {
                responseMapperObject.Company = node.getText().trim();
            }
            else if(node.getName() == 'OnHandStock') {
                responseMapperObject.OnHandStock = node.getText().trim();
            }
            else if(node.getName() == 'FreeStock') {
                responseMapperObject.FreeStock = node.getText().trim();
            }
            else if(node.getName() == 'UnitBasicPrice') {
                responseMapperObject.UnitBasicPrice = node.getText().trim();
            }
            else if(node.getName() == 'TransactionAgingDays') {
                responseMapperObject.TransactionAgingDays = node.getText().trim();
            }
            //Added by Pankaj & Shreela on 24-02-2022
            else if(node.getName() == 'CommittedQty') {
                responseMapperObject.CommittedQty = node.getText().trim();
            }
            //Ended by Pankaj & Shreela 

            else if(node.getName() == 'messageType') {
                responseMapperObject.messageType = node.getText().trim();
            }
            else if(node.getName() == 'messageText') {
                if((System.Label.BDE_Possible_Error_Messages).containsIgnoreCase(node.getText().trim())) {
                    responseMapperObject.message = node.getText().trim();
                }
               
            }
       

        for (Dom.XMLNode child: node.getChildren()) {
            parseXML(child);
        }
    }
}