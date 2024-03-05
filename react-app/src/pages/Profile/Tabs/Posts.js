import React, { useEffect, useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import styled from 'styled-components';

import { Grid } from '@aws-amplify/ui-react';

import { UserPost } from '../../../components/UserPost/UserPost';
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
    // Sort ascending by upload date
    return Date.parse(a.uploadDate) - Date.parse(b.uploadDate);
  })[0];
};

async function getPostDisplays(user, posts) {
  const result = [];
  for (const post of posts) {
    result.push(await getPostDisplay(user, post));
  }

  return result;
};

export const Posts = ({ userId }) => {
  const navigate = useNavigate();
  const location = useLocation();
  const queryParams = new URLSearchParams(location.search);
  const [postDisplays, setPostDisplays] = useState([]);
  const gridSpacing = 5;

  const postId = queryParams.get('postId');
  const mediaIndex = parseInt(queryParams.get('mediaIndex'));

  useEffect(() => {
    if (userId !== undefined) {
      getPostsByUserId(userId)
        .then(data => {
          return data.sort((a, b) => {
            // Sort descending by creation date
            return Date.parse(b.creationDate) - Date.parse(a.creationDate);
          });
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

  // Locks scrolling when a post is selected
  // https://stackoverflow.com/a/74637170/22068672
  useEffect(() => {
    if (postId !== null && mediaIndex !== null) {
      document.body.style.overflow = 'hidden';
    }
    return () => {
      document.body.style.overflow = 'scroll';
    };
  }, [postId, mediaIndex]);

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
                  onClick={() => {
                    queryParams.set('postId', postDisplay.id);
                    queryParams.set('mediaIndex', 0);
                    const newSearch = `?${queryParams.toString()}`;
                    navigate({ search: newSearch });
                  }}
                  key={id}/>
              );
            })
          }
        </Grid>
      </GridWrapper>

      { postId !== null && mediaIndex !== null &&
        <UserPost userId={userId} />
      }

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
