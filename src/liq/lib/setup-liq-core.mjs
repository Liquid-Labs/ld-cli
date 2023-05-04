import { install } from '@liquid-labs/npm-toolkit'
import { formatTerminalText } from '@liquid-labs/terminal-text'
import { wrap } from '@liquid-labs/wrap-text'

import { LIQ_CORE_VERSION } from './constants'

const setupLiqCore = () => {
  console.log(formatTerminalText(wrap('Installing <code>@liquid-labs/liq-core<rst>...', { ignoreTags : true })))
  install({ global : true, pkgs : ['@liquid-labs/liq-core'], verbose : true, version : LIQ_CORE_VERSION })
}

export { setupLiqCore }
