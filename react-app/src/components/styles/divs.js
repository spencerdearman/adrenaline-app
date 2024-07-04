import styled from 'styled-components';

export const MediaWrapper = styled.div`
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  text-align: start;
  width: fit-content;
  min-width: 40vw;
  max-width: 80vw;
  max-height: 90vh;
  background-color: rgba(200, 200, 200);
`;

export const TextWrapper = styled.div`
  display: flex;
  justify-content: start;
  padding: 15px;
  overflow-y: auto;
  overflow-x: hidden;
  width: 100%;
`;
