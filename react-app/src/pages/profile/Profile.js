import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import styled from 'styled-components';

import { Button, Card, Heading } from '@aws-amplify/ui-react';

import mapPinIcon from '../../assets/images/mapPin.svg';
import personIcon from '../../assets/images/person.svg';
import { CustomDivider } from '../../components/CustomDivider/CustomDivider';
import { ProfilePic } from '../../components/ProfilePic/ProfilePic';
import { getAthleteForUser, getUserById } from '../../utils/dataStore';

import { Favorites } from './Tabs/Favorites';
import { Posts } from './Tabs/Posts';
import { Recruiting } from './Tabs/Recruiting';
import { Results } from './Tabs/Results';
import { Saved } from './Tabs/Saved';
import { ProfileTabSelector } from './ProfileTabSelector';

import '../../assets/css/index.css';

const grayColor = '#777';
// TODO: Make this dynamic based on viewer of profile
const profileTabs = ['Posts', 'Results', 'Recruiting', 'Saved', 'Favorites'];

const PROFILE_TAB_OBJECTS = {
  posts: <Posts />,
  results: <Results />,
  recruiting: <Recruiting />,
  saved: <Saved />,
  favorites: <Favorites />,
  default: <div />
};

const Profile = (props) => {
  const { profileId } = useParams();
  const [user, setUser] = useState();
  const [athlete, setAthlete] = useState();
  const [name, setName] = useState();
  const [diveMeetsID, setDiveMeetsID] = useState();
  const [tabSelection, setTabSelection] = useState('posts');

  // Set user and DiveMeets ID
  useEffect(() => {
    getUserById(profileId)
      .then(data => {
        if (data !== undefined) {
          setUser(data);
          setName(data.firstName + ' ' + data.lastName);
          setDiveMeetsID(data.diveMeetsID);
        }
      });
  }, [profileId]);

  // Get and set athlete
  useEffect(() => {
    getAthleteForUser(user)
      .then(data => {
        setAthlete(data);
      });
  }, [user]);

  return (
    <Card>
      <BasicInfo>
        <RowItems style={{ paddingBottom: 0 }}>
          <Column>
            {diveMeetsID !== undefined &&
                <ProfilePic id={diveMeetsID} />
            }
          </Column>

          <Column>
            <JustifyLeft>
              <RowItems style={{ borderBottom: `${athlete !== undefined ? `0.5px solid ${grayColor}` : 'none'}` }}>
                <NameType>
                  <Name>
                    <Heading level={2} fontWeight={'bold'}>{name}</Heading>
                  </Name>

                  <Heading level={4} fontWeight={'normal'} color={grayColor}>{user !== undefined ? user.accountType : ''}</Heading>
                </NameType>
              </RowItems>
            </JustifyLeft>

            {/* Only show hometown and age if athlete is not undefined */}
            { athlete && athlete.hometown && athlete.age &&
            <RowItems>
              <BottomLineItem>
                <Icon src={mapPinIcon} />
                <Hometown>
                  <Heading level={4} fontWeight={'normal'}>{athlete.hometown}</Heading>
                </Hometown>
              </BottomLineItem>
              <BottomLineItem>
                <Icon src={personIcon} />
                <Age>
                  <Heading level={4} fontWeight={'normal'}>{athlete.age}</Heading>
                </Age>
              </BottomLineItem>
            </RowItems> }
          </Column>
        </RowItems>
      </BasicInfo>

      <CustomDivider marginTop={25} />

      <ProfileTabSelector tabs={profileTabs} tabSelection={tabSelection} setTabSelection={setTabSelection} />
      {tabSelection && PROFILE_TAB_OBJECTS[tabSelection]}

      <CustomDivider />

      <Button onClick={props.signOut}>Sign Out</Button>
    </Card>
  );
};

export default Profile;

const BasicInfo = styled.div`
  width: 100%;
  display: flex;
  align-items: center;
`;

const RowItems = styled.div`
  display: flex;
  width: max-content;
  align-items: center;
  flex-direction: row;  
  margin: 0 auto;
  padding: 5px 10px;
`;

const Column = styled.div`
  display: flex;
  flex-direction: column;
  padding: 0 30px;
`;

const JustifyLeft = styled.div`
  align-self: start;
`;

const NameType = styled.div`
  display: flex;
  align-items: baseline;
`;

const Name = styled.div`
  padding-right: 20px;
`;

const Icon = styled.img`
  width: auto;
  width: 24px;
  height: 100%;
  height: 24px;
  margin: 0 auto;
  object-fit: cover;
`;

const BottomLineItem = styled.div`
  display: flex;
  align-items: center;
  padding: 0 15px;
`;

const Hometown = styled.div`
  padding: 0 5px;
`;

const Age = styled.div`
  padding: 0 5px;
`;
