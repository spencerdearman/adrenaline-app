import React from 'react';
import styled from 'styled-components';

import defaultProfileIcon from '../../assets/images/defaultProfileIcon.png';

const CLOUDFRONT_PROFILE_PICS_BASE_URL = 'https://dh68pb7jazk5m.cloudfront.net';

export function getProfilePicUrl(id) {
  return `${CLOUDFRONT_PROFILE_PICS_BASE_URL}/${id}.jpg`;
}

export function ProfilePic ({ id }) {
  return (
    <Image src={getProfilePicUrl(id)} onError={({ currentTarget }) => {
      currentTarget.onerror = null;
      currentTarget.src = defaultProfileIcon;
    }} />
  );
};

const Image = styled.img`
    width: auto;
    max-width: 200px;
    height: 100%;
    object-fit: cover;
    border: 8px solid #ddd;
    border-radius: 50%;
    box-shadow: 0px 0px 15px rgba(0, 0, 0, 0.4);
`;
