/*----------------------------------------------------------------------------------
 * Author        :        Joshna
 * Company       :        Salesforce
 * Description   :        Utility class to build chatter messages
 * Test Class    :        ReceivableAlertsBatchTest
 * History
 * --------
 * 18-10-2020      Joshna Palla     Initial Release
 * ----------------------------------------------------------------------------------*/
public with sharing class ChatterUtility {
    private ConnectApi.FeedItemInput feed;
    private ConnectApi.MarkupBeginSegmentInput markupBeginSegment;
    private ConnectApi.MarkupEndSegmentInput markupEndSegment;
    private ConnectApi.MessageBodyInput messageInput;
    private ConnectApi.TextSegmentInput textInput;

    public ChatterUtility() {
        feed = new ConnectApi.FeedItemInput();
        messageInput = new ConnectApi.MessageBodyInput();
        messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
    }

    /**
     * Utility method to add @mention to chatter post
     */
    public ChatterUtility addMention(Id userId) {
        if (String.isBlank(userId)) {
            return this;
        }
        ConnectApi.MentionSegmentInput mention = new ConnectApi.MentionSegmentInput();
        mention.Id = userId;
        messageInput.messageSegments.add(mention);
        return this;
    }

    /**
     * Utility method to add text with markup type
     */
    public ChatterUtility addTextWithMarkupType(String text, ConnectApi.MarkupType textMarkupType) {
        markupBeginSegment  = new ConnectApi.MarkupBeginSegmentInput();
        markupEndSegment = new ConnectApi.MarkupEndSegmentInput();
        textInput = new ConnectApi.TextSegmentInput();
        markupBeginSegment.markupType = textMarkupType;
        messageInput.messageSegments.add(markupBeginSegment);
        textInput.text = text;
        messageInput.messageSegments.add(textInput);
        markupEndSegment.markupType = textMarkupType;
        messageInput.messageSegments.add(markupEndSegment);
        return this;
    }

    /**
     * @description Set chatter subject by id
     */
    public ChatterUtility setSubjectId(Id recordId) {
        if (String.isBlank(recordId)) {
            return this;
        }
        feed.subjectId = recordId;
        return this;
    }

    /**
     * Utility to build FeedItemInput
     */
    public ConnectApi.FeedItemInput build() {
        feed.body = messageInput;
        feed.feedElementType = ConnectApi.FeedElementType.FeedItem;
        return feed;
    }

    public static void postChatterForTestClass(List<ConnectApi.FeedItemInput> feedItemInputList) {
        ConnectApi.FeedElementPage feedElementPage = new ConnectApi.FeedElementPage();
        for (ConnectApi.FeedItemInput eachFeedItem : feedItemInputList) {
            List<ConnectApi.FeedElement> feedItemList = new List<ConnectApi.FeedItem>();
            ConnectApi.FeedElement feedItem = new ConnectApi.FeedItem();
            feedItem.body = new ConnectApi.FeedBody();
            // Setting feedItems to text with mentions
            for (ConnectApi.MessageSegmentInput messageSegment : eachFeedItem.body.messageSegments) {
                if (messageSegment.toString().contains('ConnectApi.TextSegmentInput')) {
                    ConnectApi.TextSegmentInput textSegment = (ConnectApi.TextSegmentInput) messageSegment;
                    feedItem.body.text += textSegment.text;
                }
            }
            feedItemList.add(feedItem);
            feedElementPage.elements = feedItemList;
            ConnectApi.ChatterFeeds.setTestGetFeedElementsFromFeed(null, ConnectApi.FeedType.Record, eachFeedItem.subjectId, feedElementPage);
        }
    }
}