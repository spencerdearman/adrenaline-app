import React from 'react';
import styled from 'styled-components';

import ComingSoon from './pages/ComingSoon';

import './App.css';
import '@aws-amplify/ui-react/styles.css';

function ComingSoonApp() {
  return (
    <Wrapper>
      <ComingSoon />
    </Wrapper>
  );
};

export default ComingSoonApp;

const Wrapper = styled.div`
    padding: 20px;
    margin: 0 auto;
    text-align: center;
`;
