# Aryanispe Telegram PHP Bot Host on Cloudflare Containers

This deployment keeps the existing PHP bot model by running Apache and PHP inside a Cloudflare Container. Uploaded bot files are stored in an R2 bucket mounted into the container, because Container disk is ephemeral.

## Requirements

- Cloudflare Workers Paid plan with Containers enabled
- Docker running locally for `wrangler deploy`
- An R2 bucket for bot files
- An R2 API token with Object Read and Object Write access to that bucket
- A domain or `workers.dev` hostname

Uploaded PHP files are trusted application code. They execute as `www-data` inside the container and can make outbound requests. Do not expose the uploader publicly without authentication and do not upload untrusted files.

## Configure

1. Install dependencies:

   ```sh
   npm install
   ```

2. Edit `wrangler.jsonc` and replace `R2_ACCOUNT_ID`. Set `R2_BUCKET_NAME` to your bucket name.

3. Create the R2 API credentials as Worker secrets:

   ```sh
   npx wrangler secret put AWS_ACCESS_KEY_ID
   npx wrangler secret put AWS_SECRET_ACCESS_KEY
   ```

4. Set the password for the upload panel and webhook setup page:

   ```sh
   npx wrangler secret put PANEL_PASSWORD
   ```

   The username is ignored; use any username with the password in HTTP Basic Authentication.

5. Deploy with Docker running:

   ```sh
   npx wrangler deploy
   ```

The first request can take a few minutes while Cloudflare provisions the container. The panel is at `/`, and requires Basic Authentication. A bot webhook endpoint is public at `/bots/<bot-id>/bot.php`.

## Set up a bot

Upload a `.php` file from the authenticated panel. The result page provides a setup URL. Replace `YOUR_BOT_TOKEN` with the token from BotFather and open the URL while authenticated. The setup page calls Telegram's `setWebhook` API for the uploaded bot path.

Telegram sends updates directly to the public bot URL. The Worker only permits paths matching `/bots/bot_<32 hex characters>/bot.php`; other routes remain protected.

## Local checks

```sh
npx wrangler deploy --dry-run
php -l index.php
php -l upload.php
php -l webhook.php
```

`wrangler deploy --dry-run` still needs a valid local Wrangler installation. A real deployment also needs Docker and the Cloudflare account to have Containers access.
