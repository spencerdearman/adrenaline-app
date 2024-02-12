# identity-verification and remove-user-from-face-collection

These lambdas are triggered in relation to uploading profile pictures and verifying them against a user's photo ID.

## identity-verification

When a user uploads their photo ID, is it saved in the `id-cards` directory of the main bucket.
Then, when a user uploads a profile picture, it is initially saved in the `profile-pics-under-review` directory. This upload triggers the `identity-verification` lambda, which checks if the photo upload is for a new or returning user.

If there is also an ID card uploaded in the `id-cards` directory, we can assume it is a new user (this is the behavior when a user signs up through the signup sequence). We compare the faces from both pictures, and, if they match, we create a new user and associate these faces with that user.

If there is only a profile picture under review without an ID card, we can assume it is a returning user (this is the behavior when a user tries to update their profile picture in the "Edit Profile" section). We search the existing users in the collection against the face in the uploaded picture, and, if they match the user's current faces, we accept the upload.

When the upload is accepted, we delete the ID card if it was present and move the profile picture under review into the `profile-pictures` directory, where it is then serviced by CloudFront and loaded by the app.

When verifying through the signup sequence, we wait for 10s for the file to appear in `profile-pictures`. If it does, then we assume it was successful.

In the case of updating a profile picture, we can't do this same check since the user already has a successfully uploaded profile picture on their profile. Instead, we check the `profile-pics-under-review` directory and see if the file is still there and has not been moved. If it is still in the under review folder, we can assume the verification failed.

## remove-user-from-face-collection

This lambda is triggered when a user tried to delete their account entirely. It is triggered when the user's profile picture is deleted from the `profile-pictures` directory. The lambda then searches the faces associated with the deleted user by its user ID. It finds all the associated faces first, then deletes the user, which disassociates the faces from the user, then finally deletes the faces in the collection. This allows a new user in the future to register with these faces in the future should they try to create a new account.
