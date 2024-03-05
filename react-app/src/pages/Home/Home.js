import React, { useContext, useEffect, useState } from 'react';

import { Card } from '@aws-amplify/ui-react';

import { CurrentUserContext } from '../../App';
import { FeedPost } from '../../components/FeedPost/FeedPost';
import { getFeedPostsByUserIds, getUserById } from '../../utils/dataStore';

const Home = () => {
  const userContext = useContext(CurrentUserContext);
  const [, setUser] = useState();
  const [feedPosts, setFeedPosts] = useState([]);

  useEffect(() => {
    getUserById(userContext === undefined ? '' : userContext.userId)
      .then(data => {
        setUser(data);
        return data;
      })
      .then(user => {
        // TODO: change this to favorites
        // const favorites = user.favoritesIds;
        // return getFeedPostsByUserIds(favorites);
        return getFeedPostsByUserIds([user.id]);
      })
      .then(posts => {
        setFeedPosts(posts);
      });
  }, [userContext]);

  return (
    <Card>
      {feedPosts && feedPosts.map((post, id) => {
        return (
          <FeedPost postId={post.id} key={id}/>
        );
      })
      }
    </Card>
  );
};

export default Home;
