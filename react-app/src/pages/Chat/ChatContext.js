import React, { createContext, useContext, useEffect, useState } from 'react';

import { DataStore } from '@aws-amplify/datastore';

import { CurrentUserContext } from '../../App';
import { Message, MessageNewUser } from '../../models';
import { getUserById } from '../../utils/dataStore';

const ChatContext = createContext();

export function useChat() {
  return useContext(ChatContext);
}

export const ChatProvider = ({ children }) => {
  const currentUser = useContext(CurrentUserContext);
  const [user, setUser] = useState(null);
  const [sortOrder, setSortOrder] = useState({});
  const [chatConversations, setChatConversations] = useState({});
  const [users, setUsers] = useState([]);
  const [observedMessageIDs, setObservedMessageIDs] = useState(new Set());

  // Fetching the current logged in user
  useEffect(() => {
    const fetchCurrentUser = async () => {
      const user = await getUserById(currentUser.userId); // Assuming currentUser.userId is correct
      if (user) {
        setUser(user);
      }
    };
    fetchCurrentUser();
  }, [currentUser.userId]);

  // Function to update chat conversations
  const updateChatConversations = (newMessage, currentMessageNewUser, recipientMessageNewUser) => {
    // Assuming newMessage has a recipientId to use as the key
    const key = recipientMessageNewUser.newuserID;
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

  // Function to sort and update users based on conversations
  const updateAndSortUsers = async () => {
    const sortedUserIds = getSortedConversationKeys();

    const updatedUsers = await Promise.all(sortedUserIds.map(async (userId) => {
      const existingUser = users.find(user => user ? user.id === userId : false);
      if (existingUser) {
        return existingUser;
      } else {
        try {
          const newUser = await getUserById(userId);
          return newUser;
        } catch (error) {
          console.error(`Error fetching user data for ID ${userId}:`, error);
          return undefined;
        }
      }
    }));

    // Filter out any null values in case of fetch errors and update the users state
    setUsers(updatedUsers.filter(user => user !== undefined));
  };

  // Function to observe messages
  useEffect(() => {
    const subscription = DataStore.observeQuery(Message).subscribe(async snapshot => {
      if (!user) {
        return;
      }
      setChatConversations({});
      const { items } = snapshot;
      for (const newMessage of items) {
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
              // adding
              if (currentMessageNewUser && recipientMessageNewUser) {
                updateChatConversations(newMessage, currentMessageNewUser, recipientMessageNewUser);
              }
            } else {
              console.error("MessageNewUser count isn't 2");
            }
            // Adding message to observed list regardless
            setObservedMessageIDs(prevIDs => new Set([...prevIDs, newMessage.id]));
          } catch (error) {
            console.error('Error fetching MessageNewUser records: ', error);
          }
        }
      }
    });

    return () => subscription.unsubscribe();
  }, [user]); // Re-run if user changes

  // Fetch and update current user
  useEffect(() => {
    // Fetch current user
    const fetchCurrentUser = async () => {
      const user = await getUserById(currentUser.userId); // Assuming currentUser.userId is correct
      if (user) {
        setUser(user);
      }
    };
    fetchCurrentUser();
  }, [currentUser.userId]);

  // Automatically update users list based on chat conversations changes
  useEffect(() => {
    updateAndSortUsers();
  }, [chatConversations]);

  // Sort the keys for a given conversation based on date
  const getSortedConversationKeys = () => {
    return Object.keys(sortOrder).sort((a, b) => new Date(sortOrder[b]) - new Date(sortOrder[a]));
  };

  // Provide context values and methods
  const value = {
    chatConversations,
    users,
    updateChatConversations,
    sortOrder
    // any other value or function you want to expose
  };

  return <ChatContext.Provider value={value}>{children}</ChatContext.Provider>;
};
