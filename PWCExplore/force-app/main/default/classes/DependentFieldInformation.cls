public class DependentFieldInformation {
    public String dependentField_APIName;
    public Map<String, List<String>> controllingFieldValue_VS_dependentValues;

    public DependentFieldInformation() {
        controllingFieldValue_VS_dependentValues = new Map<String, List<String>>();
    }
}