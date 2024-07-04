import React, { useEffect, useState } from 'react';
import styled from 'styled-components';

import { Text } from '@aws-amplify/ui-react';

import { getPostById, getUserById } from '../../utils/dataStore';
import { getImageURL, getVideoHLSURL } from '../../utils/storage';
import { MediaItem } from '../MediaItem/MediaItem';
import { LeftArrowButton, RightArrowButton } from '../styles/buttons';
import { MediaWrapper, TextWrapper } from '../styles/divs';

// Returns an array of CloudFront links that host the relevant media item
async function getMediaItems(post) {
  const userId = post.newuserID;
  const user = await getUserById(userId);

  const linksAndDates = [];
  if (post && user && post.images && post.videos) {
    try {
      for await (const image of post.images) {
        linksAndDates.push({
          uploadDate: image.uploadDate,
          url: getImageURL(user, image.id)
        });
      }
    } catch (error) {
      console.log(`getMediaItems: Failed to iterate through images, ${error}`);
    }

    try {
      for await (const video of post.videos) {
        linksAndDates.push({
          uploadDate: video.uploadDate,
          url: getVideoHLSURL(user, video.id)
        });
      }
    } catch (error) {
      console.log(`getMediaItems: Failed to iterate through videos, ${error}`);
    }
  }

  return linksAndDates.sort((a, b) => {
    // Sort ascending by upload date
    return Date.parse(a.uploadDate) - Date.parse(b.uploadDate);
  });
}

export const FeedPost = ({ postId }) => {
  const [caption, setCaption] = useState();
  const [mediaItems, setMediaItems] = useState([]);
  const [mediaIndex, setMediaIndex] = useState(0);

  // Gets the post currently being viewed
  useEffect(() => {
    if (postId !== null) {
      getPostById(postId)
        .then(data => {
          if (data !== undefined) {
            setCaption(data.caption);
            getMediaItems(data)
              .then(data => {
                setMediaItems(data.map((a) => a.url));
              });
          }
        });
    }
  }, [postId]);

  return (
    <InnerContent>
      <LeftArrowButton
        onClick={() => setMediaIndex(mediaIndex - 1)}
        itemindex={mediaIndex}>
        {'<'}
      </LeftArrowButton>

      {mediaItems[mediaIndex] !== undefined &&
              <MediaWrapper style={{ marginBottom: 20 }}>
                <MediaItem mediaURL={mediaItems[mediaIndex]} playing={false} />
                {caption &&
                caption.length > 0 &&
                <TextWrapper>
                  <Text textAlign={'start'}>{caption}</Text>
                </TextWrapper>
                }
              </MediaWrapper>
      }

      <RightArrowButton
        onClick={() => setMediaIndex(mediaIndex + 1)}
        itemindex={mediaIndex}
        itemslength={mediaItems.length}>
        {'>'}
      </RightArrowButton>
    </InnerContent>
  );
};

const InnerContent = styled.div`
    display: flex;
    justify-content: space-evenly;
    align-items: center;
`;
