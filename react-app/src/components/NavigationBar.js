import React from 'react';
import styled from 'styled-components';

import homeIcon from '../assets/home.svg';
import personIcon from '../assets/person.svg';

import NavigationButton from './NavigationButton';

function CustomNavigationBar ({ children }) {
  return (
    <Wrapper>
      <ButtonsWrapper>
        {children}
      </ButtonsWrapper>
    </Wrapper>
  );
};

const NavigationBar = () => {
  return (
    <CustomNavigationBar>
      <NavigationButton imageSrc={homeIcon} title="Home" href="/" />
      <NavigationButton imageSrc={personIcon} title="Profile 123" href="/profile/123" />
    </CustomNavigationBar>
  );
};

export default NavigationBar;

const Wrapper = styled.div`
    margin: 0 auto;
`;

const ButtonsWrapper = styled.div`
    display: flex;
    justify-items: space-between;
    justify-content: center;
`;
