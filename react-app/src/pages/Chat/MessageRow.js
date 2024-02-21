import React from 'react';

function MessageRow({ message, currentUserIsSender }) {
  // Define styles based on whether the current user is the sender
  const messageStyle = {
    padding: '10px',
    borderRadius: '30px',
    maxWidth: '75%',
    color: currentUserIsSender ? 'white' : 'black',
    backgroundColor: currentUserIsSender ? 'rgba(0, 0, 255, 0.7)' : 'rgba(128, 128, 128, 0.2)',
    alignSelf: currentUserIsSender ? 'flex-end' : 'flex-start',
    margin: '5px',
    wordWrap: 'break-word'
  };

  // Adjusting p tag style to reduce top and bottom margins
  const paragraphStyle = {
    margin: '0' // Removes the default top and bottom margins from the p tag
  };

  const containerStyle = {
    display: 'flex',
    flexDirection: 'column',
    alignItems: currentUserIsSender ? 'flex-end' : 'flex-start'
  };

  return (
    <div style={containerStyle}>
      <div style={messageStyle}>
        <p style={paragraphStyle}>{message.body}</p>
      </div>
    </div>
  );
}

export default MessageRow;
