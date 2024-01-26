import React, { useContext, useEffect, useState } from 'react';
import styled from 'styled-components';

import { CurrentUserContext } from '../../App';
import chatIcon from '../../assets/images/chat.svg';
import homeIcon from '../../assets/images/home.svg';
import personIcon from '../../assets/images/person.svg';
import trophyIcon from '../../assets/images/trophy.svg';
import { getUserById } from '../../utils/dataStore';
import { getProfilePicUrl } from '../ProfilePic/ProfilePic';
import SearchBar from '../SearchBar/SearchBar';

import NavigationButton from './NavigationButton';

function CustomNavigationBar ({ children }) {
  return (
    <ButtonsWrapper>
      {children}
    </ButtonsWrapper>
  );
};

const NavigationBar = () => {
  const userContext = useContext(CurrentUserContext);
  const [, setUser] = useState();
  const [diveMeetsID, setDiveMeetsID] = useState();

  useEffect(() => {
    getUserById(userContext.userId)
      .then(data => {
        setUser(data);
        setDiveMeetsID(data.diveMeetsID);
      });
  }, [userContext]);

  const profileUrl = `/profile/${userContext.userId}`;
  const profileIconSrc = diveMeetsID === undefined ? personIcon : getProfilePicUrl(diveMeetsID);

  return (
    <CustomNavigationBar>
      <NavigationButton imageSrc={homeIcon} title="Home" href="/" />
      <NavigationButton imageSrc={chatIcon} title="Chat" href="/chat" />
      <NavigationButton imageSrc={trophyIcon} title="Rankings" href="/rankings" />
      <SearchBar />
      <NavigationButton imageSrc={profileIconSrc} title="Profile" href={profileUrl} />
    </CustomNavigationBar>
  );
};

export default NavigationBar;

const ButtonsWrapper = styled.div`
    display: flex;
    justify-items: space-between;
    justify-content: center;
    margin: 0 auto;
    align-items: center;
    margin-bottom: 20px;
`;
