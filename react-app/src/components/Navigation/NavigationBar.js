import React, { useContext } from 'react';
import styled from 'styled-components';

import { CurrentUserContext } from '../../App';
import chatIcon from '../../assets/images/chat.svg';
import homeIcon from '../../assets/images/home.svg';
import personIcon from '../../assets/images/person.svg';
import trophyIcon from '../../assets/images/trophy.svg';

import NavigationButton from './NavigationButton';

function CustomNavigationBar ({ children }) {
  return (
    <ButtonsWrapper>
      {children}
    </ButtonsWrapper>
  );
};

const NavigationBar = () => {
  const user = useContext(CurrentUserContext);
  const profileUrl = `/profile/${user.userId}`;
  return (
    <CustomNavigationBar>
      <NavigationButton imageSrc={homeIcon} title="Home" href="/" />
      <NavigationButton imageSrc={chatIcon} title="Chat" href="/chat" />
      <NavigationButton imageSrc={trophyIcon} title="Rankings" href="/rankings" />
      <NavigationButton imageSrc={personIcon} title="Profile" href={profileUrl} />
    </CustomNavigationBar>
  );
};

export default NavigationBar;

const ButtonsWrapper = styled.div`
    display: flex;
    justify-items: space-between;
    justify-content: center;
    margin: 0 auto;
`;
