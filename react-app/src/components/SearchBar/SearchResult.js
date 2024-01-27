import React from 'react';
import { useNavigate } from 'react-router-dom';
import styled from 'styled-components';

export const SearchResult = ({ setInput, result, setResults }) => {
  const navigate = useNavigate();
  const onClick = (e) => {
    console.log(e.title);
    switch (e.subtitle) {
    case 'User':
      navigate(`/profile/${e.id}`);
      break;
    case 'Meet':
      navigate(`/meet/${e.id}`);
      break;
    case 'Team':
      navigate(`/team/${e.id}`);
      break;
    case 'College':
      navigate(`/college/${e.id}`);
      break;
    default:
      break;
    }
    setInput('');
    setResults([]);
  };

  return (
    <Result onClick={(e) => onClick(result)}>{result.title}</Result>
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
