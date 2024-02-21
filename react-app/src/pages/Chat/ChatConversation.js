import React, { useContext, useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';

import { DataStore } from '@aws-amplify/datastore';
import { Button, Card, Flex, Heading, TextField } from '@aws-amplify/ui-react'; // Assuming you're using Amplify UI React components

import { CurrentUserContext } from '../../App';
import { Message, MessageNewUser } from '../../models';
import { getUserById } from '../../utils/dataStore';

import MessageRow from './MessageRow';

const ChatConversation = () => {
  const userContext = useContext(CurrentUserContext);
  const { senderId, recipientId } = useParams();
  const [user, setUser] = useState();
  const [recipient, setRecipient] = useState();
  const [messages, setMessages] = useState([]);
  const [seenMNU, setSeenMNU] = useState(new Set());
  const [messageText, setMessageText] = useState('');
  // add back in sendMessage when it actually is being used -- its a bool
  const [, setSendMessage] = useState(false);
  const navigate = useNavigate();

  // Set user and check for matching ID
  useEffect(() => {
    getUserById(userContext.userId)
      .then(data => {
        if (data !== undefined && data.id !== senderId) {
          navigate('/chat/404');
        } else if (data !== undefined) {
          setUser(data);
        }
      });
  }, [userContext, senderId]);

  // Set recipient ID
  useEffect(() => {
    getUserById(recipientId)
      .then(data => {
        setRecipient(data);
      });
  }, [recipientId]);

  DataStore.observeQuery(MessageNewUser, mnu => mnu.or(mnu => [
    mnu.newuserID.eq(senderId), mnu.newuserID.eq(recipientId)
  ])).subscribe(
    async snapshot => {
      if (!user || !recipient) {
        return;
      }
      const { items } = snapshot;
      const senderMessageIds = new Set();
      const recipientMessageIds = new Set();
      const senderDict = {};
      for (const mnu of items) {
        if (seenMNU.has(mnu.id)) {
          continue;
        }
        if (mnu.newuserID === senderId) {
          senderMessageIds.add(mnu.messageID);
        } else if (mnu.newuserID === recipientId) {
          recipientMessageIds.add(mnu.messageID);
        }
        if (mnu.isSender) {
          senderDict[mnu.messageID] = mnu.newuserID;
        }
        setSeenMNU(prevMNU => new Set([...prevMNU, mnu.id]));
      }
      const intersection = new Set();
      for (const i of senderMessageIds) {
        if (recipientMessageIds.has(i)) {
          intersection.add(i);
        }
      }
      if (intersection.size === 0) { return; }
      const messages = await DataStore.query(Message, m => m.or((m) => [...intersection].map(id => m.id.eq(id))));

      const result = [];
      for (const message of messages) {
        const senderStatus = senderDict[message.id] === senderId;
        const messageTuple = [message, senderStatus];
        result.push(messageTuple);
      }

      setMessages(result.sort((a, b) => {
        return new Date(a.creationDate) < new Date(b.creationDate);
      }));
    }
  );

  const handleMessageChange = (e) => {
    setMessageText(e.target.value);
  };

  // Function to handle send message action
  const handleSendMessage = () => {
    if (messageText.trim() === '') return; // Prevent sending empty messages

    // Here you would add the logic to send the messageText to your backend or data store
    console.log('Sending message:', messageText);

    // Optionally reset the message text and toggle sendMessage state
    setMessageText('');
    setSendMessage(prev => !prev); // Toggle to trigger actions or use as a flag
  };

  return (
    <Card>
      <Heading level={1}>Chat with {recipient?.firstName} {recipient?.lastName}</Heading>
      <div style={{ overflowY: 'scroll', maxHeight: '500px' }}> {/* Adjust max height as needed */}
        {messages.map((message, id) => (
          <MessageRow
            message={message[0]}
            currentUserIsSender={message[1]}
            key={id}/>
        ))}
      </div>
      <Flex direction="row" alignItems="center" justifyContent="space-between" padding="10px">
        <TextField
          placeholder="Type a message..."
          value={messageText}
          onChange={handleMessageChange}
          flexGrow={1}
          marginRight="10px"
        />
        <Button onClick={handleSendMessage}>Send</Button> {/* Replace with an icon or custom button if preferred */}
      </Flex>
    </Card>
  );
};

export default ChatConversation;
