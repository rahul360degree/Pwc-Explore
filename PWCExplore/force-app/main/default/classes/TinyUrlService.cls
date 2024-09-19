public class TinyUrlService {
    public String create(String url) {
        String finalUrl = 'https://tinyurl.com/api-create.php?url='+url;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(finalUrl);
        req.setMethod('GET'); 
		Http htp = new Http();
        HttpResponse res = htp.send(req);
        system.debug('res'+res.getBody());

        if(res.getStatusCode()==200){
            return res.getBody();
        }
        else{
            return '';
        }
    }
}