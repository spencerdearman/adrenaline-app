# update-divemeets-diver-table

Since not all divers on DiveMeets will have Adrenaline profiles, we have to parse all the DiveMeets profiles to determine which divers are high-school age and would be the target audience for college coaches in our Rankings view.

We obtain this information through the following process:

1. The `UpdateDiveMeetsDiverTable` Lambda function starts up an existing EC2 instance to run the processing jobs.
2. The Lambda then sends a bash script to this instance to kick off the processing.
3. The script copies a directory of  files (`s3://adrenalinexxxxx153503-main/public/update-divemeets-diver-table/`), which contains several Python files to be executed.
4. A virtual environment is set up on the instance, and the required depdencies are installed.
5. An initial script is executed to parse all the DiveMeets profiles within the ID range 25,000-150,000, and the relevant IDs are recorded in `ids.csv`.
a. This is done by determining if the profile's FINA age (if present) is between 14 and 18, and if it is not present, if their high school graduation year (if present) is between 2024 and 2028 (TODO: make years range dynamic)
b. If neither field is present in the profile, it is ignored.
6. After the first Python script finishes, the `ids.csv` file is copied to S3 to the `s3://adrenalinexxxxx153503-main/public/update-divemeets-diver-table/divemeets-divers-lists/` prefix with `yyyy-MM-dd.csv` as the filename *(`e.g. s3://adrenalinexxxxx153503-main/public/update-divemeets-diver-table/divemeets-divers-lists/2023-11-30.csv`)*
7. After the file is copied, it starts the second Python script, which reads the `ids.csv` file to handle the relevant DiveMeets IDs.
8. The second script replicates the `ProfileParser` and `SkillRating` classes in Swift to parse the DiveMeets profile and collect the personal information at the top, as well as the Dive Statistics table.
9. After parsing the profile, the script verifies that the profile contained any personal information, specifically gender, as well as the statistics table. If any of these are not present, the ID is skipped.
10. After verifying the presence of this data, the script calculates the diver's skill rating with the parsed statistics table.
11. After getting the skill rating, an analogous DiveMeetsDiver Python object is created to package the relevant data for writing to DynamoDB.
12. This object is then passed to a custom GraphQLClient
