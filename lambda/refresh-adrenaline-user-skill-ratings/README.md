# refresh-adrenaline-user-skill-ratings

This lambda is added to the end of the skill rating refresh state machine to update the current Adrenaline users' skill ratings. It can be executed with no arguments, and it will pull all the Adrenaline athletes with DiveMeets IDs and recompute their skill ratings. It then sends a GraphQL request to update these values in real-time in DynamoDB.

Note: This process is currently self-contained in the lambda, but once we reach a certain number of Adrenaline users, this may exceed the 15min timeout limit on lambdas (this is why the DiveMeetsDiver calculation takes place on EC2). We may need to come up with a better solution to this update, such as EMR or another AWS service to handle this processing when we reach that point.
