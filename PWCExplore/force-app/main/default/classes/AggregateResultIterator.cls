global class AggregateResultIterator Implements Iterator<AggregateResult>{
    AggregateResult [] results {get;set;}
    // tracks which result item is returned
    Integer index {get; set;} 
    
    global AggregateResultIterator(String query,  Set<String> Roles) {
        index = 0;
        String INTERIO_BUSINESS_UNIT = GeneratePJPBatch.INTERIO_BUSINESS_UNIT;
        String b2bInterioSubDivision = GeneratePJPBatch.b2bInterioSubDivision;
        String APPLIANCE_BUSINESS_UNIT = GeneratePJPBatch.APPLIANCE_BUSINESS_UNIT;
        results = Database.query(query); 
    } 
    
    global boolean hasNext(){ 
        return results != null && !results.isEmpty() && index < results.size(); 
    }    
    
    global AggregateResult next(){        
        return results[index++];            
    }     
    
}