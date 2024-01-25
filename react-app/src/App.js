import React from 'react';
import { BrowserRouter as Router, Route, Routes } from 'react-router-dom';
import styled from 'styled-components';

import {
  withAuthenticator
} from '@aws-amplify/ui-react';

import Chat from './pages/Chat/Chat';
import Home from './pages/Home/Home';
import NotFound from './pages/NotFound';
import Profile from './pages/Profile/Profile';
import Rankings from './pages/Rankings/Rankings';

// import { getUserById } from './util/dataStore'
// import { getImageUrl } from './util/storage'
import './App.css';
import '@aws-amplify/ui-react/styles.css';

// async function getUserFullName (username) {
//   const user = await getUserById(username)
//   return user.firstName + ' ' + user.lastName
// };

function App({ signOut, user }) {
  // const [name, setName] = useState()
  // const [url, setUrl] = useState()

  // useEffect(() => {
  //   getUserFullName(user.username)
  //     .then(data =>
  //       setName(data)
  //     )
  // }, [user.username])

  // useEffect(() => {
  //   getImageUrl('images/dearmanspencer@gmail.com/3FBA6014-083B-4DD8-818E-B1496762AC5B.jpg')
  //     .then(data =>
  //       setUrl(data)
  //     )
  // })

  return (
    <Wrapper>
      <Router>
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/chat" element={<Chat />} />
          <Route path="/rankings" element={<Rankings />} />
          <Route path="/profile/:profileId" element={<Profile signOut={signOut} />} />
          <Route path="*" element={<NotFound />} />
        </Routes>
      </Router>
    </Wrapper>
  );
};

export default withAuthenticator(App);

const Wrapper = styled.div`
    padding: 50px;
    margin: 0 auto;
    text-align: center;
`;
