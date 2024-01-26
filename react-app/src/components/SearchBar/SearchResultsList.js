import React from 'react';
import styled from 'styled-components';

import { SearchResult } from './SearchResult';

export const SearchResultsList = ({ results, focused }) => {
  const ResultsList = styled.div`
    border-radius: 12px;
    max-height: 300px;
    position: absolute;
    display: block;
    width: 90%;
    top: 50px;
    background-color: #eee;
    visibility: ${results.length > 0 && focused ? 'visible' : 'hidden'};
    box-shadow: 0px 3px 8px rgb(0, 0, 0, 0.3);
    overflow-y: auto;
    margin: inherit;
`;

  return (
    <ResultsList>
      {
        results.map((result, id) => {
          return <SearchResult result={result} key={id} />;
        })
      }
    </ResultsList>
  );
};
