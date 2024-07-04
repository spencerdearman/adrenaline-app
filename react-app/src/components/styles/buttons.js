import styled from 'styled-components';

export const LeftArrowButton = styled.button`
    visibility: ${props => props.itemindex === 0 ? 'hidden' : 'visible'};
    cursor: pointer;
    margin-right: 10px;
`;

export const RightArrowButton = styled.button`
    visibility: ${props => props.itemindex === props.itemslength - 1 ? 'hidden' : 'visible'};
    cursor: pointer;
    margin-left: 10px;
`;
