import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';

import { Heading } from '@aws-amplify/ui-react';

import { getPostById, getUserById } from '../../utils/dataStore';
import { getImageURL, getVideoHLSURL } from '../../utils/storage';

// Returns an array of CloudFront links that host the relevant media item
async function getMediaItems(post) {
  const userId = post.newuserID;
  const user = await getUserById(userId);
  const images = await post.images;
  const videos = await post.videos;

  const linksAndDates = [];
  for (const image of images) {
    linksAndDates.push((image.uploadDate, getImageURL(user, image.id)));
  }
  for (const video of videos) {
    linksAndDates.push((video.uploadDate, getVideoHLSURL(user, video.id)));
  }

  return linksAndDates.sort((a, b) => a < b);
}

export const UserPost = () => {
  const { userId, postId } = useParams();
  const [post, setPost] = useState();
  const [mediaItems, setMediaItems] = useState([]);

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
    <div>
      <Heading level={2}>{userId}</Heading>
      <Heading level={2}>{postId}</Heading>

      {
        mediaItems.map((item, id) => {
          return (<p key={id}>{item}</p>);
        })
      }
    </div>
  );
};
