@IsTest
public class mockTinyUrlService implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setBody('https://tinyurl.com/8wa5w2o');
        res.setStatusCode(200);
        return res;
    }  
}