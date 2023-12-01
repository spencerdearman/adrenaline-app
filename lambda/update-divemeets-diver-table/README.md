# update-divemeets-diver-table

Since not all divers on DiveMeets will have Adrenaline profiles, we have to parse all the DiveMeets profiles to determine which divers are high-school age and would be the target audience for college coaches in our Rankings view.

## The Process

We obtain this information through the following process:

0. EventBridge Schedule is set to run this process every Wednesday at 9AM ET (UTC-5) so we can capture any newly created DiveMeets accounts in the relevant age ranges, as well as update existing divers' skill ratings from any meets they competed in over the last week.
1. The `UpdateDiveMeetsDiverTable` Lambda function starts up an existing EC2 instance to run the processing jobs.
2. The Lambda then sends a bash script to this instance to kick off the processing. It passes the JSON input from the function, which should be an event dictionary that looks like this: {"start_index": "25000", "end_index": '150000"}, to the first Python function within the script.
    1. Note that the start and end indices are passed as Strings, not Ints.
3. The script copies a directory of  files (`s3://adrenalinexxxxx153503-main/public/update-divemeets-diver-table/`), which contains several Python files to be executed.
4. A virtual environment is set up on the instance, and the required depdencies are installed.
5. An initial script is executed to parse all the DiveMeets profiles within the ID range 25,000-150,000, and the relevant IDs are recorded in `ids.csv`.
    1. This is done by determining if the profile's FINA age (if present) is between 14 and 18, and if it is not present, if their high school graduation year (if present) is between 2024 and 2028 (TODO: make years range dynamic)
    2. If neither field is present in the profile, it is ignored.
6. After the first Python script finishes, the `ids.csv` file is copied to S3 to the `s3://adrenalinexxxxx153503-main/public/update-divemeets-diver-table/divemeets-divers-lists/` prefix with `yyyy-MM-dd.csv` as the filename *(`e.g. s3://adrenalinexxxxx153503-main/public/update-divemeets-diver-table/divemeets-divers-lists/2023-11-30.csv`)*
7. After the file is copied, it starts the second Python script, which reads the `ids.csv` file to handle the relevant DiveMeets IDs.
8. The second script replicates the `ProfileParser` and `SkillRating` classes in Swift to parse the DiveMeets profile and collect the personal information at the top, as well as the Dive Statistics table.
9. After parsing the profile, the script verifies that the profile contained any personal information, specifically gender, as well as the statistics table. If any of these are not present, the ID is skipped.
10. After verifying the presence of this data, the script calculates the diver's skill rating with the parsed statistics table.
11. After getting the skill rating, an analogous DiveMeetsDiver Python object is created to package the relevant data for writing to DynamoDB.
12. This object is then passed to a custom GraphQLClient, which handles creating or updating the record using HTTP POST requests to a GraphQL endpoint provided by AppSync.
13. Once all the relevant DiveMeets IDs have been processed and the script finishes, it deactivates the virtual environment, deletes all the files it created, and stops the EC2 instance.

Once these records are added to DynamoDB, Adrenaline is able to sync with the table through AppSync and DataStore so the records can be displayed to the user in the Rankings view.
This process also shouldn't interfere with anyone using the app during this process, as AppSync should take care of pushing any DynamoDB updates to the user, and the rest of the process has no user impact.

## Logging

There are two sets of logs for this process: the UpdateDiveMeetsTable lambda logs (`/aws/lambda/ForceUpdateDiveMeetsDiverTable`), and the EC2 logs. Since the lambda is just initiating this process, it takes about 15s to complete, and the logs here are minimal. The EC2 logs are much more descriptive of the actual process. This is in the `/aws/ec2/update-divemeets-diver-table` log group.

There are four types of log streams that could appear in this log group

- `.../.../aws-runShellScript/stdout`
  - This is the output of the bash script when it is starting, between Python scripts, and finishing the run.
- `.../.../aws-runShellScript/stderr`
  - This is when something crashes, so hopefully this doesn't appear very often.
- `python-script-logs-...`
  - This is the log stream for the initial Python script that scrapes the DiveMeets IDs in the proper age range. This script takes about 40 minutes to run. It should follow stdout and precede the below log stream.
- `python-dynamodb-script-logs-...`
  - This is the log stream for the second Python script that reads ids.csv and processes them to be written to DynamoDB. This script takes about 20 minutes to run. Once this completes, the stdout stream should show the deactivation of the virtual environment, cleanup of resources, and stopping of the instance itself.

## Force Update DynamoDB

There could be some cases in the future where we may not need to reparse all of the DiveMeets IDs to update, but we just want to force update the DynamoDB with the latest profile data from a pre-existing list. This can be done manually using the ForceUpdateDiveMeetsDiverTable lambda function, which just picks up the process from Step 7. However, it first copies a CSV from the
`divemeets-divers-list` directory into the location where `ids.csv` would be written if we started the process from the beginning, and the lambda takes as JSON input this dictionary: `{ "input_date": "yyyy-MM-dd" }` to specify an input date you want to read from.
