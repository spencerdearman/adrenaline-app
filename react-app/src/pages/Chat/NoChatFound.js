import React from 'react';

import { Card, Heading, Text } from '@aws-amplify/ui-react';

const NoChatFound = () => {
  return (
    <Card>
      <Heading level={1}>Chat Not Found</Heading>
      <Text>{"It looks like this chat doesn't exist."}</Text>
    </Card>
  );
};

export default NoChatFound;
