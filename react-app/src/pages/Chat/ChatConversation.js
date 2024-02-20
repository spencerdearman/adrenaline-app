import React, { useContext, useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';

// import { DataStore } from '@aws-amplify/datastore';
import { Card, Heading } from '@aws-amplify/ui-react';

import { CurrentUserContext } from '../../App';
import { getUserById } from '../../utils/dataStore';
// import { Message, MessageNewUser, NewUser } from '../models';

const Chat = () => {
  const userContext = useContext(CurrentUserContext);
  const { profileId, recipientId } = useParams();
  const [user, setUser] = useState();
  const [, setRecipient] = useState();
  const [messages] = useState([]);
  // const [observedMessageIDs, setObservedMessageIDs] = useState(new Set());

  // Set user and check for matching ID
  useEffect(() => {
    getUserById(userContext.userId)
      .then(data => {
        if (data !== undefined && data.id !== profileId) {
          this.props.history.push('/chat/404');
        } else if (data !== undefined) {
          setUser(data);
        }
      });
  }, [userContext, profileId]);

  // Set recipient ID
  useEffect(() => {
    getUserById(recipientId)
      .then(data => {
        setRecipient(data);
      });
  }, [recipientId]);

  return (
    <Card>
      <Heading level={1}>Chat with {user?.firstName} {user?.lastName}</Heading>
      {/* Render messages or chat interface here */}
      {messages.map(message => (
        <div key={message.id}>{message.body}</div>
      ))}
    </Card>
  );
};

export default Chat;
