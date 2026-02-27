#!/usr/bin/env node
/**
 * Cursor stop-hook: long-running agent loop.
 * Chạy khi agent dừng (stop). Nếu chưa "xong" (scratchpad chưa có DONE/PASS) và chưa vượt số lần lặp,
 * trả về followup_message để agent tiếp tục (vd chạy verify, sửa lỗi, lặp lại).
 * Cần Node.js (node .cursor/hooks/grind.mjs). Cursor gọi từ workspace root (cwd = workspaceFolder).
 */

import { readFileSync, existsSync } from "fs";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const MAX_ITERATIONS = 5;
const SCRATCHPAD_PATH = join(__dirname, "..", "scratchpad.md");

function readStdin() {
  return new Promise((resolve) => {
    let data = "";
    process.stdin.setEncoding("utf8");
    process.stdin.on("data", (chunk) => { data += chunk; });
    process.stdin.on("end", () => resolve(data));
  });
}

function output(obj) {
  console.log(JSON.stringify(obj));
}

(async () => {
  let input;
  try {
    const raw = await readStdin();
    input = raw ? JSON.parse(raw) : {};
  } catch {
    output({});
    process.exit(0);
    return;
  }

  const { status = "", loop_count: loopCount = 0 } = input;

  if (status !== "completed" || loopCount >= MAX_ITERATIONS) {
    output({});
    process.exit(0);
    return;
  }

  let scratchpad = "";
  if (existsSync(SCRATCHPAD_PATH)) {
    try {
      scratchpad = readFileSync(SCRATCHPAD_PATH, "utf-8");
    } catch {
      // ignore
    }
  }

  const done = /DONE|PASS|VERIFY\s*PASS/i.test(scratchpad);

  if (done) {
    output({});
    process.exit(0);
    return;
  }

  const next = loopCount + 1;
  const msg = `[${next}/${MAX_ITERATIONS}] Chưa DONE. Chạy /bcdt-verify hoặc build+checklist; sửa lỗi. Khi Pass → ghi "DONE" hoặc "VERIFY PASS" vào .cursor/scratchpad.md.`;
  output({ followup_message: msg });
})();
