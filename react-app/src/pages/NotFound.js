import React from 'react';

import { Card, Heading, Text } from '@aws-amplify/ui-react';

import Page from './Page';

const NotFound = () => {
  return (
    <Page>
      <Card>
        <Heading level={1}>Page Not Found</Heading>
        <Text>{"It looks like this page doesn't exist"}</Text>
      </Card>
    </Page>
  );
};

export default NotFound;
