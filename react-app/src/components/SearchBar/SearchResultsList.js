import React from 'react';
import styled from 'styled-components';

import { SearchResult } from './SearchResult';

export const SearchResultsList = ({ setInput, results, setResults, focused }) => {
  return (
    <ResultsList resultslength={results.length} hasfocus={focused.toString()}>
      {
        results.map((result, id) => {
          return <SearchResult setInput={setInput} result={result} setResults={setResults} key={id} />;
        })
      }
    </ResultsList>
  );
};

const ResultsList = styled.div`
    border-radius: 12px;
    max-height: 300px;
    position: absolute;
    display: block;
    width: 90%;
    top: 50px;
    background-color: #eee;
    visibility: ${props => props.resultslength > 0 && props.hasfocus ? 'visible' : 'hidden'};
    box-shadow: 0px 3px 8px rgb(0, 0, 0, 0.3);
    overflow-y: auto;
    margin: inherit;
`;
