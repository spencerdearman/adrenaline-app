import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import styled from 'styled-components';

import { Grid } from '@aws-amplify/ui-react';

import { getPostsByUserId, getUserById } from '../../../utils/dataStore';
import { getImageURL, getVideoThumbnailURL } from '../../../utils/storage';

async function getPostDisplay(user, post) {
  const result = [];

  for await (const video of post.videos) {
    result.push({
      id: post.id,
      uploadDate: video.uploadDate,
      thumbnailURL: getVideoThumbnailURL(user, video.id)
    });
  }

  for await (const image of post.images) {
    result.push({
      id: post.id,
      uploadDate: image.uploadDate,
      thumbnailURL: getImageURL(user, image.id)
    });
  }

  if (result.length === 0) {
    return undefined;
  }

  return result.sort((a, b) => {
    return a.uploadDate > b.uploadDate;
  })[0];
};

async function getPostDisplays(user, posts) {
  const result = [];
  for (const post of posts) {
    console.log('post', JSON.stringify(post));
    result.push(await getPostDisplay(user, post));
  }

  return result;
};

export const Posts = ({ userId }) => {
  const navigate = useNavigate();
  const [postDisplays, setPostDisplays] = useState([]);
  const gridSpacing = 5;

  useEffect(() => {
    if (userId !== undefined) {
      getPostsByUserId(userId)
        .then(data => {
          return data.sort((a, b) => a.creationDate > b.creationDate);
        })
        .then(posts => {
          getUserById(userId)
            .then(user => {
              if (user !== undefined) {
                getPostDisplays(user, posts)
                  .then((data) => setPostDisplays(data));
              }
            });
        });
    }
  }, [userId]);

  return (
    <Wrapper>
      <GridWrapper>
        <Grid
          rowGap={gridSpacing}
          columnGap={gridSpacing}
          templateColumns={{ base: '1fr 1fr', medium: '1fr 1fr', large: '1fr 1fr 1fr' }}>
          {
            postDisplays.map((postDisplay, id) => {
              return (
                <Image
                  src={postDisplay.thumbnailURL}
                  onClick={() => navigate(`/post/${userId}/${postDisplay.id}`)}
                  key={id}/>
              );
            })
          }
        </Grid>
      </GridWrapper>
    </Wrapper>
  );
};

const Wrapper = styled.div`
  display: flex;
  flex-direction: column;
  align-items: center;
`;

const GridWrapper = styled.div`
  margin: 20px;
`;

const Image = styled.img`
  width: 100%;
  aspect-ratio: 1;
  cursor: pointer;
`;
