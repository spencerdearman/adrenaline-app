import React from 'react';
import { Amplify } from 'aws-amplify';
import { DataStore } from 'aws-amplify/datastore';
import { Hub } from 'aws-amplify/utils';
import ReactDOM from 'react-dom/client';

import amplifyconfig from './amplifyconfiguration.json';
import App from './App';
import ComingSoonApp from './ComingSoonApp';
import reportWebVitals from './reportWebVitals';

import './assets/css/index.css';

const devMode = false;

Amplify.configure(amplifyconfig);

Hub.listen('auth', async ({ payload }) => {
  switch (payload.event) {
  case 'signedIn':
    console.log('user have been signedIn successfully.');
    await DataStore.start();
    break;
  case 'signedOut':
    console.log('user have been signedOut successfully.');
    await DataStore.clear();
    break;
  case 'tokenRefresh':
    console.log('auth tokens have been refreshed.');
    break;
  case 'tokenRefresh_failure':
    console.log('failure while refreshing auth tokens.');
    break;
  case 'signInWithRedirect':
    console.log('signInWithRedirect API has successfully been resolved.');
    break;
  case 'signInWithRedirect_failure':
    console.log('failure while trying to resolve signInWithRedirect API.');
    break;
  case 'customOAuthState':
    console.log('custom state returned from CognitoHosted UI');
    break;
  default:
    break;
  }
});

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    { devMode ? <App /> : <ComingSoonApp />}
  </React.StrictMode>
);

// If you want to start measuring performance in your app, pass a function
// to log results (for example: reportWebVitals(console.log))
// or send to an analytics endpoint. Learn more: https://bit.ly/CRA-vitals
reportWebVitals();
