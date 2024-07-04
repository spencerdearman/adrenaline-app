import { DataStore } from 'aws-amplify/datastore';

import * as models from '../models';

export async function getUserById(id) {
  // Query returns a list, so verifying it only returns one item
  const result = await DataStore.query(models.NewUser, (u) => u.id.eq(id));
  if (result.length === 1) {
    return result[0];
  }

  return undefined;
}

export async function getAthleteForUser(user) {
  return await user.athlete;
}

export async function getSearchData() {
  return {
    users: await DataStore.query(models.NewUser),
    meets: await DataStore.query(models.NewMeet),
    teams: await DataStore.query(models.NewTeam),
    colleges: await DataStore.query(models.College)
  };
}

export async function getPostById(postId) {
  // Query returns a list, so verifying it only returns one item
  const result = await DataStore.query(models.Post, (p) => p.id.eq(postId));
  if (result.length === 1) {
    return result[0];
  }

  return undefined;
}

export async function getPostsByUserId(userId) {
  return await DataStore.query(models.Post, (p) => p.newuserID.eq(userId));
}

export async function getFeedPostsByUserIds(ids) {
  const predicates = (c) => ids.map((userId, id) => c.newuserID.eq(userId));
  const allPosts = await DataStore.query(models.Post, (c) =>
    c.or(c => predicates(c))
  );

  // Sorts in descending order on creationDate
  return allPosts.sort((a, b) => {
    return Date.parse(b.creationDate) - Date.parse(a.creationDate);
  });
}
