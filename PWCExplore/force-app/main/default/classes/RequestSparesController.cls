public class RequestSparesController {
    
    @AuraEnabled
    public static void saveFormData(Map<String, Object> formData) {
        System.debug('Test');
        String issue = (String)formData.get('issue');
        String partCode = (String)formData.get('partCode');
        String modelNumber = (String)formData.get('modelNumber');
        String reasonForReplacement = (String)formData.get('reasonForReplacement');
        Integer quantity = (Integer)formData.get('quantity');
        String selectedDeliveryOption = (String)formData.get('selectedDeliveryOption');
        Id workOrderId = (Id)formData.get('workOrderId');
        Blob serialNumberFile = (Blob)formData.get('serialNumberFile');
        Blob invoiceFile = (Blob)formData.get('invoiceFile');
        
    }
    
}