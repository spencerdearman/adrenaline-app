import { DataStore } from 'aws-amplify/datastore';

import * as models from '../models';

export async function getUserById(id) {
  return await DataStore.query(models.NewUser, id);
}
