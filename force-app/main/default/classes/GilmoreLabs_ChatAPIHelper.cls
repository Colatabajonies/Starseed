public class GilmoreLabs_ChatAPIHelper 
{
    public static List<initSessionResponse> InitSession(List<chatInitRequest> requests)
    {
        List<initSessionResponse> responses = new List<initSessionResponse>();
        initSessionResponse response = new initSessionResponse();
        chatInitRequest request = requests[0];
        Http http1=new Http();
        HttpRequest req1=new HttpRequest();
        req1.setendpoint(request.chatEndpoint + '/chat/rest/System/SessionId');
        req1.setmethod('GET');
        req1.setHeader('Accept', '*/*');
        req1.setHeader('Accept-Encoding', 'gzip, deflate, br');
        req1.setHeader('Connection', 'keep-alive');
        req1.setHeader('X-LIVEAGENT-API-VERSION', request.apiVersion);
        req1.setHeader('X-LIVEAGENT-AFFINITY', 'null');
        HttpResponse res1 = http1.send(req1);
        //system.debug('First Request status:' + res1.getStatusCode());
        
        if (res1.getStatusCode() == 200)
        {
            //Do the chasitor Init
            Map<String, Object> responseJson = (Map<String, Object>)JSON.deserializeUntyped(res1.getBody());
            String sessionKey = (string)responseJson.get('key');
            String sessionId = (string)responseJson.get('id');
            String affinity = (string)responseJson.get('affinityToken');
            
            //Send Chasitor Init
            Http http2=new Http();
            HttpRequest req2=new HttpRequest();
            req2.setendpoint(request.chatEndpoint + '/chat/rest/Chasitor/ChasitorInit');
            req2.setmethod('POST');
            req2.setHeader('Accept', '*/*');
            req2.setHeader('Accept-Encoding', 'gzip, deflate, br');
            req2.setHeader('Connection', 'keep-alive');
            req2.setHeader('X-LIVEAGENT-SESSION-KEY', sessionKey);
            req2.setHeader('X-LIVEAGENT-SEQUENCE', '1');
            req2.setHeader('X-LIVEAGENT-API-VERSION', request.apiVersion);
            req2.setHeader('X-LIVEAGENT-AFFINITY', affinity);
            //req2.setHeader('Content-Type', 'application/json');
            req2.setBody('{"organizationId": "' + UserInfo.getOrganizationId().substring(0,15) + '","deploymentId": "' + request.deploymentId + '","buttonId": "' + request.buttonId + '","sessionId": "' + sessionId + '","userAgent": "' + request.slackChannelId + '|' + affinity + '|' + sessionKey  + '","language": "en-US","screenResolution": "1900x1080","buttonOverrides": [],"prechatDetails": [],"prechatEntities": [],"trackingId": "","receiveQueueUpdates": false, "isPost": true}');
            system.debug(req2.getBody());
            HttpResponse res2 = http2.send(req2);
            if (res2.getStatusCode() == 200)
            {
                response.sessionKey = sessionKey;
                response.affinity = affinity;
            }
            //system.debug('ChasitorInit Request status:' + res2.getStatusCode());
        }
        responses.add(response);
        return responses;
    }
    
    public static List<chatGetMessageResponse> getMessage(List<chatMessageRequest> requests)
    {
        List<chatGetMessageResponse> responses = new list<chatGetMessageResponse>();
        chatGetMessageResponse response = new chatGetMessageResponse();
        response.type = 'none';

        chatMessageRequest request = requests[0];
        Http http1=new Http();
        HttpRequest req1=new HttpRequest();
        req1.setendpoint(request.chatEndpoint + '/chat/rest/System/Messages');
        req1.setTimeout(2000);
        req1.setmethod('GET');
        req1.setHeader('Accept', '*/*');
        req1.setHeader('Accept-Encoding', 'gzip, deflate, br');
        req1.setHeader('Connection', 'keep-alive');
        req1.setHeader('X-LIVEAGENT-API-VERSION', request.apiVersion);
        req1.setHeader('X-LIVEAGENT-AFFINITY', request.affinity);
        req1.setHeader('X-LIVEAGENT-SESSION-KEY', request.sessionKey);
        
        try 
        {
            HttpResponse res1 = http1.send(req1);
            if (res1.getStatusCode() == 200)
            {
                string theText = '';
                List<string> theButtons = new List<String>();
                Map<String, Object> responseJson = (Map<String, Object>)JSON.deserializeUntyped(res1.getBody());
                List<Object> messagesJSON = (List<Object>)responseJson.get('messages');
                for (object messageJSON : messagesJSON)
                {
                    if ((string)( (Map<String, Object>)messageJSON).get('type') == 'ChatMessage')
                    {
                        //add to the message string
                        Map<String, Object> innerJson = (Map<String, Object>)((Map<String, Object>)messageJSON).get('message');
                        theText += (string)innerJson.get('text') + '\\n';
                    }
                    else if ((string)( (Map<String, Object>)messageJSON).get('type') == 'RichMessage')
                    {
                        //add to the message string
                        Map<String, Object> innerJson = (Map<String, Object>)((Map<String, Object>)messageJSON).get('message');
                        List<Object> itemsJSON = (List<Object>)innerJson.get('items');
                        for (object itemJSON : itemsJSON)
                        {
                            theButtons.add((string)( (Map<String, Object>)itemJSON).get('text'));
                        }
                    }
                }
                
                //recursive call
                List<chatGetMessageResponse> rresponses = getMessage(requests);
                if (rresponses != null && rresponses.size() > 0 && String.isNotBlank(rresponses[0].text)) theText += rresponses[0].text;
                if (rresponses != null && rresponses.size() > 0 && rresponses[0].buttons != null && rresponses[0].buttons.size()>0) theButtons = rresponses[0].buttons;
                
                theText = theText.removeEnd('\\n');
                if (theButtons.size() == 0 && String.isNotBlank(theText)) response.type = 'text';
                if (theButtons.size() > 0 && String.isBlank(theText)) response.type = 'buttons';
                if (theButtons.size() > 0 && String.isNotBlank(theText)) response.type = 'both';
                response.text = theText;
                response.buttons = theButtons;
            }
        } 
        catch (CalloutException ex) 
        {
            system.debug('Exception: ' + ex.getTypeName());
        }
        
        responses.add(response);
        return responses;
    }
    
    public static List<HttpResponse> postMessage(List<chatMessageRequest> requests)
    {
        List<HttpResponse> responses = new list<HttpResponse>();
        
        chatMessageRequest request = requests[0];
        Http http1=new Http();
        HttpRequest req1=new HttpRequest();
        req1.setendpoint(request.chatEndpoint + '/chat/rest/Chasitor/ChatMessage');
        req1.setmethod('POST');
        req1.setHeader('Accept', '*/*');
        req1.setHeader('Accept-Encoding', 'gzip, deflate, br');
        req1.setHeader('Connection', 'keep-alive');
        req1.setHeader('X-LIVEAGENT-API-VERSION', request.apiVersion);
        req1.setHeader('X-LIVEAGENT-AFFINITY', request.affinity);
        req1.setHeader('X-LIVEAGENT-SESSION-KEY', request.sessionKey);
        req1.setBody('{"text": "' + request.text + '"}');
        //system.debug(request.sessionKey + ' ' + request.affinity);
        HttpResponse res1 = http1.send(req1);
        //system.debug('Post Message Result: ' + res1.getStatusCode() + ' ' + res1.getBody());
        responses.add(res1);
        
        
        //Delay a few sec
        /*for (integer i = 0; i<1000000;i++)
        {
            string j = i + 'w00t';
        }*/
        return responses;
    }
    
    public class initSessionResponse
    {
        @InvocableVariable(required=true)
        public string sessionKey;
        @InvocableVariable(required=true)
        public string affinity;
    }
    
    public class chatGetMessageResponse
    {
        @InvocableVariable(required=true)
        public string type;
        @InvocableVariable(required=false)
        public string text;
        @InvocableVariable(required=false)
        public List<string> buttons;
    }
    
    public class chatMessageRequest
    {
        @InvocableVariable(required=true)
        public string chatEndpoint;
        @InvocableVariable(required=true)
        public string apiVersion;
        @InvocableVariable(required=true)
        public string affinity;
        @InvocableVariable(required=true)
        public string sessionKey;
        @InvocableVariable(required=false)
        public string text;
    }
    
    public class chatInitRequest
    {
        @InvocableVariable(required=true)
        public string chatEndpoint;
        @InvocableVariable(required=true)
        public string apiVersion;
        @InvocableVariable(required=true)
        public string deploymentId;
        @InvocableVariable(required=true)
        public string buttonId;
        @InvocableVariable(required=true)
        public string slackChannelId;
        @InvocableVariable(required=false)
        public string text;
    }
}