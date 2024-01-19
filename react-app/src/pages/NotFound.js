import React from 'react';
import { Link } from 'react-router-dom';

import { Card, Heading, Text } from '@aws-amplify/ui-react';

import Page from './Page';

const NotFound = () => {
  return (
    <Page>
      <Card>
        <Heading level={1}>Page Not Found</Heading>
        <Text>{"It looks like this page doesn't exist"}</Text>
      </Card>

      <Link to="/">Go to Home</Link>
    </Page>
  );
};

export default NotFound;
