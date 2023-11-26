# Scrape-profiles mechanism

Currently, DiveMeets profiles are scraped from the website through the following process:

1. Lambda function is triggered on a schedule weekly at 9am ET to start an EC2 instance and send a shell script to it.
2. Once the instance is started, the lambda sends a SSM command to execute the hard-coded script in the lambda, which runs the python script to scrape the profiles and save them to a local CSV file. The script then copies that file to S3 with the `public/divemeets-divers-lists/` prefix and stops the EC2 instance.
3. A second lambda function gets triggered when a file is added to the `divemeets-divers-lists` folder, which takes the new file and pulls the DiveMeets IDs one by one to parse their profiles fully. This data is then updated in the `DiveMeetsDiver` DynamoDB table.
4. The `DiveMeetsDiver` table has a Time-To-Live (TTL) of 1 week for all its entries, so if a DiveMeets ID is not updated by the weekly script run, it will be removed from the table.
