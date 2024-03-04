import React, { useEffect, useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import styled from 'styled-components';

import { getPostById, getPostsByUserId, getUserById } from '../../utils/dataStore';
import { getImageURL, getVideoHLSURL } from '../../utils/storage';

import { MediaItem } from './MediaItem';

// Returns an array of CloudFront links that host the relevant media item
async function getMediaItems(post) {
  const userId = post.newuserID;
  const user = await getUserById(userId);

  const linksAndDates = [];
  if (post && user && post.images && post.videos) {
    try {
      for await (const image of post.images) {
        linksAndDates.push((image.uploadDate, getImageURL(user, image.id)));
      }
    } catch (error) {
      console.log(`getMediaItems: Failed to iterate through images, ${error}`);
    }

    try {
      for await (const video of post.videos) {
        linksAndDates.push((video.uploadDate, getVideoHLSURL(user, video.id)));
      }
    } catch (error) {
      console.log(`getMediaItems: Failed to iterate through videos, ${error}`);
    }
  }

  return linksAndDates.sort((a, b) => a < b);
}

export const UserPost = ({ userId }) => {
  const navigate = useNavigate();
  const location = useLocation();
  const queryParams = new URLSearchParams(location.search);
  const [mediaItems, setMediaItems] = useState([]);
  const [posts, setPosts] = useState([]);
  const [postIndex, setPostIndex] = useState(0);

  const postId = queryParams.get('postId');
  const mediaIndex = parseInt(queryParams.get('mediaIndex'));

  const closeOverlay = (e) => {
    queryParams.delete('postId');
    queryParams.delete('mediaIndex');
    const newSearch = `?${queryParams.toString()}`;
    navigate({ search: newSearch });
  };

  // Gets all posts for the given user to allow outer left/right arrows to
  // switch posts
  useEffect(() => {
    if (userId !== undefined) {
      getPostsByUserId(userId)
        .then(data => {
          const sorted = data.sort((a, b) => a.creationDate > b.creationDate);
          setPosts(sorted);

          for (let i = 0; i < data.length; i++) {
            if (postId !== null && data[i].id === postId) {
              setPostIndex(i);
              break;
            }
          }
        });
    }
  }, [userId, postId]);

  // Gets the post currently being viewed
  useEffect(() => {
    if (postId !== null) {
      getPostById(postId)
        .then(data => {
          if (data !== undefined) {
            getMediaItems(data)
              .then(data => {
                setMediaItems(data);
              });
          }
        });
    }
  }, [postId]);

  return (
    <Overlay onClick={closeOverlay}>
      <Wrapper>
        <OuterContent>
          <LeftArrowButton
            onClick={() => {
              queryParams.set('postId', posts[postIndex - 1].id);
              queryParams.set('mediaIndex', 0);
              const newSearch = `?${queryParams.toString()}`;
              navigate({ search: newSearch });
            }}
            itemindex={postIndex}>
            {'<'}
          </LeftArrowButton>

          <InnerContent>
            <LeftArrowButton
              onClick={(e) => {
                e.stopPropagation();
                queryParams.set('mediaIndex', mediaIndex - 1);
                const newSearch = `?${queryParams.toString()}`;
                navigate({ search: newSearch });
              }}
              itemindex={mediaIndex}>
              {'<'}
            </LeftArrowButton>

            {mediaItems[mediaIndex] !== undefined &&
            <MediaWrapper onClick={(e) => e.stopPropagation()}>
              <MediaItem mediaURL={mediaItems[mediaIndex]} />
            </MediaWrapper>
            }

            <RightArrowButton
              onClick={(e) => {
                e.stopPropagation();
                queryParams.set('mediaIndex', mediaIndex + 1);
                const newSearch = `?${queryParams.toString()}`;
                navigate({ search: newSearch });
              }}
              itemindex={mediaIndex}
              itemslength={mediaItems.length}>
              {'>'}
            </RightArrowButton>
          </InnerContent>

          <RightArrowButton
            onClick={(e) => {
              e.stopPropagation();
              queryParams.set('postId', posts[postIndex + 1].id);
              queryParams.set('mediaIndex', 0);
              const newSearch = `?${queryParams.toString()}`;
              navigate({ search: newSearch });
            }}
            itemindex={postIndex}
            itemslength={posts.length}>
            {'>'}
          </RightArrowButton>
        </OuterContent>
      </Wrapper>
    </Overlay>
  );
};

const Wrapper = styled.div`
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    margin: auto;
    width: fit-content;
    height: fit-content;
`;

const OuterContent = styled.div`
    display: flex;
    justify-content: space-between;
    align-items: center;
    width: 98vw;
    height: 98vh;
`;

const InnerContent = styled.div`
    display: flex;
    justify-content: space-evenly;
    align-items: center;
`;

const LeftArrowButton = styled.button`
    visibility: ${props => props.itemindex === 0 ? 'hidden' : 'visible'};
    cursor: pointer;
    margin-right: 10px;
`;

const RightArrowButton = styled.button`
    visibility: ${props => props.itemindex === props.itemslength - 1 ? 'hidden' : 'visible'};
    cursor: pointer;
    margin-left: 10px;
`;

const Overlay = styled.div`
  background-color: rgba(0, 0, 0, 0.5);
  width: 100vw;
  height: 100vh;
  position: fixed;
  top: 0;
  left: 0;
`;

const MediaWrapper = styled.div`
  display: flex;
  justify-content: center;
  align-items: center;
  max-width: 85vw;
  max-height: 85vh;
`;
