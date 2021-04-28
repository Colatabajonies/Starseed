/**
 * @description       :
 * @author            : shawn.butters
 * @group             :
 * @last modified on  : 04-27-2021
 * @last modified by  : shawn.butters
 * Modifications Log
 * Ver   Date         Author          Modification
 * 1.0   04-27-2021   shawn.butters   Initial Version
**/
@RestResource(urlMapping='/SlackApp_MessageCommandHandler/*')
global class SlackApp_MessageCommandHandler
{
    @HttpPost
    global static void doPost()
    {
        RestRequest req = RestContext.request;
        RestResponse res = Restcontext.response;
        string command = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        String jsonString = req.requestBody.toString();
        //system.debug(req.params);
        //system.debug(jsonString);


        //First see if a slash command is fired
        if (String.isNotBlank(command) && command != 'SlackApp_MessageCommandHandler')
        {
            String slackText = req.params.get('text');
            String slackUser = req.params.get('user_id');
            String slackChannel = req.params.get('channel_id');
            String slackChannelType = req.params.get('channel_name');
            List<SlackEvent__e> sEvents = new List<SlackEvent__e>();
            sEvents.add(new SlackEvent__e(Type__c=command,User__c=slackUser,Text__c=slackText,Channel__c=slackChannel, ChannelType__c=slackChannelType));
            List<Database.SaveResult> results = EventBus.publish(sEvents);
            res.statusCode = 200;
            res.addHeader('Content-Type', 'application/json');
            string responseText = 'running command \'' + command + '\'' + (String.isNotBlank(slackText) ? ' for \'' + slackText + '\'' : '') + '...';
            Map<String, Object> responseBody = new Map<String, Object>{'response_type' => 'in_channel', 'text' => responseText};
            res.responseBody = Blob.valueOf(JSON.serialize(responseBody));
            return;
        }
        
        //next see if it's an interactive action
        //system.debug(req.params.get('payload'));
        if (req.params !=null && String.isNotBlank(req.params.get('payload')))
        {
            Map<String, Object> responseJson = (Map<String, Object>)JSON.deserializeUntyped(req.params.get('payload'));
            if ((string)responseJson.get('type') == 'interactive_message')
            {
                //User clicked some menu
                String slackText = '';
                for (Object o : (List<Object>)responseJson.get('actions'))
                {
                    if ((string)((Map<String, Object>)o).get('type') == 'button')
                    {
                        slackText = (string)((Map<String, Object>)o).get('value');
                    }
                }
                String slackUser = (string)((Map<String, Object>)responseJson.get('user')).get('id');
                String slackChannel = (string)((Map<String, Object>)responseJson.get('channel')).get('id');
                List<SlackEvent__e> sEvents = new List<SlackEvent__e>();
                sEvents.add(new SlackEvent__e(Type__c='message', User__c=slackUser, Text__c=slackText,Channel__c=slackChannel, ChannelType__c='channel'));
                List<Database.SaveResult> results = EventBus.publish(sEvents);
            }
            res.statusCode = 200;
            return;
        }

        //Otherwise handle various Slack Events
        Map<String, Object> responseJson = (Map<String, Object>)JSON.deserializeUntyped(jsonString);
        string messageType = (string)responseJson.get('type');

        //First check if app is trying to be verified
        if (messageType == 'url_verification')
        {
            res.statusCode = 200;
            string challenge = (string)responseJson.get('challenge');
            Map<String, Object> responseBody = new Map<String, Object>{'challenge' => challenge};
            res.responseBody = Blob.valueOf(JSON.serialize(responseBody));
            return;
        }

        else if (messageType == 'event_callback')
        {
            //Process event
            Map<String, Object> jsonEvent = (Map<String,Object>)responseJson.get('event');
            String eventType = (string)jsonEvent.get('type');

            if (eventType == 'message')
            {
                String slackText = (string)jsonEvent.get('text');
            	String slackUser = (string)jsonEvent.get('user');
                String slackChannel = (string)jsonEvent.get('channel');
                String slackChannelType = (string)jsonEvent.get('channel_type');
                List<SlackEvent__e> sEvents = new List<SlackEvent__e>();
                sEvents.add(new SlackEvent__e(Type__c='message', User__c=slackUser, Text__c=slackText,Channel__c=slackChannel, ChannelType__c=slackChannelType));
                List<Database.SaveResult> results = EventBus.publish(sEvents);

                res.statusCode = 200;
                return;
            }
            else if (eventType == 'app_mention')
            {
                String slackText = (string)jsonEvent.get('text');
            	String slackUser = (string)jsonEvent.get('user');
                String slackChannel = (string)jsonEvent.get('channel');
                List<SlackEvent__e> sEvents = new List<SlackEvent__e>();
                sEvents.add(new SlackEvent__e(Type__c='message', User__c=slackUser, Text__c=slackText,Channel__c=slackChannel, ChannelType__c='channel'));
                List<Database.SaveResult> results = EventBus.publish(sEvents);

                res.statusCode = 200;
                return;
            }
            else if (eventType == 'app_home_opened') {
                String slackText = (string)jsonEvent.get('text');
            	String slackUser = (string)jsonEvent.get('user');
                String slackChannel = (string)jsonEvent.get('channel');
                String eventTs = (String)jsonEvent.get('event_ts');
                String hash = (String)jsonEvent.get('hash');

                String token = 'xoxb-1825047764117-2002524456243-eS5cGd8PZ8jQr8dGNMBQwikH';
                String protoString = '{"type":"home","blocks":[{"type":"header","text":{"type":"plain_text","text":":salesforce:  Service"}},{"type":"section","text":{"type":"mrkdwn","text":"This is the very beginning of your direct message history with <https://project-starseed.slack.com/archives/C01V43L8LMC|Service>"}},{"type":"context","elements":[{"type":"mrkdwn","text":":bulb: *How does <https://project-starseed.slack.com/archives/C01V43L8LMC|Service> work?*"}]}]}';
                String appHomeJson = EncodingUtil.urlEncode(protoString, 'UTF-8');
                Http http = new Http();
                HttpRequest postAppHome = new HttpRequest();
                String requestEndpoint = 'https://slack.com/api/views.publish';
                //String requestParams = 'user_id={0}&view={1}&hash={2}';
                String[] paramValues = new String[]{
                    slackUser, appHomeJson, hash, token
                };
                //postAppHome.setEndpoint(String.valueOf(requestEndpoint + String.format(requestParams, paramValues)));
                postAppHome.setEndpoint(requestEndpoint);
                postAppHome.setMethod('POST');
                postAppHome.setHeader('Authorization', 'Bearer ' + token);
                postAppHome.setHeader('Content-Type', 'application/json; charset=UTF-8');
                postAppHome.setTimeout(60000);

                Map<String, Object> payload = new Map<String, Object>{
                    'user_id' => slackUser,
                    'view' => '{"type":"home","blocks":[{"type":"header","text":{"type":"plain_text","text":":salesforce:  Service"}},{"type":"section","text":{"type":"mrkdwn","text":"This is the very beginning of your direct message history with <https://project-starseed.slack.com/archives/C01V43L8LMC|Service>"}},{"type":"context","elements":[{"type":"mrkdwn","text":":bulb: *How does <https://project-starseed.slack.com/archives/C01V43L8LMC|Service> work?*"}]},{"type":"context","elements":[{"text":"*April 27, 2021*  |  Today","type":"mrkdwn"}]},{"type":"divider"},{"type":"header","text":{"type":"plain_text","text":":salesforce: Service","emoji":true}},{"type":"divider"},{"type":"section","text":{"type":"mrkdwn","text":"*Hey There :raised_hands:, I\'m <https://project-starseed.slack.com/archives/C01V43L8LMC|Service> and I\'m here to keep you buzzing with your mission critical collaboration*"}},{"type":"divider"},{"type":"section","text":{"type":"mrkdwn","text":" :dart: *Stay Focussed*"}},{"type":"section","text":{"type":"mrkdwn","text":"Everyday I will send you a list of swarms that need your attention most."}},{"type":"section","text":{"type":"mrkdwn","text":":bee: *Be Prompted to Swarm*"}},{"type":"section","text":{"type":"mrkdwn","text":"I will keep on eye on the cases you are an owner of and send you the ones that could use some Service collaboration."}},{"type":"section","text":{"type":"mrkdwn","text":":eagle: *Get a birds eye view*"}},{"type":"section","text":{"type":"mrkdwn","text":"You can always go the App Home Page to see all active and closed swarms and take quick action from there."}},{"type":"section","text":{"type":"mrkdwn","text":":mega: *Keep everyone informed with broadcasting*"}},{"type":"section","text":{"type":"mrkdwn","text":"There are lots of people who want to know your Service progress that might not be in your Swarm channel, keep them informed with broadcasting."}},{"type":"section","text":{"type":"mrkdwn","text":":hand: *Reach out for help*"}},{"type":"section","text":{"type":"mrkdwn","text":"Launch a swarm when you know you need help. We will connect you with the right people from across your company or in a partner company with expert finder!"}},{"type":"divider"},{"type":"section","text":{"type":"mrkdwn","text":":helmet_with_white_cross: |   *Service!*  | :helmet_with_white_cross:"}},{"type":"section","text":{"type":"mrkdwn","text":"Service by launching a swarm from this test Case. It will create a test swarm channel for you to learn how to Swarm. Bring in people you know and let them know you are just learning."}},{"type":"section","text":{"type":"mrkdwn","text":"TestCase123456 in Salesforce"},"accessory":{"type":"button","text":{"type":"plain_text","text":"Launch a Test Swarm","emoji":true}}},{"type":"divider"},{"type":"section","text":{"type":"mrkdwn","text":":eyes: *Or just watch others Service to start*"}},{"type":"section","text":{"type":"mrkdwn","text":"You can join this public active Swarm to see Service in action and learn new skills!"}},{"type":"section","text":{"type":"mrkdwn","text":"<https://project-starseed.slack.com/archives/C01V43L8LMC|Channel-Name-1linked>  :woman: Created on `04/27/2021` - 12 members"}},{"type":"section","text":{"type":"mrkdwn","text":":toolbox: Case 00001504 | In Progress"}},{"type":"divider"},{"type":"section","text":{"type":"mrkdwn","text":"Skills"}},{"type":"actions","elements":[{"type":"button","text":{"type":"plain_text","text":"Skill 1","emoji":true},"value":"click_me_123","action_id":"actionId-0"}]},{"type":"actions","elements":[{"type":"button","text":{"type":"plain_text","text":"Skill 2","emoji":true},"value":"click_me_123","action_id":"actionId-0"}]},{"type":"section","text":{"type":"mrkdwn","text":"Join this Swarm Channel"},"accessory":{"type":"button","text":{"type":"plain_text","text":"Join Swarm Channel","emoji":true},"value":"click_me_123","action_id":"button-action"}}]}'
                    //'hash' => hash
                    //String.valueOf(
                    //    Crypto.generateDigest('MD5', Blob.valueOf(String.valueOf(System.now()))) //assists with race conditions under high-traffic environments
                    //)
                };
                //res.responseBody = Blob.valueOf(responseData);
                postAppHome.setBody(JSON.serialize(payload));
                HttpResponse newAppHomeResponse = http.send(postAppHome);
                System.debug(newAppHomeResponse.getBody());
                res.statusCode = 200;
            }
        }
        
        res.statusCode = 200;

    }
}