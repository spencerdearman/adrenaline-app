import React, { useContext, useEffect, useState } from 'react';

// import { useParams } from 'react-router-dom';
import { Card, Heading } from '@aws-amplify/ui-react';

import { CurrentUserContext } from '../../App';
import { getUserById } from '../../utils/dataStore';

import { useChat } from './ChatContext';
import ProfileRow from './ProfileRow';

const Chat = () => {
  const currentUser = useContext(CurrentUserContext);
  const { chatConversations, users } = useChat();
  const [user, setUser] = useState();

  // Fetch and update current user
  useEffect(() => {
    const fetchCurrentUser = async () => {
      const user = await getUserById(currentUser.userId); // Assuming currentUser.userId is correct
      if (user) {
        setUser(user);
      }
    };
    fetchCurrentUser();
  }, [currentUser.userId]);

  return (
    <Card>
      <Heading level={1}>Messaging</Heading>
      {users.length > 0 && user
        ? (
          users.map((recipient, index) => (
            <ProfileRow
              key={index}
              currentUserId = {user.id}
              recipient={recipient}
              messages={chatConversations} />
          ))
        )
        : (
          <div>No active conversations.</div>
        )}
    </Card>
  );
};

export default Chat;
