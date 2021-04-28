global class SlackApp_PostMessage 
{
    @InvocableMethod(label='Slack - Post Message')
    global static List<Boolean> postMessage(List<postMessageRequest> requests) 
    {
        postMessageRequest request = requests[0];
        
        if (String.isBlank(request.text) && (request.buttons == null || request.buttons.size() == 0))
        {
            //Nothing to post
            return new list<boolean>{false};
        }
        
        Http http1=new Http();
        HttpRequest req1=new HttpRequest();
        req1.setendpoint('https://slack.com/api/chat.postMessage');
        req1.setmethod('POST');
        req1.setHeader('Authorization', 'Bearer ' + request.token);
        req1.setHeader('Content-Type', 'application/json');
        
        //Build the text
        String theText = String.isNotBlank(request.text) ? request.text : 'Select an option';
        //Build the buttons
        String thebuttonJSON = '';
        if (request.buttons != null && request.buttons.size() > 0)
        {
            thebuttonJSON = '"attachments": [{"fallback": "You did not choose","callback_id": "bot_optionMenu","color": "#C66D9C","actions": [';
            for (String button : request.buttons)
            {
                theButtonJSON += '{"name": "theOption","text": "' + button + '","type": "button","value": "' + button + '"},';
            }
            thebuttonJSON = thebuttonJSON.removeEnd(',') + ']}]';
        }
        system.debug(theButtonJSON);
        req1.setBody('{"channel": "' + request.channel + '","text": "' + request.text + '",' + thebuttonJSON + '}');
        HttpResponse res1 = http1.send(req1);
        
        if (res1.getStatusCode() == 200)
        {
            return new list<boolean>{true};
        }
        return new list<boolean>{false};
    }
    
    global class postMessageRequest
    {
        @InvocableVariable(required=true)
        public string token;
        @InvocableVariable(required=true)
        public string channel;
        @InvocableVariable(required=false)
        public string text;
        @InvocableVariable(required=false)
        public List<string> buttons;
    }
}