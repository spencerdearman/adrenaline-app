import React from 'react';
import styled from 'styled-components';

export function ProfileTabSelector({ tabs, tabSelection, setTabSelection }) {
  return (
    <Wrapper>
      {
        tabs.map((tab, id) => {
          return (
            <Button onClick={(e) => setTabSelection(tab.toLowerCase())} key={id}>
              <TabBox selected={tab.toLowerCase() === tabSelection}>
                <Tab selected={tab.toLowerCase() === tabSelection}>{tab.toUpperCase()}</Tab>
              </TabBox>
            </Button>
          );
        })
      }
    </Wrapper>
  );
};

const Wrapper = styled.div`
  display: flex;
  flex-direction: row;
  margin: auto;
  padding: 0 50px;
  padding-bottom: 10px;
  justify-content: space-evenly;
`;

const Button = styled.button`
    display: flex;
    background: none;
    border: none;
    padding: 10px 20px;
    padding-top: 0px;
    transition: 0.3s ease-in-out;
    cursor: pointer;

    :focus {
        outline: none;
    }
`;

const TabBox = styled.div`
    border-bottom: ${props => props.selected ? '1px solid black' : 'none'};
`;

const Tab = styled.p`
    font-weight: ${props => props.selected ? 'bold' : 'normal'};
    padding: 0;
    margin: 0;
`;
