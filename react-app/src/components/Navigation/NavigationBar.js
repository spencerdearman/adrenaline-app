import React from 'react';
import styled from 'styled-components';

import chatIcon from '../../assets/images/chat.svg';
import homeIcon from '../../assets/images/home.svg';
import personIcon from '../../assets/images/person.svg';
import trophyIcon from '../../assets/images/trophy.svg';

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
      <NavigationButton imageSrc={chatIcon} title="Chat" href="/chat" />
      <NavigationButton imageSrc={trophyIcon} title="Rankings" href="/rankings" />
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
