import React from 'react';
import styled from 'styled-components';

export const SearchResult = ({ result }) => {
  return (
    <Result onClick={(e) => alert(`You clicked on ${result.name}`)}>{result.name}</Result>
  );
};

const Result = styled.div`
    padding: 10px 17px;
    text-align: left;

    &:hover {
        background-color: #ddd;
        cursor: pointer;
    }
`;
