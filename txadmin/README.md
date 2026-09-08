# NHR txAdmin recipe

This folder contains the deploy recipe and generated server configuration for NHR Framework 1.0.0.

## Publish once

1. Create a GitHub repository named `nhr-framework`.
2. Upload the complete NHR package, preserving the root-level `resources` and `txadmin` folders.
3. Confirm `txadmin/recipe.yaml` points to `https://github.com/neonharborroleplay/nhr-framework`.
4. Commit the change to the `main` branch.

The remote recipe URL will be:

```text
https://raw.githubusercontent.com/neonharborroleplay/nhr-framework/main/txadmin/recipe.yaml
```

## Deploy

1. Start FXServer and open txAdmin.
2. Choose **Popular Recipes**, then **Remote URL Template**.
3. Paste the raw recipe URL.
4. Enter the server name, Cfx.re license key, maximum players, and MariaDB/MySQL credentials.
5. Run the deployer. It downloads the Cfx.re defaults, ox dependencies, pma-voice, all NHR resources, creates the database, imports `nhr.sql`, and generates `server.cfg`.
6. Add administrators in txAdmin, start the server, and run `nhrhealth` in the server console.

## Notes

- Use a new empty database for a fresh deployment.
- The database account needs permission to create and modify tables in the selected database.
- Do not re-run the full recipe over a live server. Back up first and use NHR's versioned migrations for upgrades.
- Test the complete acceptance checklist in `DEPLOYMENT.md` before opening the server publicly.
