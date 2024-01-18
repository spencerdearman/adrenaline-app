import React from 'react';

import { Card, Heading } from '@aws-amplify/ui-react';

import Page from '../Page';

const Home = () => {
  return (
        <Page>
            <Card>
                <Heading level={1}>Home</Heading>
            </Card>
        </Page>
  );
};

export default Home;
