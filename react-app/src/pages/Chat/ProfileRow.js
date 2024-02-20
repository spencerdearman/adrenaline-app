import React from 'react';
import { useNavigate } from 'react-router-dom';
import styled from 'styled-components';

import { ProfilePic } from '../../components/ProfilePic/ProfilePic';

const ProfileRow = ({ currentUserId, recipient, messages }) => {
  const navigate = useNavigate();
  // add newMessagesBool back in eventually
  //   const [, setNewMessagesBool] = useState(false);

  //   useEffect(() => {
  //     const fetchData = async () => {
  //       const recipientData = await getUserById(profileId);
  //       if (recipientData) {
  //         setUser(recipientData);
  //         // Check if there are new messages for this recipient
  //         // setNewMessagesBool(newMessages.has(recipientData.id));
  //       }
  //     };

  //     fetchData();
  //   }, [profileId, newMessages]);

  if (!recipient) {
    return <div>Loading...</div>; // or any other loading indicator
  }

  return (
    <Row onClick={() => navigate(`/chat/${currentUserId}/${recipient.id}`)}>
      <ProfilePicWrapper>
        <ProfilePic id={recipient.id} />
      </ProfilePicWrapper>
      <UserInfo>
        <AccountType>{recipient.accountType}</AccountType>
        <UserName>{recipient.firstName} {recipient.lastName}</UserName>
      </UserInfo>
    </Row>
  );
};

export default ProfileRow;

const Row = styled.div`
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 12px;
  cursor: pointer;
  width: fit-content;
  margin: auto;
`;

const ProfilePicWrapper = styled.div`
  display: flex;
  width: 100px;
  aspect-ratio: 1;
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
