public class SlackApp_PostBotMessage 
{
    @InvocableMethod(label='Slack - Post Bot Message')
    public static List<GilmoreLabs_ChatAPIHelper.chatGetMessageResponse> postMessage(List<GilmoreLabs_ChatAPIHelper.chatInitRequest> requests) 
    {
        GilmoreLabs_ChatAPIHelper.chatInitRequest request = requests[0];
        List<GilmoreLabs_ChatAPIHelper.chatGetMessageResponse> responses = new List<GilmoreLabs_ChatAPIHelper.chatGetMessageResponse>();
        GilmoreLabs_ChatAPIHelper.chatGetMessageResponse response = new GilmoreLabs_ChatAPIHelper.chatGetMessageResponse();
        response.type = 'none';
        //first see if we need to init first or use existing session
        string likeMatch = request.slackChannelId + '%';
        List<LiveChatTranscript> objTs = new List<LiveChatTranscript>([SELECT Id, ChatKey, UserAgent FROM LiveChatTranscript WHERE status =: 'Waiting' AND LiveChatDeploymentId =: request.deploymentId AND UserAgent LIKE :likeMatch]);
        if (objTs.size() > 0)
        {
            //use existing session
            GilmoreLabs_ChatAPIHelper.chatMessageRequest thechatRequest = new GilmoreLabs_ChatAPIHelper.chatMessageRequest();
            thechatRequest.chatEndpoint = request.chatEndpoint;
            thechatRequest.sessionKey = objTs[0].UserAgent.split('\\|')[2];
            theChatRequest.apiVersion = request.apiVersion;
            theChatRequest.affinity = objTs[0].UserAgent.split('\\|')[1];
            theChatRequest.text = request.text;
            
            //First post the message
            GilmoreLabs_ChatAPIHelper.postMessage(new list<GilmoreLabs_ChatAPIHelper.chatMessageRequest>{thechatRequest});
            //then read the responses
            responses = GilmoreLabs_ChatAPIHelper.getMessage(new list<GilmoreLabs_ChatAPIHelper.chatMessageRequest>{thechatRequest});
            return responses;
        }
        else
        {
            //We need to Init a new Session and then get the response
            system.debug('Initializing new Session...');
            List<GilmoreLabs_ChatAPIHelper.initSessionResponse> initResponses = GilmoreLabs_ChatAPIHelper.InitSession(requests);
            if (initResponses.size() > 0 && String.isNotBlank(initResponses[0].sessionKey))
            {
                system.debug('Now "' + request.text + '" to session:' + initResponses[0].sessionKey + ' ' + initResponses[0].affinity);
                //use existing session
                GilmoreLabs_ChatAPIHelper.chatMessageRequest thechatRequest = new GilmoreLabs_ChatAPIHelper.chatMessageRequest();
                thechatRequest.chatEndpoint = request.chatEndpoint;
                thechatRequest.sessionKey = initResponses[0].sessionKey;
                theChatRequest.apiVersion = request.apiVersion;
                theChatRequest.affinity = initResponses[0].affinity;
                theChatRequest.text = request.text;
                //First post the message
                GilmoreLabs_ChatAPIHelper.postMessage(new list<GilmoreLabs_ChatAPIHelper.chatMessageRequest>{thechatRequest});
                
                //Then read the response
                responses = GilmoreLabs_ChatAPIHelper.getMessage(new list<GilmoreLabs_ChatAPIHelper.chatMessageRequest>{thechatRequest});
                return responses;
            }
        }
        
        responses.add(response);
        return responses;
    }
}