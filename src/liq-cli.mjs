import { readFileSync } from 'node:fs'
import * as fsPath from 'node:path'

import { LIQ_HOME, LIQ_PLAYGROUND, LIQ_PORT } from '@liquid-labs/liq-defaults'
import { startCLI } from '@liquid-labs/plugable-express-cli'

let versionCache

const getVersion = () => {
  if (versionCache === undefined) {
    // works for both prod and test
    const packagePath = fsPath.resolve(__dirname, '..', 'package.json')

    const pkgJSON = JSON.parse(readFileSync(packagePath, { encoding : 'utf8' }))
    const { version } = pkgJSON

    versionCache = version
  }

  return versionCache
}

const cliSettings = {
  cliName             : 'liq',
  getVersion,
  cliHome             : LIQ_HOME(),
  localServerDevPaths : [
    fsPath.join(LIQ_PLAYGROUND(), 'liq-server'),
    fsPath.join(LIQ_PLAYGROUND(), 'liquid-labs', 'liq-server')
  ],
  localSettingsPath : fsPath.join(LIQ_HOME(), 'local-settings.yaml'),
  port              : LIQ_PORT(),
  serverAPIPath     : fsPath.join(LIQ_HOME(), 'core-api.json'),
  serverPackage     : '@liquid-lab/liq-server',
  serverVersion     : 'latest'
}

const startLiqCLI = () => startCLI(cliSettings)

export { startLiqCLI }
