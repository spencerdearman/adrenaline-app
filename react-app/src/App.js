import { useEffect, useState } from 'react';
import logo from './logo.svg';
import "./App.css";
import "@aws-amplify/ui-react/styles.css";
import {
  withAuthenticator,
  Button,
  Heading,
  Image,
  View,
  Card,
} from "@aws-amplify/ui-react";
import { getUserById } from './util/dataStore';
import { getImageUrl } from './util/storage';

async function getUserFullName(username) {
  const user = await getUserById(username);
  return user.firstName + " " + user.lastName;
}

function App({ signOut, user }) {
  const [name, setName] = useState();
  const [url, setUrl] = useState();

  useEffect(() => {
    getUserFullName(user.username)
      .then(data =>
        setName(data)
      );
  }, [user.username]);

  useEffect(() => {
    getImageUrl('images/dearmanspencer@gmail.com/3FBA6014-083B-4DD8-818E-B1496762AC5B.jpg')
      .then(data =>
        setUrl(data)
      );
  });

  return (
    <View className="App">
      <Card>
        <Image src={logo} className="App-logo" alt="logo" />
        <Heading level={1}>Hello {name}</Heading>
      </Card>
      <Button onClick={signOut}>Sign Out</Button>
      <br />
      <br />
      <br />
      <Image src={url} />
    </View >
  );
}

export default withAuthenticator(App);
