import React from 'react';
import styled from 'styled-components';

export function getProfilePicUrl(id) {
  return `https://secure.meetcontrol.com/divemeets/system/profilephotos/${id}.jpg`;
}

export function ProfilePic ({ id }) {
  return (
    <Image src={getProfilePicUrl(id)} />
  );
};

const Image = styled.img`
    width: auto;
    height: 100%;
    object-fit: cover;
    border: 8px solid #ddd;
    border-radius: 50%;
    box-shadow: 0px 0px 15px rgba(0, 0, 0, 0.4);
`;
