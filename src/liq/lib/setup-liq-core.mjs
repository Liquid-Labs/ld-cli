import { install } from '@liquid-labs/npm-toolkit'

import { LIQ_CORE_VERSION } from './constants'

const setupLiqCore = () => {
  install({ global: true, pkgs: [ '@liquid-labs/liq-core' ], verbose: true, version: LIQ_CORE_VERSION })
}

export { setupLiqCore }