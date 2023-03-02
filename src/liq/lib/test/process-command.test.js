/* global describe expect test */

import { processCommand } from '../process-command'
import { PORT, PROTOCOL, SERVER } from '../constants'

describe('processCommand', () => {
  test.each([
    [[], '/'],
    [['foo'], '/foo'],
    [['foo', 'bar'], '/foo/bar'],
    [['foo bar', 'baz'], '/foo%20bar/baz']
  ])("command '%s' yields path '%s'", async(command, expectedPath) => {
    const { path } = await processCommand(command)
    expect(path).toEqual(expectedPath)
  })

  test('processes leading method', async() => {
    const { method, path } = await processCommand(['POST', 'foo', 'bar'])
    expect(method).toBe('POST')
    expect(path).toBe('/foo/bar')
  })

  test.each([
    [['foo=1'], [['foo', '1']]],
    [['bar=hey there'], [['bar', 'hey there']]],
    [['baz'], [['baz', 'true']]],
    [['foo=1', 'baz'], [['foo', '1'], ['baz', 'true']]]
  ])("parameter '%s' yields '%p'", async(param, expectedData) => {
    const { data } = await processCommand(['foo', '--', ...param])
    expect(data).toEqual(expectedData)
  })

  test.each([
    [['POST', 'work', 'create', '--', 'bar=1'], '/work/create'],
    [['GET', 'foo', 'bar', '--', 'baz=1'], '/foo/bar?baz=1'],
    [['GET', 'foo', 'bar', '--', 'baz=1', 'bobo'], '/foo/bar?baz=1&bobo=true']
  ])(`command '%p' yields url '${PROTOCOL}://${SERVER}:${PORT}%s'`, async(commands, expectedPath) => {
    const { url } = await processCommand(commands)
    expect(url).toBe(`${PROTOCOL}://${SERVER}:${PORT}${expectedPath}`)
  })
})
