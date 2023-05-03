import * as fsPath from 'node:path'

const LIQ_CORE_VERSION = 'latest'
const LIQ_HOME = fsPath.join(process.env.HOME, '.liq')
const LIQ_PLAYGROUND = fsPath.join(LIQ_HOME, 'playground')

const PORT = '32600'
const PROTOCOL = 'http'
const SERVER = '127.0.0.1'

export {
  LIQ_CORE_VERSION,
  LIQ_HOME,
  LIQ_PLAYGROUND,
  PORT,
  PROTOCOL,
  SERVER
}
