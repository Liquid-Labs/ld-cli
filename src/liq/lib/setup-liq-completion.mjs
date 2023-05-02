import { existsSync } from 'node:fs'
import * as fs from 'node:fs/promises'
import * as fsPath from 'node:path'

import { refresh } from '@liquid-labs/edit-section'

const possibleSystemCompletionPaths = [ 
  fsPath.resolve( fsPath.sep + 'etc', 'bash_completion.d'), 
  fsPath.resolve( fsPath.sep +'usr', 'local', 'etc', 'bash_completion.d')
]
const localBashCompletionPath = fsPath.resolve(process.env.HOME, '.bash_completion')
const possibleBashConfigFiles = [
  fsPath.join(process.env.HOME, '.bash_profile'),
  fsPath.join(process.env.HOME, '.profile')
]

const setupLiqCompletion = async () => {
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
      await fs.mkdir(localBashCompletionPath, { recursive: true })
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
    console.error('Could not set up completion; did not find a terminal config file.')
  }

  const content = `[ -f '${completionTarget}' ] && . '${completionTarget}'`
  refresh({ content, file: bashConfig, sectionKey: 'liq completion' })

  console.log(`To enable completion, you must open a new shell, or try:\nsource ${bashConfig}`)
}

export { setupLiqCompletion }