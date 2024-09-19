/*------------------------------------------------------------------------
Author:        Shubham Pant      
Description:   This method will be generating good and bad otp for the customer
Inputs:        NA
Test Class:    
----------------------------------------------------------------------------*/
public class OTPGenerator {
    
    public class OTPWrapper {
        @InvocableVariable(description='Good OTP value')
        public Integer goodOTP;
        
        @InvocableVariable(description='Bad OTP value')
        public Integer badOTP;
        
        public OTPWrapper(Integer goodOTP, Integer badOTP) {
            this.goodOTP = goodOTP;
            this.badOTP = badOTP;
        }
    }
    
    @InvocableMethod(description='This method will be generating good and bad OTPs for the customer')
    public static List<OTPWrapper> generateOTP() {
        List<OTPWrapper> otpValues = new List<OTPWrapper>();
        
        Integer goodOTP = generateRandomOTP();
        Integer badOTP = generateRandomOTP();
        
        otpValues.add(new OTPWrapper(goodOTP, badOTP));
        
        return otpValues;
    }
    
    private static Integer generateRandomOTP() {
        String randomIntegerString = String.valueOf(Math.abs(Crypto.getRandomInteger()));
        String otpString = randomIntegerString.substring(0, 6);
        return Integer.valueOf(otpString);
    }
}