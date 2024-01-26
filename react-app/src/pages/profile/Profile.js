import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';

import { Button, Card, Heading } from '@aws-amplify/ui-react';

import { ProfilePic } from '../../components/ProfilePic/ProfilePic';
import { getUserById } from '../../utils/dataStore';

const Profile = (props) => {
  const { profileId } = useParams();
  const [, setUser] = useState();
  const [name, setName] = useState();
  const [diveMeetsID, setDiveMeetsID] = useState();
  useEffect(() => {
    getUserById(profileId)
      .then(data => {
        if (data !== undefined) {
          setUser(data);
          setName(data.firstName + ' ' + data.lastName);
          setDiveMeetsID(data.diveMeetsID);
        }
      });
  }, [profileId]);

  return (
    <Card>
      {diveMeetsID !== undefined &&
          <ProfilePic id={diveMeetsID} />
      }
      <Heading level={1}>Profile</Heading>
      <Heading level={2}>{name}</Heading>
      <Heading level={3}>{diveMeetsID}</Heading>

      <Button onClick={props.signOut}>Sign Out</Button>
    </Card>
  );
};

export default Profile;
