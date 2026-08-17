import { Container } from "@cloudflare/containers";
import { env } from "cloudflare:workers";

export class BotHost extends Container {
  defaultPort = 8080;
  sleepAfter = "24h";
  envVars = {
    AWS_ACCESS_KEY_ID: env.AWS_ACCESS_KEY_ID,
    AWS_SECRET_ACCESS_KEY: env.AWS_SECRET_ACCESS_KEY,
    R2_ACCOUNT_ID: env.R2_ACCOUNT_ID,
    R2_BUCKET_NAME: env.R2_BUCKET_NAME,
  };
}

function unauthorized() {
  return new Response("Authentication required", {
    status: 401,
    headers: { "WWW-Authenticate": 'Basic realm="Bot Host"' },
  });
}

function isAuthorized(request, password) {
  const authorization = request.headers.get("Authorization");
  if (!authorization?.startsWith("Basic ")) return false;

  try {
    const decoded = atob(authorization.slice(6));
    const separator = decoded.indexOf(":");
    return separator >= 0 && decoded.slice(separator + 1) === password;
  } catch {
    return false;
  }
}

function isPublicBotRoute(pathname) {
  return /^\/bots\/bot_[a-f0-9]{32}\/bot\.php$/.test(pathname);
}

export default {
  async fetch(request, workerEnv) {
    const url = new URL(request.url);
    const publicRoute = isPublicBotRoute(url.pathname);

    if (!publicRoute && !isAuthorized(request, workerEnv.PANEL_PASSWORD)) {
      return unauthorized();
    }

    const targetUrl = new URL(request.url);
    if (targetUrl.pathname === "/setup") targetUrl.pathname = "/webhook.php";

    const headers = new Headers(request.headers);
    headers.delete("Authorization");
    headers.set("X-Forwarded-Proto", "https");
    headers.set("X-Forwarded-Host", url.host);

    const forwardedRequest = new Request(targetUrl, {
      method: request.method,
      headers,
      body: request.method === "GET" || request.method === "HEAD" ? undefined : request.body,
      redirect: request.redirect,
    });
    const container = workerEnv.BOT_HOST.getByName("primary");
    return container.fetch(forwardedRequest);
  },
};
