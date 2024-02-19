import React, { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import styled from 'styled-components';

import { Heading } from '@aws-amplify/ui-react';

import { getPostById, getPostsByUserId, getUserById } from '../../utils/dataStore';
import { getImageURL, getVideoHLSURL } from '../../utils/storage';

// Returns an array of CloudFront links that host the relevant media item
async function getMediaItems(post) {
  const userId = post.newuserID;
  const user = await getUserById(userId);
  const images = await post.images;
  const videos = await post.videos;

  const linksAndDates = [];
  if (images !== undefined) {
    try {
      for (const image of images) {
        linksAndDates.push((image.uploadDate, getImageURL(user, image.id)));
      }
    } catch (error) {
      console.log(`getMediaItems: Failed to iterate through images, ${error}`);
    }
  }

  if (videos !== undefined) {
    try {
      for (const video of videos) {
        linksAndDates.push((video.uploadDate, getVideoHLSURL(user, video.id)));
      }
    } catch (error) {
      console.log(`getMediaItems: Failed to iterate through videos, ${error}`);
    }
  }

  return linksAndDates.sort((a, b) => a < b);
}

export const UserPost = () => {
  const navigate = useNavigate();
  const { userId, postId } = useParams();
  const [mediaItems, setMediaItems] = useState([]);
  const [posts, setPosts] = useState([]);
  const [post, setPost] = useState();
  const [mediaItemIndex, setMediaItemIndex] = useState(0);
  const [postIndex, setPostIndex] = useState(0);

  // Gets all posts for the given user to allow outer left/right arrows to
  // switch posts
  useEffect(() => {
    if (userId !== undefined) {
      getPostsByUserId(userId)
        .then(data => {
          const sorted = data.sort((a, b) => a.creationDate > b.creationDate);
          console.log(sorted);
          setPosts(sorted);

          for (let i = 0; i < data.length; i++) {
            if (data[i].id === postId) {
              setPostIndex(i);
            }
          }
        });
    }
  }, [userId, postId]);

  // Gets the post currently being viewed
  useEffect(() => {
    getPostById(postId)
      .then(data => {
        setPost(data);
      });

    if (post !== undefined) {
      getMediaItems(post)
        .then(data => {
          setMediaItems(data);
        });
    }
  }, [postId]);

  return (
    <Wrapper>
      <Heading level={2}>{userId}</Heading>
      <Heading level={2}>{postId}</Heading>
      <Heading level={3}>{mediaItemIndex}</Heading>
      <DimmedWrapper />

      <OuterContent>
        <LeftArrowButton
          onClick={() => navigate(`/post/${userId}/${posts[postIndex - 1].id}`)}
          itemindex={postIndex}>
          {'<'}
        </LeftArrowButton>

        <InnerContent>
          <LeftArrowButton
            onClick={() => setMediaItemIndex(mediaItemIndex - 1)}
            itemindex={mediaItemIndex}>
            {'<'}
          </LeftArrowButton>

          {/* TODO: HLS Stream or image goes here */}
          <p style={{ padding: 20 }}>
            {mediaItems[mediaItemIndex] !== undefined
              ? mediaItems[mediaItemIndex].id
              : 'undefined'}
          </p>

          <RightArrowButton
            onClick={() => setMediaItemIndex(mediaItemIndex + 1)}
            itemindex={mediaItemIndex}
            itemslength={mediaItems.length}>
            {'>'}
          </RightArrowButton>
        </InnerContent>

        <RightArrowButton
          onClick={() => navigate(`/post/${userId}/${posts[postIndex + 1].id}`)}
          itemindex={postIndex}
          itemslength={posts.length}>
          {'>'}
        </RightArrowButton>
      </OuterContent>
    </Wrapper>
  );
};

const Wrapper = styled.div`
    display: flex;
    align-items: center;
    flex-direction: column;
`;

const DimmedWrapper = styled.div`
    fill: black;
    fill-opacity: 0.1;
    width: 100%;
    height: 100%;
`;

const OuterContent = styled.div`
    display: flex;
    justify-content: space-between;
`;

const InnerContent = styled.div`
    display: flex;
    justify-content: space-evenly;
    padding: 20px;
`;

const LeftArrowButton = styled.button`
    visibility: ${props => props.itemindex === 0 ? 'hidden' : 'visible'};
    cursor: pointer;
`;

const RightArrowButton = styled.button`
    visibility: ${props => props.itemindex === props.itemslength - 1 ? 'hidden' : 'visible'};
    cursor: pointer;
`;
