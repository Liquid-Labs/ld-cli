// https://misc.flogisoft.com/bash/tip_colors_and_formatting
// for testing:
// function colors() { local i=1; while (( $i <= $# )); do printf "\e[48;5;${!i}m "; i=$(( $i + 1 )); done; printf "\e[0m\n"; }
// then: colors 11 220 8
const tCodes = {
  // non-color control codes
  rst : "\x1b[0m",
  bright : "\x1b[1m",
  bold : "\x1b[1m", // bold and bright are aliases
  dim : "\x1b[2m",
  underscore : "\x1b[4m",
  blink : "\x1b[5m",
  reverse : "\x1b[7m",
  hidden : "\x1b[8m",
  // semantic formatting
  error: "\x1b[91m", // bright red
  warning: "\x1b[93m", // bright yellow/gold
  // standard foreground colors
  black : "\x1b[30m",
  red : "\x1b[31m",
  green : "\x1b[32m",
  yellow : "\x1b[33m", // more of a gold, but we'll stick with the traditional names
  gold : "\x1b[33m",
  blue : "\x1b[34m",
  magenta : "\x1b[35m",
  cyan : "\x1b[36m",
  lightGrey : "\x1b[37m",
  // standard background colors
  bgBlack : "\x1b[40m",
  bgRed : "\x1b[41m",
  bgGreen : "\x1b[42m",
  bgYellow : "\x1b[43m",
  bgBlue : "\x1b[44m",
  bgMagenta : "\x1b[45m",
  bgCyan : "\x1b[46m",
  bgWhite : "\x1b[47m",
  // standard bright colors; these are the same as 'bright'/'bold' + standard color
  darkGrey : "\x1b[90m", // 'bright black == dark grey'
  bRed : "\x1b[91m",
  bGreen: "\x1b[92m",
  bYellow: "\x1b[93m",
  bGold: "\x1b[93m", // == 38;5;11m
  bBlue: "\x1b[94m",
  bMagenta: "\x1b[95m",
  bCyan: "\x1b[96m",
  white: "\x1b[97m", // 'bright grey == white'
  
  forestGreen : "\x1b[38;5;22m",
  richYellow: "\x1b[38;5;220m", // brightest yellow
  canaryYellow: "\x1b[38;5;226m", // brightest yellow
  
  
  dYellow: "\x1b[33m\x1b[2m",
  
  
  bgForestGreen : "\x1b[48;5;22m"
}

const formatTerminalText = (tText) => {
  for (const [ key, code ] of Object.entries(tCodes)) {
    const replacer = new RegExp('<' + key + '>', 'g')
    tText = tText.replaceAll(replacer, code)
  }
  tText = tText.replaceAll(/<fgc:(\d+)>/g, "\x1b[38;5;$1m")
  tText = tText.replaceAll(/<bgc:(\d+)>/g, "\x1b[48;5;$1m")
  
  return tText
}

export { formatTerminalText }
