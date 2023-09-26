/* global afterAll beforeAll describe expect test */
import { startLiqCLI } from '../liq-cli'

describe('startLiqCLI', () => {
  let origArgv

  beforeAll(() => { origArgv = process.argv })
  afterAll(() => { process.argv = origArgv })

  test('can start the CLI process (defines necessary parameters)', () => {
    process.argv = ['node', 'script.js', '-v']
    expect(() => startLiqCLI()).not.toThrow()
  })
})
