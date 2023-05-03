import { existsSync } from 'node:fs'
import * as fs from 'node:fs/promises'

import { formatTerminalText } from '@liquid-labs/terminal-text'
import { wrap } from '@liquid-labs/wrap-text'

import { LIQ_HOME } from './constants'

const setupLiqHome = async() => {
  if (existsSync(LIQ_HOME)) {
    console.log(formatTerminalText(wrap(`Found existing liq home: <code>${LIQ_HOME}<rst>`, { ignoreTags : true })))
  }
  else {
    console.log(formatTerminalText(wrap(`Creating liq home: <code>${LIQ_HOME}<rst>...`, { ignoreTags : true })))
    try {
      await fs.mkdir(LIQ_HOME, { recursive : true })
    }
    catch (e) {
      console.log(`There was an error attempting to create the liq home directory: ${e.message}`)
      return false
    }
  }

  return true
}

export { setupLiqHome }
