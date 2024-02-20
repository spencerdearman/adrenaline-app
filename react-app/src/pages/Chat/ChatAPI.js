// import { DataStore } from 'aws-amplify';

// import { Message, MessageNewUser, NewUser } from './models'; // Adjust the import path according to your project structure

// async function didTapSend(messageText, sender, recipient) {
//   try {
//     // Create the message instance
//     const message = new Message({
//       body: messageText,
//       creationDate: new Date().toISOString() // Adjust according to your model's date format
//     });

//     // Save the message to DataStore
//     const savedMessage = await DataStore.save(message);

//     // Create and save the sender association
//     const tempSender = new MessageNewUser({
//       isSender: true,
//       newuserID: sender.id,
//       messageID: savedMessage.id
//     });
//     await DataStore.save(tempSender);

//     // Create and save the recipient association
//     const tempRecipient = new MessageNewUser({
//       isSender: false,
//       newuserID: recipient.id,
//       messageID: savedMessage.id
//     });
//     await DataStore.save(tempRecipient);

//     console.log('Message and associations saved successfully!');
//   } catch (error) {
//     console.error('Error saving message or associations:', error);
//   }
// }
