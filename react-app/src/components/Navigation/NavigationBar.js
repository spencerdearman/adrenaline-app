import React, { useContext, useEffect, useState } from 'react';
import styled from 'styled-components';

import { CurrentUserContext } from '../../App';
import chatIcon from '../../assets/images/chat.svg';
import homeIcon from '../../assets/images/home.svg';
import personIcon from '../../assets/images/personCircle.svg';
import trophyIcon from '../../assets/images/trophy.svg';
import { getSearchData, getUserById } from '../../utils/dataStore';
import { getProfilePicUrl } from '../ProfilePic/ProfilePic';
import SearchBar from '../SearchBar/SearchBar';
import { CollegeSearchItem } from '../SearchItem/CollegeSearchItem';
import { MeetSearchItem } from '../SearchItem/MeetSearchItem';
import { TeamSearchItem } from '../SearchItem/TeamSearchItem';
import { UserSearchItem } from '../SearchItem/UserSearchItem';

import NavigationButton from './NavigationButton';

function CustomNavigationBar ({ children }) {
  return (
    <ButtonsWrapper>
      {children}
    </ButtonsWrapper>
  );
};

function processSearchData ({ users, meets, teams, colleges }) {
  return users.map((user) => { return new UserSearchItem(user); }).concat(
    meets.map((meet) => { return new MeetSearchItem(meet); }).concat(
      teams.map((team) => { return new TeamSearchItem(team); }).concat(
        colleges.map((college) => { return new CollegeSearchItem(college); })
      )
    )
  );
}

const NavigationBar = () => {
  const userContext = useContext(CurrentUserContext);
  const [user, setUser] = useState();
  const [searchData, setSearchData] = useState();

  useEffect(() => {
    getUserById(userContext === undefined ? '' : userContext.userId)
      .then(data => {
        setUser(data);
      });
  }, [userContext]);

  useEffect(() => {
    getSearchData()
      .then(data => {
        setSearchData(processSearchData(data));
      });
  }, []);

  const profileUrl = `/profile/${userContext === undefined ? '' : userContext.userId}`;
  const profileIconSrc = user === undefined ? personIcon : getProfilePicUrl(user.id);

  return (
    <CustomNavigationBar>
      <NavigationButton imageSrc={homeIcon} title="Home" href="/" />
      <NavigationButton imageSrc={chatIcon} title="Chat" href="/chat" />
      <NavigationButton imageSrc={trophyIcon} title="Rankings" href="/rankings" />
      <SearchBar searchData={searchData}/>
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
