public class SalesOrderBulkAPIHelper {
    public static Map<String, Id> generateCSVOrders(List<JSONRequestWrapper> jsonRequestWrapper) {
        // Initialize a StringBuilder to construct the CSV content
        String csvDataOrders = '';
        
        Map<String, Id> mapOrderRefAndId = new Map<String, Id>();
        
        // Append header row
        csvDataOrders += 'AccountId,RecordTypeId,LogisticCompany,OrderNumber,OrderDate,OrderStatus,CustomerCode,PriceBookId,OrderReferenceNo\n';

        // Iterate through each order and its line items to generate CSV rows
        for (JSONRequestWrapper jsonWrapObj : jsonRequestWrapper) {
            // Add order record to CSV
            OrderWrapper orderRec = jsonWrapObj.orderRec;
            csvDataOrders = csvDataOrders + orderRec.AccountId + ','
                    + orderRec.RecordTypeId + ','
                    + orderRec.LogisticCompany + ','
                    + orderRec.OrderNumber+','
                    + orderRec.OrderDate +','
                    + orderRec.OrderStatus+','
                    + orderRec.CustomerCode+','
                    + orderRec.PriceBookId+','
                    + orderRec.OrderReferenceNo+'\n';

            // Add order line items to CSV
            /*for (OrderProductWrapper lineItem : jsonWrapObj.orderProducts) {
                csvData.append(escapeCsvValue(lineItem.OrderId)).append(',')
                       .append(escapeCsvValue(lineItem.PositionNo)).append(',')
                       .append(escapeCsvValue(lineItem.SequenceNo)).append(',')
                       .append(escapeCsvValue(lineItem.Warehouse)).append(',')
                       .append(escapeCsvValue(String.valueOf(lineItem.Quantity))).append(',')
                       .append(escapeCsvValue(lineItem.ItemCode)).append(',')
                       .append(escapeCsvValue(lineItem.LineStatus)).append(',')
                       .append(escapeCsvValue(String.valueOf(lineItem.ListPrice))).append(',')
                       .append(escapeCsvValue(String.valueOf(lineItem.UnitPrice))).append(',')
                       .append(escapeCsvValue(lineItem.Product2Id)).append(',')
                       .append(escapeCsvValue(lineItem.PriceBookEntryId)).append('\n');
            }*/
        }

        // Return the generated CSV data
        return mapOrderRefAndId;
    }

  
    
    // Wrapper class for the JSON request
    public class JSONRequestWrapper {
        public OrderWrapper orderRec;
        public List<OrderProductWrapper> orderProducts;
    }
    
    // Wrapper class for the order record
    public class OrderWrapper {
        public String accountId;
        public String recordTypeId;
        public String logisticCompany;
        public String orderNumber;
        public Date orderDate;
        public String orderStatus;
        public String customerCode;
        public String priceBookId;
        public String orderReferenceNo;
    }
    
    // Wrapper class for the order line item
    public class OrderProductWrapper {
        public String orderId;
        public String positionNo;
        public String sequenceNo;
        public String warehouse;
        public String quantity;
        public String itemCode;
        public String lineStatus;
        public String listPrice;
        public String unitPrice;
        public String product2Id;
        public String priceBookEntryId;
    }          
    
}