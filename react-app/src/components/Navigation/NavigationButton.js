import React from 'react';
import { Link } from 'react-router-dom';
import styled from 'styled-components';

import personIcon from '../../assets/images/person.svg';

const NavigationButton = (props) => {
  const hasProfilePic = props.imageSrc !== personIcon;
  const isProfileImage = props.title === 'Profile';

  return (
    <Link to={props.href}>
      <HoverButton>
        <ButtonWrapper>
          <Wrapper>
            <Image
              src={props.imageSrc}
              alt=""
              hasprofilepic={hasProfilePic.toString()}
              isprofileimage={isProfileImage.toString()} />
            <Title>{props.title}</Title>
          </Wrapper>
        </ButtonWrapper>
      </HoverButton>
    </Link>
  );
};

export default NavigationButton;

const Image = styled.img`
    width: auto;
    width: 24px;
    height: 100%;
    height: 24px;
    margin: 0 auto;
    object-fit: cover;
    border: ${props => props.hasprofilepic && props.isprofileimage ? '1px solid #ddd' : 'none'};
    border-radius: 50%;
  `;

const ButtonWrapper = styled.button`
    display: flex;
    background: none;
    border: none;
    border-radius: 14px;
    padding: 10px 20px;
    transition: 0.3s ease-in-out;
    cursor: pointer;
    background-blend-mode: overlay;

    p {
        transition: 0.3s ease-in-out;
    }

    :focus {
        outline: none;
    }
`;

const Wrapper = styled.div`
    display: flex;
    justify-items: space-between;
    justify-content: center;
    pointer-events: none;
    cursor: pointer;
`;

const Title = styled.p`
    align-items: center;
    color: #000000;
    text-align: center;
    margin: auto;
    margin-left: 10px;
`;

const HoverButton = styled.div`
    :hover {
      box-shadow: 0px 20px 20px rgba(31, 47, 71, 0.25), 0px 1px 5px rgba(0, 0, 0, 0.1), inset 0 0 0 0.5px rgba(255, 255, 255, 0.4);
    }
`;
