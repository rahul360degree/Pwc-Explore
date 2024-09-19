/**
 * @description       : 
 * @author            : vrajpoot@godrej.com
 * @group             : 
 * @last modified on  : 03-25-2022
 * @last modified by  : vrajpoot@godrej.com
**/
public class ProductConfigResponseHandler{
	public cls_message message;
	public boolean didError;
	public cls_errorMessage errorMessage;
	public cls_model model;
	public class cls_message {
	}
	public class cls_errorMessage {
	}
	public class cls_model {
		public String id;
		public String salCode;
		public String sfpcToken;
	}
	public static ProductConfigResponseHandler parse(String json){
		return (ProductConfigResponseHandler) System.JSON.deserialize(json, ProductConfigResponseHandler.class);
	}
/*
	static testMethod void testParse() {
		String json=		'{"message":null,"didError":false,"errorMessage":null,"model":{"id":"nikhilev","salCode":"366603","sfpcToken":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJjZXJ0c2VyaWFsbnVtYmVyIjoiMjAyMjAzMjUxNjIyNTUwOCIsImVtYWlsIjoiU3lzdGVtLlJhbmRvbSIsIm5iZiI6MTY0ODIwNTU3NSwiZXhwIjoxNjQ4MjIzNTc1LCJpYXQiOjE2NDgyMDU1NzUsImlzcyI6ImdvZHJlamluZm90ZWNoLmNvbSIsImF1ZCI6ImdvZHJlamluZm90ZWNoLmNvbSJ9.ZLPpSaCEZLwWsYUbFjZ4Sg1soSNlJzlu3gMVIR0gJgo"}}';
		ProductConfigResponseHandler obj = parse(json);
		System.assert(obj != null);
	}
    */
}