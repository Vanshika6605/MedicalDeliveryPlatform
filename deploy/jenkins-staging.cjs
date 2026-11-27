const { execFileSync } = require('node:child_process');
const { statSync } = require('node:fs');

async function deploy() {
  const envFile = process.env.MEDIFLOW_CI_ENV_FILE;
  if (!envFile || !statSync(envFile, { throwIfNoEntry: false })?.isFile()) {
    throw new Error('Set MEDIFLOW_CI_ENV_FILE to the staging environment file on the Jenkins agent.');
  }

  const revision = execFileSync('git', ['rev-parse', '--short=12', 'HEAD'], { encoding: 'utf8' }).trim();
  const url = 'http://127.0.0.1:8096';
  const env = {
    ...process.env,
    MEDIFLOW_BIND_IP: '127.0.0.1',
    MEDIFLOW_PORT: '8096',
    MEDIFLOW_IMAGE_TAG: `ci-${revision}`,
    CLIENT_URLS: url,
  };
  const compose = ['compose', '--project-name', 'mediflow-a3-ci', '--env-file', envFile];
  console.log(`Deploying revision ${revision} to ${url}`);
  execFileSync('docker', [...compose, 'up', '--build', '--detach', '--wait', '--wait-timeout', '180'], { env, stdio: 'inherit' });
  execFileSync('docker', [...compose, 'ps'], { env, stdio: 'inherit' });

  const response = await fetch(`${url}/api/health`, { signal: AbortSignal.timeout(10000) });
  const result = await response.json();
  if (!response.ok || result.status !== 'ok' || result.db !== 'postgresql') {
    throw new Error(`Unexpected staging health response (HTTP ${response.status}).`);
  }
  console.log(`Staging health: HTTP ${response.status} ${JSON.stringify(result)}`);
}

deploy().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
