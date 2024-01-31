import React from 'react';
import { BrowserRouter as Router, Route, Routes } from 'react-router-dom';
import styled from 'styled-components';

import {
  withAuthenticator
} from '@aws-amplify/ui-react';

import NavigationBar from './components/Navigation/NavigationBar';
import Chat from './pages/Chat/Chat';
import Home from './pages/Home/Home';
import NotFound from './pages/NotFound';
import Profile from './pages/Profile/Profile';
import Rankings from './pages/Rankings/Rankings';

// import { getImageUrl } from './util/storage'
import './App.css';
import '@aws-amplify/ui-react/styles.css';

export const CurrentUserContext = React.createContext();

function App({ signOut, user }) {
  // const [url, setUrl] = useState()

  // useEffect(() => {
  //   getImageUrl('images/dearmanspencer@gmail.com/3FBA6014-083B-4DD8-818E-B1496762AC5B.jpg')
  //     .then(data =>
  //       setUrl(data)
  //     )
  // })

  return (
    <CurrentUserContext.Provider value={user}>
      <Wrapper>
        <Router>
          <NavigationBar />

          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/chat" element={<Chat />} />
            <Route path="/rankings" element={<Rankings />} />
            <Route path="/profile/:profileId" element={<Profile signOut={signOut} />} />
            <Route path="*" element={<NotFound />} />
          </Routes>
        </Router>
      </Wrapper>
    </CurrentUserContext.Provider>
  );
};

export default withAuthenticator(App);

const Wrapper = styled.div`
    padding: 20px;
    margin: 0 auto;
    text-align: center;
`;
