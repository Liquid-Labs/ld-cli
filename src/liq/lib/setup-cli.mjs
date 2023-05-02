import { existsSync } from 'node:fs'
import * as fsPath from 'node:path'

import { readFJSON, writeFJSON } from '@liquid-labs/federated-json'
import { Questioner } from '@liquid-labs/question-and-answer'
import { formatTerminalText, validStyles } from '@liquid-labs/terminal-text'

const liqHome = fsPath.join(process.env.HOME, '.liq')
const settingsPath = fsPath.join(liqHome, 'local-settings.yaml')

const settingsQuestions = {
  actions: [
    {
      prompt: 'Which terminal highlighting scheme should be used?',
      options: validStyles,
      parameter: 'TERMINAL_STYLE'
    }
  ]
}

const setupCLI = async() => {
  let settings
  try {
    settings = readFJSON(settingsPath)
  }
  catch (e) {
    if (e.code === 'ENOENT') {
      settings = {}
    }
    else {
      throw e
    }
  }

  const questioner = new Questioner({ initialParameters: settings, interrogationBundle: settingsQuestions })

  await questioner.question()
  const terminalStyle = questioner.get('TERMINAL_STYLE')

  if (!('TERMINAL' in settings)) {
    settings.TERMINAL = {}
  }
  settings.TERMINAL.style = terminalStyle

  console.log(formatTerminalText(`Updating <code>${settingsPath}<rst>...`))
  writeFJSON({ file: settingsPath, data: settings })
}

export { setupCLI }