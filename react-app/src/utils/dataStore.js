import { DataStore } from 'aws-amplify/datastore';

import * as models from '../models';

export async function getUserById(id) {
  return await DataStore.query(models.NewUser, id);
}

export async function getSearchData() {
  return {
    users: await DataStore.query(models.NewUser),
    meets: await DataStore.query(models.NewMeet),
    teams: await DataStore.query(models.NewTeam),
    colleges: await DataStore.query(models.College)
  };
}
