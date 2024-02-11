import React from 'react';

import { Card, Heading, Text } from '@aws-amplify/ui-react';

const ComingSoon = () => {
  return (
    <Card>
      <Heading level={1}>Coming Soon</Heading>
      <Text>{'Adrenaline Recruiting will be available for all users on \
      July 1st, 2024'}</Text>
    </Card>
  );
};

export default ComingSoon;
