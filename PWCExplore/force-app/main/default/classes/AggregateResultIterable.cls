global class AggregateResultIterable implements Iterable<AggregateResult>{
    private String query;
    private Set<String> roles;
    global AggregateResultIterable(String soql, Set<String> pjpRoles){
        query = soql;
        roles = pjpRoles;
    }
    
    global Iterator<AggregateResult> Iterator(){
      return new AggregateResultIterator(query, roles);
    } 
}