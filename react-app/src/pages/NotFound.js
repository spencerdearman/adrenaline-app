import React from 'react';

import { Card, Heading, Text } from '@aws-amplify/ui-react';

const NotFound = () => {
  return (
    <Card>
      <Heading level={1}>Page Not Found</Heading>
      <Text>{"It looks like this page doesn't exist"}</Text>
    </Card>
  );
};

export default NotFound;
