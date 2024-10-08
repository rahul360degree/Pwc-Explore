/**
 * @Description       : Parser class used to parse the response
 * @Author            : Varun Rajpoot
 * @last modified on  : 12-18-2023
 * @last modified by  : Varun Rajpoot
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   12-14-2023   Varun Rajpoot   Initial Version
**/
//
// Generated by JSON2Apex http://json2apex.herokuapp.com/
//

public class EzeTapResponseParser {

	public Boolean success;
	public String sessionKey;
	public String username;
	public Boolean enableRki;
	public String amount;
	public String amountOriginal;
	public String authCode;
	public String cardLastFourDigit;
	public String currencyCode;
	public String customerMobile;
	public String customerReceiptUrl;
	public String externalRefNumber;
	public String formattedPan;
	public String txnId;
	public String merchantName;
	public String mid;
	public String nonceStatus;
	public String orgCode;
	public String merchantCode;
	public String payerName;
	public String paymentCardBin;
	public String paymentCardBrand;
	public String paymentCardType;
	public String paymentMode;
	public String postingDate;
	public String processCode;
	public String rrNumber;
	public String settlementStatus;
	public String status;
	public List<String> states;
	public String tid;
	public String txnType;
	public Boolean dccOpted;
	public String cardHolderCurrencyExponent;
	public String userAgreement;
	public Boolean signable;
	public Boolean voidable;
	public Boolean refundable;
	public String chargeSlipDate;
	public String readableChargeSlipDate;
	public String issuerCode;
	public String maximumPayAttemptsAllowed;
	public String maximumSuccessfulPaymentAllowed;
	public Boolean noExpiryFlag;
	public String settlementTime;
	public String receiptUrl;
	public Boolean signReqd;
	public String txnTypeDesc;
	public String paymentGateway;
	public String acquirerCode;
	public String createdTime;
	public Boolean customerNameAvailable;
	public Boolean callbackEnabled;
	public Boolean onlineRefundable;
	public String cardClassification;
	public String shiftNo;
	public String orderNumber;
	public String reverseReferenceNumber;
	public String totalAmount;
	public String displayPAN;
	public String nameOnCard;
	public String cardType;
	public Boolean tipEnabled;
	public Boolean callTC;
	public String acquisitionId;
	public String acquisitionKey;
	public Boolean processCronOutput;
	public Boolean externalDevice;
	public Boolean tipAdjusted;
	public List<TxnMetadata> txnMetadata;
	public String middlewareStanNumber;
	public Boolean otpRequired;
	public String abstractPaymentStatus;
	public Boolean twoStepConfirmPreAuth;
	public Boolean reload;
	public Boolean redirect;
	public String errorCode;
	public String errorMessage;
	public String message;
	public String realCode;
    public String customerName;
	public class TxnMetadata {
	}

	
	public static EzeTapResponseParser parse(String json) {
		return (EzeTapResponseParser) System.JSON.deserialize(json, EzeTapResponseParser.class);
	}
}