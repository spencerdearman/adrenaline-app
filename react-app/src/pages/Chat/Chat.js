import React, { useContext, useEffect, useState } from 'react';

// import { useParams } from 'react-router-dom';
import { DataStore } from '@aws-amplify/datastore';
import { Card, Heading } from '@aws-amplify/ui-react';

import { CurrentUserContext } from '../../App';
import { Message, MessageNewUser, NewUser } from '../../models';
import { getUserById } from '../../utils/dataStore';

import ProfileRow from './ProfileRow';

const Chat = () => {
  const currentUser = useContext(CurrentUserContext);

  const [chatConversations, setChatConversations] = useState({});
  const [sortOrder, setSortOrder] = useState({});
  const [user, setUser] = useState();
  const [users, setUsers] = useState([]);
  // add back in messages into the line below when actually using it
  const [, setMessages] = useState([]);
  const [observedMessageIDs, setObservedMessageIDs] = useState(new Set());
  // add back setSearchTerm
  // const [searchTerm] = useState('');

  // Function to observe new messages and update state
  DataStore.observeQuery(Message).subscribe(
    async snapshot => {
      if (!user) {
        return;
      }

      console.log('inside snapshot');
      const { items } = snapshot;
      for (const newMessage of items) {
        console.log(newMessage);
        if (!observedMessageIDs.has(newMessage.id)) {
          // Try to fetch related MessageNewUser Records
          try {
            const msgMessageNewUsers = await DataStore.query(MessageNewUser,
              c => c.messageID.eq(newMessage.id));
            if (msgMessageNewUsers.length === 2) {
              const currentMessageNewUser = msgMessageNewUsers.find(mnu =>
                mnu.newuserID === user.id);
              const recipientMessageNewUser = msgMessageNewUsers.find(mnu =>
                mnu.newuserID !== user.id);

              console.log(currentMessageNewUser);
              console.log(recipientMessageNewUser);

              // adding
              if (currentMessageNewUser && recipientMessageNewUser) {
                setMessages(prevMessages => [...prevMessages, newMessage]);
                updateChatConversations(newMessage, currentMessageNewUser, recipientMessageNewUser);
              }
            } else {
              console.error("MessageNewUser count isn't 2");
            }
            // Adding message to observed list regardless
            setObservedMessageIDs(prevIDs => new Set(prevIDs).add(newMessage.id));
          } catch (error) {
            console.error('Error fetching MessageNewUser records: ', error);
          }
        }
      }
    }
  );

  useEffect(() => {
    const updateUserList = async () => {
      const newUserIds = Object.keys(chatConversations).filter(userId =>
        !users.some(user => user.id === userId));

      for (const userId of newUserIds) {
        try {
          const userData = await getUserById(userId);
          const updatedUsers = users.concat([userData]);
          setUsers(updatedUsers);
          console.log('INSIDE USERS PORTION');
          console.log(users);
        } catch (error) {
          console.error('Error fetching user data:', error);
        }
      }
    };

    updateUserList();
  }, [chatConversations]);

  useEffect(() => {
    // Fetch current user
    const fetchCurrentUser = async () => {
      console.log(JSON.stringify(currentUser));
      const user = await DataStore.query(NewUser, currentUser.userId); // Assuming currentUser.userId is correct
      if (user) {
        setUser(user);
      }
    };
    fetchCurrentUser();
  }, [currentUser.userId, observedMessageIDs]);

  const updateChatConversations = (newMessage, currentMessageNewUser, recipientMessageNewUser) => {
    // Assuming newMessage has a recipientId to use as the key
    const key = recipientMessageNewUser.userId;
    const senderStatus = currentMessageNewUser.isSender;
    const messageTuple = [newMessage, senderStatus];

    setChatConversations(prevConversations => {
      const updatedConversations = { ...prevConversations };
      // Check if there's an existing conversation for the key
      if (updatedConversations[key]) {
        // Append the new message tuple to the existing array
        updatedConversations[key].push(messageTuple);
      } else {
        // Create a new array for this key with the message tuple
        updatedConversations[key] = [messageTuple];
      }
      return updatedConversations;
    });

    setSortOrder(prevSortOrder => {
      const updatedSortOrder = { ...prevSortOrder };
      const messageDate = new Date(newMessage.creationDate);
      if (!updatedSortOrder[key] || new Date(updatedSortOrder[key]) < messageDate) {
        updatedSortOrder[key] = newMessage.creationDate; // update with new message date
      }
      return updatedSortOrder;
    });
  };

  const getSortedConversationKeys = () => {
    return Object.keys(sortOrder).sort((a, b) => new Date(sortOrder[b]) - new Date(sortOrder[a]));
  };

  const updateAndSortUsers = async () => {
    const sortedUserIds = getSortedConversationKeys();

    const updatedUsers = await Promise.all(sortedUserIds.map(async (userId) => {
      const existingUser = users.find(user => user.id === userId);
      if (existingUser) {
        return existingUser;
      } else {
        try {
          const newUser = await getUserById(userId);
          return newUser;
        } catch (error) {
          console.error(`Error fetching user data for ID ${userId}:`, error);
          return null;
        }
      }
    }));

    // Filter out any null values in case of fetch errors and update the users state
    setUsers(updatedUsers.filter(user => user !== null));
  };

  useEffect(() => {
    updateAndSortUsers();
  }, [chatConversations, sortOrder]);

  // const filteredChats = useMemo(() => users.filter(user =>
  //   user.name.toLowerCase().includes(searchTerm.toLowerCase())
  // ), [users, searchTerm]);

  // const handleChatSelect = async (user) => {
  //   // Your chat selection handling logic here
  // };

  return (
    <Card>
      <Heading level={1}>Chat with {user?.firstName} {user?.lastName}</Heading>
      {users.length > 0
        ? (
          users.map((user, index) => (
            <React.Fragment key={user.id}>
              {index !== 0 && <hr />}
              <ProfileRow user={user} />
            </React.Fragment>
          ))
        )
        : (
          <div>No active conversations.</div>
        )}
    </Card>
  );
};

export default Chat;
