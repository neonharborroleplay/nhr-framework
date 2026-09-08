# Clean installation

The supplied Harbor archive is a reference install only. Do not place its `[qbx]`
folder beside NHR and do not import its framework schema into the NHR database.

## txAdmin

1. Publish this `nhr-framework` folder to a private or public Git repository.
2. Replace `REPLACE_WITH_GITHUB_USERNAME` in `txadmin/recipe.yaml`.
3. In txAdmin, choose **Remote URL Template** and paste the raw recipe URL.
4. Deploy into a new server-data directory and a new empty MariaDB/MySQL database.
5. Add administrators through txAdmin and run `nhrhealth` in the server console.

## Manual

1. Install `oxmysql`, `ox_lib`, `ox_target`, `pma-voice`, stock `spawnmanager`, and
   stock `chat`.
2. Copy `resources/[nhr]` into the server's `resources` directory.
3. Import `resources/[nhr]/nhr_core/sql/nhr.sql` into an empty database.
4. Merge `server.cfg.example` into the active server configuration.
5. Start the server and complete the acceptance checks in `DEPLOYMENT.md`.

Never reuse a Cfx.re license key embedded in a shared archive. Generate or select the
appropriate key for the deployment through the Cfx.re portal/txAdmin setup.
