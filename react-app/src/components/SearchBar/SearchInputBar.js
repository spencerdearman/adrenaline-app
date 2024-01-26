import React, { useState } from 'react';
import styled from 'styled-components';

export const SearchInputBar = ({ setResults, onFocus, onBlur }) => {
  const [input, setInput] = useState('');
  //   fetch data on backend, just filter search on frontend
  const fetchData = (value) => {
    fetch('https://jsonplaceholder.typicode.com/users')
      .then((response) => response.json())
      .then((json) => {
        const results = json.filter((user) => {
          return (
            value &&
              user &&
              user.name &&
              user.name.toLowerCase().includes(value.toLowerCase())
          );
        });
        setResults(results);
      });
  };

  const handleChange = (value) => {
    setInput(value);
    fetchData(value);
  };

  return (
    <SearchBox>
      <Input
        type="search"
        placeholder="Search"
        onChange={(e) => handleChange(e.target.value)}
        onFocus={onFocus}
        onBlur={onBlur}
        value={input} />
    </SearchBox>
  );
};

const Input = styled.input`
    background-color: transparent;
    border: none;
    height: 100%;
    width: 100%;
    margin-left: 15px;
    margin-right: 6px;

    &:focus {
        outline: none;
    }

    // https://stackoverflow.com/a/68687577
    &::-webkit-search-cancel-button {
        -webkit-appearance: none;
        height: 24px;
        width: 24px;
        margin-left: .4em;
        background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='%23777'><path d='M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z'/></svg>");
        cursor: pointer;
    }

    &::-webkit-search-cancel-button:hover {
        cursor: pointer;
    }
`;

const SearchBox = styled.div`
    background-color: #eee;
    width: 100%;
    border-radius: 12px;
    height: 40px;
    box-shadow: 0px 0px 8px rgb(0, 0, 0, 0.3);
    display: flex;
    align-items: center;
`;
