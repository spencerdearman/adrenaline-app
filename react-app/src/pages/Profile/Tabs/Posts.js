import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import styled from 'styled-components';

import { Grid } from '@aws-amplify/ui-react';

import { getPostsByUserId } from '../../../utils/dataStore';

export const Posts = ({ userId }) => {
  const navigate = useNavigate();
  const [posts, setPosts] = useState([]);

  useEffect(() => {
    if (userId !== undefined) {
      getPostsByUserId(userId)
        .then(data => {
          const sorted = data.sort((a, b) => a.creationDate > b.creationDate);
          console.log(sorted);
          setPosts(sorted);
        });
    }
  }, [userId]);

  return (
    <Wrapper>
      <GridWrapper>
        <Grid rowGap={20} columnGap={20} templateColumns={{ base: '1fr 1fr', medium: '1fr 1fr', large: '1fr 1fr 1fr' }}>
          {
            posts.map((post, id) => {
              return (
                <Button onClick={() => navigate(`/post/${post.id}`)} key={id}>{post.id}</Button>
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

const Button = styled.button`
  width: auto;
  aspect-ratio: 1;
  border: 1px solid black;
  cursor: pointer;
`;
