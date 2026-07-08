import { execSync } from "child_process";
import { readFileSync } from "fs";

const REPO = "krislester900/Design-for-Artistic-Community-App";
const SECRETS = {
  SUPABASE_PROJECT_REF: "wzewlweghntnqyfvhgan",
  SUPABASE_EDGE_FUNCTIONS_URL: "https://wzewlweghntnqyfvhgan.supabase.co/functions/v1",
  CRON_SECRET: "Ivanjiren11@",
  REPLICATE_API_KEY: "r8_DMFSZAZXQQDuZTgaZZEX8wki5gLrkkz30f62I",
};

function getGitToken() {
  const input = `protocol=https\nhost=github.com\n\n`;
  const buf = execSync(`git credential fill`, { input, encoding: "utf8", timeout: 5000 });
  const lines = buf.split("\n");
  for (const line of lines) {
    if (line.startsWith("password=")) return line.slice(9).trim();
    if (line.startsWith("oauth_token=")) return line.slice(12).trim();
    if (line.startsWith("access_token=")) return line.slice(13).trim();
  }
  // Try Windows Credential Manager
  try {
    const result = execSync(`powershell -Command "& {` +
      `$cred = cmdkey /list 2>&1 | Select-String 'git:https://github.com' -SimpleMatch -Context 0,5; ` +
      `if ($cred) { Write-Output $cred.ToString() } }"`, { encoding: "utf8", timeout: 5000 });
    console.log("Credential found, but can't extract password directly.");
  } catch {}
  return null;
}

async function setSecret(name, value, token) {
  const url = `https://api.github.com/repos/${REPO}/actions/secrets/${name}`;
  const body = JSON.stringify({
    encrypted_value: value,
    key_id: await getPublicKey(token),
  });

  const res = await fetch(url, {
    method: "PUT",
    headers: {
      Authorization: `token ${token}`,
      "Content-Type": "application/json",
      "User-Agent": "node-script",
    },
    body: JSON.stringify({
      encrypted_value: Buffer.from(value).toString("base64"),
      key_id: null,
    }),
  });
  return res.status;
}

async function getPublicKey(token) {
  const res = await fetch(`https://api.github.com/repos/${REPO}/actions/secrets/public-key`, {
    headers: { Authorization: `token ${token}`, "User-Agent": "node-script" },
  });
  const data = await res.json();
  return data;
}

async function main() {
  const token = getGitToken();
  if (!token) {
    console.log("Token GitHub non trouvé dans le credential manager.");
    console.log("Ajoute les secrets manuellement depuis le site GitHub.");
    return;
  }
  console.log("Token trouvé !");
  const pubKey = await getPublicKey(token);
  console.log("Clé publique récupérée :", pubKey.key_id ? "OK" : "Échec");
}

main().catch(console.error);
