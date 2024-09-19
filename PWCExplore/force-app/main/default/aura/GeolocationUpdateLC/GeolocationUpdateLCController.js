({
    trackLocation: function(component, event, helper) {
        // Reset the message initially
        component.set("v.message", "Updating location...");

        navigator.geolocation.getCurrentPosition(
            function(position) {
                var latitude = position.coords.latitude;
                var longitude = position.coords.longitude;
                var recordId = component.get("v.recordId");

                var action = component.get("c.updateGeolocation");
                action.setParams({
                    latitude: latitude,
                    longitude: longitude,
                    recordId: recordId
                });
                action.setCallback(this, function(response) {
                    var state = response.getState();
                    if (state === "SUCCESS") {
                        var isSuccess = response.getReturnValue();
                        if (isSuccess) {
                            // Location sent to server successfully
                            console.log("Location sent to server.");
                            // Set success message
                            component.set("v.message", "Location updated successfully.");
                            $A.get('e.force:refreshView').fire();
                            $A.get("e.force:closeQuickAction").fire();
                        } else {
                            // Set message if already in progress
                            component.set("v.message", "Location update is already in progress.");
                        }
                    } else {
                        // Handle any errors
                        console.error("Error sending location data: " + JSON.stringify(response.getError()));
                        // Set error message
                        component.set("v.message", "Error updating location. Please try again later.");
                    }
                });
                $A.enqueueAction(action);
            },
            function(error) {
                // Handle geolocation errors
                console.error("Geolocation error: " + error.message);
                // Set error message
                component.set("v.message", "Geolocation error: " + error.message);
            }
        );
    }
})