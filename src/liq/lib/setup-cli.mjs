import * as fsPath from 'node:path'

import { readFJSON, writeFJSON } from '@liquid-labs/federated-json'
import { Questioner } from '@liquid-labs/question-and-answer'
import { formatTerminalText, validStyles } from '@liquid-labs/terminal-text'

const liqHome = fsPath.join(process.env.HOME, '.liq')
const settingsPath = fsPath.join(liqHome, 'local-settings.yaml')

const settingsQuestions = {
  actions : [
    {
      prompt    : 'Which terminal highlighting scheme should be used?',
      options   : validStyles,
      parameter : 'TERMINAL_STYLE'
    },
    {
      statement : "80 or 120 would be typical limited column widths, or enter '0' to use the full terminal width."
    },
    {
      prompt    : 'Preferred column width?',
      paramType : 'int',
      parameter : 'TERMINAL_WIDTH'
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

  const questioner = new Questioner({ initialParameters : settings, interrogationBundle : settingsQuestions })

  await questioner.question()
  const terminalStyle = questioner.get('TERMINAL_STYLE')
  const terminalWidth = questioner.get('TERMINAL_WIDTH')

  if (!('TERMINAL' in settings)) {
    settings.TERMINAL = {}
  }
  settings.TERMINAL.style = terminalStyle
  settings.TERMINAL.width = terminalWidth

  console.log(formatTerminalText(`Updating <code>${settingsPath}<rst>...`))
  writeFJSON({ file : settingsPath, data : settings })
}

export { setupCLI }
