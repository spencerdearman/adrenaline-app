import React from 'react';

import { Button, Card, Heading } from '@aws-amplify/ui-react';

import Page from '../Page';

const Profile = (props) => {
  return (
        <Page>
            <Card>
                <Heading level={1}>Profile</Heading>
            </Card>

            <Button onClick={props.signOut}>Sign Out</Button>
        </Page>
  );
};

export default Profile;
