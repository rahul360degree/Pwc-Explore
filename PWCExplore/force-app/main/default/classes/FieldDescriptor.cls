public with sharing class FieldDescriptor {
    public String fieldLabel;
    public String fieldAPIName;
    public String fieldType;
    public Map<String, String> fieldValueVSfieldLabel;
    public Map<String, List<String>> config;
    public List<DependentFieldInformation> dependentFields;
    public Boolean isError = false;
    public String errorMessage = '';
    public String parentFieldAPIName = '';
}