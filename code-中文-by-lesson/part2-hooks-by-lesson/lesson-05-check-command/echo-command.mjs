#!/usr/bin/env node
// echo-command.mjs - 第 5 課 Step 3 編碼測試：證明 Node 原生 UTF-8 解析
import { createInterface } from 'readline'
async function readStdin() {
  const rl = createInterface({ input: process.stdin })
  const lines = []
  for await (const line of rl) lines.push(line)
  return JSON.parse(lines.join('\n'))
}
const input = await readStdin()
const command = input.tool_input?.command ?? ''
process.stdout.write(`解析到的指令內容：${command}\n`)
process.stdout.write(`字元數（中文算 1 字）：${[...command].length}\n`)
