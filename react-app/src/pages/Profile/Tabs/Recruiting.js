import React, { useEffect, useState } from 'react';
import styled from 'styled-components';

import { Heading } from '@aws-amplify/ui-react';

import { getAthleteForUser, getUserById } from '../../../utils/dataStore';

export const Recruiting = ({ userId }) => {
  const [user, setUser] = useState();
  const [athlete, setAthlete] = useState();

  // Set user
  useEffect(() => {
    getUserById(userId)
      .then(data => {
        if (data !== undefined) {
          setUser(data);
        }
      });
  }, [userId]);

  // Get and set athlete
  useEffect(() => {
    if (user !== undefined) {
      getAthleteForUser(user)
        .then(data => {
          setAthlete(data);
        });
    }
  }, [user]);

  return (
    <div>
      {athlete && (
        <Wrapper>
          <Heading level={5}>{`Height: ${athlete.heightFeet}' ${athlete.heightInches}"`}</Heading>
          <Heading level={5}>{`Weight: ${athlete.weight} ${athlete.weightUnit}`}</Heading>
          <Heading level={5}>{`Gender: ${athlete.gender}`}</Heading>
          <Heading level={5}>{`Age: ${athlete.age}`}</Heading>
          <Heading level={5}>{`Graduation Year: ${athlete.graduationYear}`}</Heading>
          <Heading level={5}>{`High School: ${athlete.highSchool}`}</Heading>
          <Heading level={5}>{`Hometown: ${athlete.hometown}`}</Heading>
          <Heading level={5}>{`Springboard Rating: ${athlete.springboardRating}`}</Heading>
          <Heading level={5}>{`Platform Rating: ${athlete.platformRating}`}</Heading>
          <Heading level={5}>{`Total Rating: ${athlete.totalRating}`}</Heading>
        </Wrapper>
      )
      }
    </div>
  );
};

const Wrapper = styled.div`
  display: flex;
  flex-direction: column;
`;
