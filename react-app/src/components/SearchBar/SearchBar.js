import React, { useState } from 'react';
import styled from 'styled-components';

import { SearchInputBar } from './SearchInputBar';
import { SearchResultsList } from './SearchResultsList';

function SearchBar() {
  const [results, setResults] = useState([]);
  const [focused, setFocused] = useState(false);
  const onFocus = () => setFocused(true);
  const onBlur = () => setFocused(false);

  return (
    <SearchContainer>
      <SearchInputBar setResults={setResults} onFocus={onFocus} onBlur={onBlur} />
      <SearchResultsList results={results} focused={focused} />
    </SearchContainer>
  );
}

export default SearchBar;

const SearchContainer = styled.div`
    width: 30%;
    margin: auto;
    margin-right: 20px;
    padding-left: 20px;
    position: relative;
    align-items: center;
    min-width: 250px;
`;
