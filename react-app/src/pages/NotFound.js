import React from 'react';
import { Link } from 'react-router-dom';
import styled from 'styled-components';

import { Card, Heading, Text } from '@aws-amplify/ui-react';

const NotFound = () => {
  return (
        <Wrapper>
            <Card>
                <Heading level={1}>Page Not Found</Heading>
                <Text>{"It looks like this page doesn't exist"}</Text>
            </Card>

            <Link to="/">Go to Home</Link>
        </Wrapper>
  );
};

export default NotFound;

const Wrapper = styled.div`
    padding-top: 150px;
    margin: 0 auto;
    text-align: center;
`;
