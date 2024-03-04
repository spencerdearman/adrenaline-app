import React from 'react';
import ReactPlayer from 'react-player';
import styled from 'styled-components';

export const MediaItem = ({ mediaURL }) => {
  if (mediaURL === undefined) {
    return;
  }

  if (mediaURL.includes('.jpg')) {
    return <Image src={mediaURL}/>;
  } else {
    return (
      <ReactPlayer
        playing={true}
        loop={true}
        controls={true}
        url={mediaURL}
        width='100%'
        height='75vh'
      />
    );
  }
};

const Image = styled.img`
  width: 100%;
  max-height: 75vh;
  aspect-ratio: 1;
`;
