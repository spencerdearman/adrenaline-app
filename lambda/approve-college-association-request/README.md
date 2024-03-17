# approve-college-association-request

To approve a college association request, provide the following input parameters to the lambda:

```{json}
{
    "user_id": <NewUser ID>,
    "college_id": <College ID>
}
```

where the NewUser ID is the ID of the NewUser who has an associated CoachUser that is being associated with the college, and College ID is the ID in `idsToNames.json`.

If you want to remove all college associations from the user, set `"college_id"` to `""`.
