import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import styled from 'styled-components';

import { ProfilePic } from '../../components/ProfilePic/ProfilePic';
import { getUserById } from '../../utils/dataStore';

const ProfileRow = ({ newMessages }) => {
  const { profileId } = useParams();
  const [user, setUser] = useState(null);
  // add newMessagesBool back in eventually
  //   const [, setNewMessagesBool] = useState(false);

  useEffect(() => {
    const fetchData = async () => {
      const userData = await getUserById(profileId);
      if (userData) {
        setUser(userData);
        // Check if there are new messages for this user
        // setNewMessagesBool(newMessages.has(userData.id));
      }
    };

    fetchData();
  }, [profileId, newMessages]);

  if (!user) {
    return <div>Loading...</div>; // or any other loading indicator
  }

  return (
    <Row>
      <ProfilePicWrapper>
        <ProfilePic id={profileId} />
      </ProfilePicWrapper>
      <UserInfo>
        <AccountType>{user.accountType}</AccountType>
        <UserName>{user.firstName} {user.lastName}</UserName>
        {/* Here you could add more user info or indicators */}
      </UserInfo>
      {/* Optionally, include the new messages indicator or circular progress view here */}
    </Row>
  );
};

export default ProfileRow;

const Row = styled.div`
  display: flex;
  align-items: center;
  padding: 12px;
`;

const ProfilePicWrapper = styled.div`
  position: relative;
  width: 36px;
  height: 36px;
  border-radius: 50%;
  overflow: hidden;
  padding: 12px;
  background: rgba(255, 255, 255, 0.3); /* Adjust based on your theme */
`;

const UserInfo = styled.div`
  display: flex;
  flex-direction: column;
  margin-left: 16px;
`;

const AccountType = styled.div`
  font-size: 14px;
  color: #6e6e6e; /* Secondary text color */
`;

const UserName = styled.div`
  font-weight: bold;
`;
