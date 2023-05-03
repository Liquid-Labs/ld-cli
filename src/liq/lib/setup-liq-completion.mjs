import { existsSync } from 'node:fs'
import * as fs from 'node:fs/promises'
import * as fsPath from 'node:path'

import { refresh } from '@liquid-labs/edit-section'

const possibleSystemCompletionPaths = [
  fsPath.resolve(fsPath.sep + 'etc', 'bash_completion.d'),
  fsPath.resolve(fsPath.sep + 'usr', 'local', 'etc', 'bash_completion.d')
]
const localBashCompletionPath = fsPath.resolve(process.env.HOME, '.bash_completion')
const possibleBashConfigFiles = [
  fsPath.join(process.env.HOME, '.bashrc'),
  fsPath.join(process.env.HOME, '.profile')
]

const setupLiqCompletion = async() => {
  console.log(wrap('Setting up bash completion...'))
  let completionConfigPath
  for (const testPath of possibleSystemCompletionPaths) {
    try {
      await fs.access(testPath, fs.constants.W_OK)
      completionConfigPath = testPath
      break
    }
    catch (e) {}
  }

  if (completionConfigPath === undefined) {
    if (!existsSync(localBashCompletionPath)) {
      await fs.mkdir(localBashCompletionPath, { recursive : true })
    }
    completionConfigPath = localBashCompletionPath
  }

  const completionSrc = fsPath.resolve(__dirname, 'completion.sh')
  const completionTarget = fsPath.join(completionConfigPath, 'liq')
  await fs.cp(completionSrc, completionTarget)

  let bashConfig
  for (const testConfig of possibleBashConfigFiles) {
    try {
      await fs.access(testConfig, fs.constants.W_OK)
      bashConfig = testConfig
      break
    }
    catch (e) {}
  }

  if (bashConfig === undefined) {
    bashConfig = possibleBashConfigFiles[0]
    await fs.writeFile(bashConfig, '# .bashrc - executed for non-login interactive shells\n')
  }

  const content = `[ -f '${completionTarget}' ] && . '${completionTarget}'`
  refresh({ content, file : bashConfig, sectionKey : 'liq completion' })

  console.log(formatTerminalText(wrap(`To enable completion, you must open a new shell, or try:\n<em>source ${bashConfig}<rst>`, { ignoreTags: true })))
}

export { setupLiqCompletion }
