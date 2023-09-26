import * as fsPath from 'node:path'

import { LIQ_HOME, LIQ_PLAYGROUND, LIQ_PORT } from '@liquid-labs/liq-defaults'
import { startCLI } from '@liquid-labs/plugable-express-cli'

const cliSettings = {
  cliName             : 'liq',
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

startCLI(cliSettings)
