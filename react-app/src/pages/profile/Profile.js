import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';

import { Button, Card, Heading } from '@aws-amplify/ui-react';

import { getUserById } from '../../utils/dataStore';

async function getUserFullName (username) {
  const user = await getUserById(username);
  return user.firstName + ' ' + user.lastName;
};

const Profile = (props) => {
  const { profileId } = useParams();
  const [name, setName] = useState();
  useEffect(() => {
    getUserFullName(profileId)
      .then(data =>
        setName(data)
      );
  }, [profileId]);

  return (
    <Card>
      <Heading level={1}>Profile</Heading>
      <Heading level={2}>{name}</Heading>

      <Button onClick={props.signOut}>Sign Out</Button>
    </Card>
  );
};

export default Profile;
