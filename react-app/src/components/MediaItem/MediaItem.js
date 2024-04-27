import React from 'react';
import ReactPlayer from 'react-player';
import styled from 'styled-components';

export const MediaItem = ({ mediaURL, playing = false, loop = true }) => {
  if (mediaURL === undefined) {
    return;
  }

  if (mediaURL.includes('.jpg')) {
    return <Image src={mediaURL}/>;
  } else {
    return (
      <ReactPlayer
        playing={playing}
        loop={loop}
        controls={true}
        url={mediaURL}
        width='100%'
        height='75vh'
      />
    );
  }
};

const Image = styled.img`
  width: auto;
  max-height: 75vh;
`;
