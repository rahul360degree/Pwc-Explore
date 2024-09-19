/*------------------------------------------------------------------------
Author:        PSM
Company:       GITL
Description:   Wrapper class for Asset to sort on basis of Account id
----------------------------------------------------------------------------*/
global class AssetWrapper implements Comparable {
    public Asset objAsset;

    // Constructor
    public AssetWrapper(Asset a) {
        objAsset = a;
    }

    // Compare Asset based on the account.
    global Integer compareTo(Object compareTo) {
        AssetWrapper compareToAsset = (AssetWrapper)compareTo;// Cast argument to AssetWrapper
        
        Integer returnValue = 0; // The return value of 0 indicates that both elements are equal.
        if (objAsset.Accountid > compareToAsset.objAsset.Accountid) {
            returnValue = 1;  // Set return value to a positive value.
        } 
        else if (objAsset.Accountid < compareToAsset.objAsset.Accountid) {
            returnValue = -1; // Set return value to a negative value.
        }

        return returnValue;       
    }
}