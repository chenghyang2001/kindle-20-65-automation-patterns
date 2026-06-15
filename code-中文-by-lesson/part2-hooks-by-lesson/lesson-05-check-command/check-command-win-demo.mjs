// Windows Git Bash + Node.js v24 相容版本
// 原版用 readline，在 non-TTY 環境（pipe 輸入）會有 readline bug
// 改用 process.stdin async iteration 直接讀取，繞過 readline 不相容問題

async function readStdin() {
  const chunks = []
  for await (const chunk of process.stdin) {
    chunks.push(chunk)
  }
  return JSON.parse(Buffer.concat(chunks).toString())
}

const input = await readStdin()
const { tool_name, tool_input } = input

if (tool_name === 'Bash') {
  const command = tool_input?.command ?? ''
  const BLOCKED = ['rm -rf', 'git push --force', 'DROP TABLE']
  for (const pattern of BLOCKED) {
    if (command.includes(pattern)) {
      process.stderr.write(`已阻擋：'${pattern}' 是被禁止的指令\n`)
      process.exit(2)
    }
  }
}

process.exit(0)
