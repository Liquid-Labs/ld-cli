import { existsSync } from 'node:fs'
import * as fsPath from 'node:path'

import { install } from '@liquid-labs/npm-toolkit'
import { formatTerminalText } from '@liquid-labs/terminal-text'
import { wrap } from '@liquid-labs/wrap-text'

import { LIQ_CORE_VERSION, LIQ_PLAYGROUND } from './constants'

const setupLiqCore = () => {
  console.log(formatTerminalText(wrap('Installing <code>@liquid-labs/liq-core<rst>...', { ignoreTags : true })))
  console.log(wrap('Checking for local installation...'))
  let localPath
  const testPaths = [fsPath.join(LIQ_PLAYGROUND, 'liq-core'), fsPath.join(LIQ_PLAYGROUND, 'liquid-labs', 'liq-core')]
  for (const testPath of testPaths) {
    if (existsSync(testPath)) {
      localPath = testPath
    }
  }
  if (localPath !== undefined) {
    install({ global : true, pkgs : [localPath], verbose : true })
  }
  else {
    install({ global : true, pkgs : ['@liquid-labs/liq-core'], verbose : true, version : LIQ_CORE_VERSION })
  }
}

export { setupLiqCore }
