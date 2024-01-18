import React from 'react';
import styled from 'styled-components';

import NavigationBar from '../components/NavigationBar';

// Wrapping elements in <Page> tags will add the NavigationBar to the top
export default function Page ({ children }) {
  return (
    <Wrapper>
      <NavigationBar />

      {children}
    </Wrapper>
  );
};

const Wrapper = styled.div`
    padding-top: 0px;
    margin: 0 auto;
    text-align: center;
    align-items: center;
`;
