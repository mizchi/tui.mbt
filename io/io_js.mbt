///|
/// I/O implementation for JavaScript/Node.js target

///|
/// Read a single key from stdin (raw mode)
extern "js" fn js_read_key() -> @js_async.Promise[String] =
  #| async () => {
  #|   if (typeof process === 'undefined') return 'q';
  #|
  #|   if (process.stdin.isTTY) {
  #|     process.stdin.setRawMode(true);
  #|   }
  #|   process.stdin.resume();
  #|   process.stdin.setEncoding('utf8');
  #|
  #|   return new Promise((resolve) => {
  #|     const onData = (data) => {
  #|       process.stdin.removeListener('data', onData);
  #|       resolve(data);
  #|     };
  #|     process.stdin.on('data', onData);
  #|   });
  #| }

///|
/// Print to stdout without newline
extern "js" fn js_print_raw(s : String) =
  #| (s) => process.stdout.write(s)

///|
/// Debug print to stderr (won't interfere with TUI)
extern "js" fn js_debug_stderr(s : String) =
  #| (s) => {
  #|   process.stderr.write('[DEBUG] ' + s + '\n');
  #| }

///|
/// Debug print to stderr (public)
pub fn debug_stderr(s : String) -> Unit {
  js_debug_stderr(s)
}

///|
/// Debug stdin state
extern "js" fn js_debug_stdin_state(label : String) =
  #| async (label) => {
  #|   const { stdin } = await import('node:process');
  #|   console.log(`[STDIN ${label}] isTTY=${stdin.isTTY}, isRaw=${stdin.isRaw}, isPaused=${stdin.isPaused()}, readable=${stdin.readable}, listenerCount(data)=${stdin.listenerCount('data')}`);
  #| }

///|
/// Debug stdin state (public)
pub fn debug_stdin_state(label : String) -> Unit {
  js_debug_stdin_state(label)
}

///|
/// Cleanup stdin (turn off raw mode)
extern "js" fn js_cleanup_stdin() =
  #| () => {
  #|   if (typeof process !== 'undefined' && process.stdin.isTTY) {
  #|     process.stdin.setRawMode(false);
  #|     process.stdin.pause();
  #|   }
  #| }

///|
/// Enable raw mode
extern "js" fn js_enable_raw_mode() =
  #| () => {
  #|   if (typeof process !== 'undefined' && process.stdin.isTTY) {
  #|     process.stdin.setRawMode(true);
  #|     process.stdin.resume();
  #|   }
  #| }

///|
/// Get terminal columns
extern "js" fn js_get_terminal_columns() -> Int =
  #| () => {
  #|   if (typeof process === 'undefined') return 80;
  #|   return process.stdout.columns || 80;
  #| }

///|
/// Get terminal rows
extern "js" fn js_get_terminal_rows() -> Int =
  #| () => {
  #|   if (typeof process === 'undefined') return 24;
  #|   return process.stdout.rows || 24;
  #| }

///|
/// Sleep for milliseconds
extern "js" fn js_sleep(ms : Int) -> @js_async.Promise[Unit] =
  #| (ms) => new Promise(r => setTimeout(r, ms))

///|
/// Get current time in milliseconds
extern "js" fn js_get_time_ms() -> Int =
  #| () => Date.now()

///|
/// Get current time in milliseconds (monotonic)
pub fn get_time_ms() -> Int {
  js_get_time_ms()
}

///|
/// Keep the process alive without blocking (non-blocking)
/// This schedules a timeout but doesn't wait - keeps event loop active
extern "js" fn js_keep_alive_nonblocking(ms : Int) =
  #| (ms) => {
  #|   // Simple timer keeps the process alive
  #|   setTimeout(() => {}, ms);
  #| }

///|
/// Keep process alive without blocking the event loop
pub fn keep_alive_nonblocking(ms : Int) -> Unit {
  js_keep_alive_nonblocking(ms)
}

///|
/// Start a keypress listener (event-driven, non-blocking)
/// Uses raw data events for reliability
extern "js" fn js_start_keypress_listener(callback : (String) -> Unit) =
  #| async (callback) => {
  #|   const { stdin } = await import('node:process');
  #|
  #|   // Clean up any existing listeners
  #|   stdin.removeAllListeners('keypress');
  #|   stdin.removeAllListeners('data');
  #|
  #|   if (stdin.isTTY) {
  #|     stdin.setRawMode(true);
  #|   }
  #|   stdin.resume();
  #|   stdin.setEncoding('utf8');
  #|
  #|   const onData = (data) => callback(data);
  #|
  #|   stdin.__dataHandler = onData;
  #|   stdin.on('data', onData);
  #| }

///|
/// Stop the keypress listener
extern "js" fn js_stop_keypress_listener() =
  #| async () => {
  #|   const { stdin } = await import('node:process');
  #|   if (stdin.__dataHandler) {
  #|     stdin.removeListener('data', stdin.__dataHandler);
  #|     stdin.__dataHandler = null;
  #|   }
  #|   if (stdin.isTTY) {
  #|     stdin.setRawMode(false);
  #|   }
  #|   stdin.pause();
  #| }

///|
/// Start listening for keypresses (event-driven)
pub fn start_keypress_listener(callback : (String) -> Unit) -> Unit {
  js_start_keypress_listener(callback)
}

///|
/// Stop listening for keypresses
pub fn stop_keypress_listener() -> Unit {
  js_stop_keypress_listener()
  // Also stop idle interval
  if idle_interval_id.val >= 0 {
    js_stop_idle_interval(idle_interval_id.val)
    idle_interval_id.val = -1
  }
}

///|
/// Start idle interval timer
extern "js" fn js_start_idle_interval(handler : () -> Unit, ms : Int) -> Int =
  #| (handler, ms) => setInterval(() => handler(), ms)

///|
/// Stop idle interval timer
extern "js" fn js_stop_idle_interval(id : Int) =
  #| (id) => clearInterval(id)

///|
/// Idle interval ID storage
let idle_interval_id : Ref[Int] = Ref::new(-1)

///|
/// Set idle handler (uses setInterval for JS)
pub fn set_idle_handler(handler : () -> Unit) -> Unit {
  // Clear previous interval if any
  if idle_interval_id.val >= 0 {
    js_stop_idle_interval(idle_interval_id.val)
  }
  // Start new interval (10ms polling)
  idle_interval_id.val = js_start_idle_interval(handler, 10)
}

///|
/// Start an inline input session with cooked mode (IME enabled)
/// Exits alternate screen temporarily for proper IME support
/// Enter confirms, Escape cancels, Ctrl+C force quits
extern "js" fn js_start_inline_input_cooked(
  field_name : String,
  initial : String,
  confirm_on_shift_enter : Bool,
  esc_cancels : Bool,
  on_confirmed : (String) -> Unit,
  on_cancelled : () -> Unit,
  on_force_quit : () -> Unit,
) -> Unit =
  #| async (fieldName, initial, confirmOnShiftEnter, escCancels, onConfirmed, onCancelled, onForceQuit) => {
  #|   const { stdin, stdout, stderr } = await import('node:process');
  #|   const { execSync } = await import('node:child_process');
  #|   const debug = process.env.TUI_DEBUG_COOKED === '1';
  #|   const reserveRows = Number(process.env.TUI_IME_RESERVE_ROWS || '1');
  #|   const toHex = (text) => Array.from(text)
  #|     .map((ch) => ch.codePointAt(0).toString(16).padStart(4, '0'))
  #|     .join(' ');
  #|   const show = (text) => {
  #|     try {
  #|       return JSON.stringify(text);
  #|     } catch {
  #|       return '[unprintable]';
  #|     }
  #|   };
  #|
  #|   // Show cursor (stay in alt screen)
  #|   stdout.write('\x1b[?25h');
  #|   // Enable modifyOtherKeys to detect Shift+Enter if supported
  #|   stdout.write('\x1b[>4;2m');
  #|
  #|   let sttyState = null;
  #|   if (stdin.isTTY) {
  #|     try {
  #|       sttyState = execSync('stty -g < /dev/tty', { encoding: 'utf8' }).trim();
  #|     } catch {
  #|       sttyState = null;
  #|     }
  #|   }
  #|
  #|   // Clean up any existing handlers
  #|   if (stdin.__dataHandler) {
  #|     stdin.removeListener('data', stdin.__dataHandler);
  #|     stdin.__dataHandler = null;
  #|   }
  #|   if (stdin.__cookedHandler) {
  #|     stdin.removeListener('data', stdin.__cookedHandler);
  #|     stdin.__cookedHandler = null;
  #|   }
  #|
  #|   // Set cooked mode for IME support
  #|   if (stdin.isTTY) {
  #|     stdin.setRawMode(false);
  #|   }
  #|   stdin.resume();
  #|   stdin.setEncoding('utf8');
  #|   if (stdin.isTTY && sttyState) {
  #|     try {
  #|       execSync('stty -echoctl < /dev/tty');
  #|     } catch {
  #|       try {
  #|         execSync('stty -ctlecho < /dev/tty');
  #|       } catch {
  #|         // ignore if unsupported
  #|       }
  #|     }
  #|   }
  #|
  #|   if (stdin.isTTY && sttyState) {
  #|     try {
  #|       execSync('stty -icanon -echo -icrnl < /dev/tty');
  #|     } catch {
  #|       // ignore if unsupported
  #|     }
  #|   }
  #|
  #|   const initialText = initial || '';
  #|   let chars = Array.from(initialText);
  #|   let cursor = chars.length;
  #|   let done = false;
  #|
  #|   const shiftEnterSeqs = [
  #|     '\x1b[13;2u',
  #|     '\x1b[27;2;13~',
  #|     '\x1bOM',
  #|     '\x1b\r',
  #|     '\x1b\n',
  #|   ];
  #|   const shiftEnterAt = (text, index) =>
  #|     shiftEnterSeqs.find((seq) => text.startsWith(seq, index));
  #|   const deleteSeq = '\x1b[3~';
  #|
  #|   const getCharWidth = (char) => {
  #|     const code = char.codePointAt(0);
  #|     if (code >= 0x1100 && (
  #|       code <= 0x115F ||
  #|       code === 0x2329 || code === 0x232A ||
  #|       (code >= 0x2E80 && code <= 0x303E) ||
  #|       (code >= 0x3040 && code <= 0x33FF) ||
  #|       (code >= 0x3400 && code <= 0x4DBF) ||
  #|       (code >= 0x4E00 && code <= 0x9FFF) ||
  #|       (code >= 0xAC00 && code <= 0xD7A3) ||
  #|       (code >= 0xF900 && code <= 0xFAFF) ||
  #|       (code >= 0xFE10 && code <= 0xFE1F) ||
  #|       (code >= 0xFE30 && code <= 0xFE6F) ||
  #|       (code >= 0xFF00 && code <= 0xFF60) ||
  #|       (code >= 0xFFE0 && code <= 0xFFE6) ||
  #|       (code >= 0x20000 && code <= 0x2FFFF)
  #|     )) {
  #|       return 2;
  #|     }
  #|     return 1;
  #|   };
  #|
  #|   const wrapText = (chars) => {
  #|     const lines = [];
  #|     let currentLine = [];
  #|     let lineStartIdx = 0;
  #|     for (let i = 0; i < chars.length; i++) {
  #|       const char = chars[i];
  #|       if (char === '\n') {
  #|         lines.push({ chars: currentLine, startIdx: lineStartIdx });
  #|         currentLine = [];
  #|         lineStartIdx = i + 1;
  #|         continue;
  #|       }
  #|       currentLine.push(char);
  #|     }
  #|     lines.push({ chars: currentLine, startIdx: lineStartIdx });
  #|     return lines;
  #|   };
  #|
  #|   const findCursorPos = (lines, cursor) => {
  #|     for (let lineIdx = 0; lineIdx < lines.length; lineIdx++) {
  #|       const line = lines[lineIdx];
  #|       const lineEnd = line.startIdx + line.chars.length;
  #|       if (cursor <= lineEnd) {
  #|         const posInLine = cursor - line.startIdx;
  #|         let colOffset = 0;
  #|         for (let i = 0; i < posInLine; i++) {
  #|           colOffset += getCharWidth(line.chars[i]);
  #|         }
  #|         return { lineIdx, colOffset };
  #|       }
  #|     }
  #|     const lastLine = lines[lines.length - 1];
  #|     let colOffset = 0;
  #|     for (const char of lastLine.chars) {
  #|       colOffset += getCharWidth(char);
  #|     }
  #|     return { lineIdx: lines.length - 1, colOffset };
  #|   };
  #|
  #|   const readCursorPos = () => new Promise((resolve) => {
  #|     let buf = '';
  #|     const onResp = (chunk) => {
  #|       buf += chunk;
  #|       const match = /\x1b\[(\d+);(\d+)R/.exec(buf);
  #|       if (match) {
  #|         stdin.removeListener('data', onResp);
  #|         resolve({ row: Number(match[1]), col: Number(match[2]) });
  #|       }
  #|     };
  #|     stdin.on('data', onResp);
  #|     stdout.write('\x1b[6n');
  #|     setTimeout(() => {
  #|       stdin.removeListener('data', onResp);
  #|       resolve(null);
  #|     }, 100);
  #|   });
  #|
  #|   let startRow = null;
  #|   let startCol = 1;
  #|   let canRender = false;
  #|   let prefix = '';
  #|   let renderedLines = Math.max(1, initialText.split('\n').length);
  #|   let maxRows = null;
  #|   let maxCols = null;
  #|   let cursorPending = false;
  #|   let scrollOffset = 0;
  #|
  #|   const updatePrefix = () => {
  #|     prefix = startCol > 1 ? ' '.repeat(startCol - 1) : '';
  #|   };
  #|
  #|   const applyCursorPos = (pos) => {
  #|     if (!pos) return false;
  #|     startRow = pos.row;
  #|     startCol = pos.col;
  #|     canRender = true;
  #|     if (stdout.rows) {
  #|       const available = stdout.rows - startRow + 1 - reserveRows;
  #|       maxRows = Math.max(1, available);
  #|     }
  #|     if (stdout.columns) {
  #|       const availableCols = stdout.columns - startCol + 1;
  #|       maxCols = Math.max(1, availableCols);
  #|     }
  #|     updatePrefix();
  #|     return true;
  #|   };
  #|
  #|   const bufferString = () => chars.join('');
  #|
  #|   const renderAll = () => {
  #|     if (!canRender) return false;
  #|     const lines = wrapText(chars);
  #|     const cursorPos = findCursorPos(lines, cursor);
  #|     const maxVisible = maxRows || lines.length;
  #|
  #|     if (lines.length <= maxVisible) {
  #|       scrollOffset = 0;
  #|     } else {
  #|       if (cursorPos.lineIdx < scrollOffset) {
  #|         scrollOffset = cursorPos.lineIdx;
  #|       } else if (cursorPos.lineIdx >= scrollOffset + maxVisible) {
  #|         scrollOffset = cursorPos.lineIdx - maxVisible + 1;
  #|       }
  #|       scrollOffset = Math.max(0, Math.min(scrollOffset, lines.length - maxVisible));
  #|     }
  #|
  #|     const visible = lines.slice(scrollOffset, scrollOffset + maxVisible);
  #|
  #|     stdout.write(`\x1b[${startRow};${startCol}H`);
  #|     const clearLines = maxRows ? Math.min(renderedLines, maxRows) : renderedLines;
  #|     for (let i = 0; i < clearLines; i++) {
  #|       stdout.write('\x1b[K');
  #|       if (i < clearLines - 1) {
  #|         stdout.write('\x1b[1B');
  #|       }
  #|     }
  #|     stdout.write(`\x1b[${startRow};${startCol}H`);
  #|     for (let i = 0; i < visible.length; i++) {
  #|       if (i > 0) {
  #|         stdout.write('\n' + prefix);
  #|       }
  #|       stdout.write(visible[i].chars.join(''));
  #|     }
  #|
  #|     renderedLines = Math.max(1, visible.length);
  #|
  #|     const cursorLineOffset = cursorPos.lineIdx - scrollOffset;
  #|     const maxRowOffset = maxVisible - 1;
  #|     const displayRow = startRow + Math.max(0, Math.min(cursorLineOffset, maxRowOffset));
  #|     const displayCol = startCol + Math.max(0, cursorPos.colOffset);
  #|     stdout.write(`\x1b[${displayRow};${displayCol}H`);
  #|     stdout.write('\x1b[?25h');
  #|     return true;
  #|   };
  #|
  #|   const lineBounds = (cursor) => {
  #|     let start = 0;
  #|     for (let i = cursor - 1; i >= 0; i--) {
  #|       if (chars[i] === '\n') {
  #|         start = i + 1;
  #|         break;
  #|       }
  #|     }
  #|     let end = chars.length;
  #|     for (let i = cursor; i < chars.length; i++) {
  #|       if (chars[i] === '\n') {
  #|         end = i;
  #|         break;
  #|       }
  #|     }
  #|     return { start, end };
  #|   };
  #|
  #|   const requestCursorPos = () => {
  #|     if (cursorPending || canRender) return;
  #|     cursorPending = true;
  #|     readCursorPos().then((pos) => {
  #|       cursorPending = false;
  #|       if (applyCursorPos(pos)) {
  #|         renderAll();
  #|       }
  #|     });
  #|   };
  #|
  #|   const initialPos = await readCursorPos();
  #|   applyCursorPos(initialPos);
  #|
  #|
  #|   const cleanup = () => {
  #|     if (stdin.__cookedHandler) {
  #|       stdin.removeListener('data', stdin.__cookedHandler);
  #|       stdin.__cookedHandler = null;
  #|     }
  #|     // Disable modifyOtherKeys
  #|     stdout.write('\x1b[>4;m');
  #|     if (sttyState) {
  #|       try {
  #|         execSync(`stty ${sttyState} < /dev/tty`);
  #|       } catch {
  #|         // ignore restore errors
  #|       }
  #|     }
  #|   };
  #|
  #|   const finish = (result) => {
  #|     if (done) return;
  #|     done = true;
  #|     cleanup();
  #|     setImmediate(() => onConfirmed(result));
  #|   };
  #|
  #|   const cancel = () => {
  #|     if (done) return;
  #|     done = true;
  #|     cleanup();
  #|     setImmediate(() => onCancelled());
  #|   };
  #|
  #|   const forceQuit = () => {
  #|     if (done) return;
  #|     done = true;
  #|     cleanup();
  #|     setImmediate(() => onForceQuit());
  #|   };
  #|
  #|   if (!renderAll()) {
  #|     requestCursorPos();
  #|     if (chars.length > 0) {
  #|       stdout.write(bufferString());
  #|     }
  #|   }
  #|
  #|   const onData = (chunk) => {
  #|     if (done) return;
  #|
  #|     if (debug) {
  #|       stderr.write(`[cooked] raw=${show(chunk)} hex=${toHex(chunk)}\n`);
  #|     }
  #|
  #|     let i = 0;
  #|     let needRender = false;
  #|     while (i < chunk.length) {
  #|       if (chunk[i] === '\x1b') {
  #|         const seq = shiftEnterAt(chunk, i);
  #|         if (seq) {
  #|           if (confirmOnShiftEnter) {
  #|             const result = chars.length > 0 ? bufferString() : initialText;
  #|             finish(result);
  #|             return;
  #|           }
  #|           chars.splice(cursor, 0, '\n');
  #|           cursor += 1;
  #|           needRender = true;
  #|           i += seq.length;
  #|           continue;
  #|         }
  #|         if (chunk.startsWith(deleteSeq, i)) {
  #|           if (cursor < chars.length) {
  #|             chars.splice(cursor, 1);
  #|             needRender = true;
  #|           }
  #|           i += deleteSeq.length;
  #|           continue;
  #|         }
  #|         if (chunk.startsWith('\x1b[D', i)) {
  #|           if (cursor > 0) {
  #|             cursor -= 1;
  #|             needRender = true;
  #|           }
  #|           i += 3;
  #|           continue;
  #|         }
  #|         if (chunk.startsWith('\x1b[C', i)) {
  #|           if (cursor < chars.length) {
  #|             cursor += 1;
  #|             needRender = true;
  #|           }
  #|           i += 3;
  #|           continue;
  #|         }
  #|         if (chunk.startsWith('\x1b[H', i)) {
  #|           cursor = 0;
  #|           needRender = true;
  #|           i += 3;
  #|           continue;
  #|         }
  #|         if (chunk.startsWith('\x1b[A', i)) {
  #|           const lines = wrapText(chars);
  #|           const pos = findCursorPos(lines, cursor);
  #|           if (pos.lineIdx > 0) {
  #|             const prevLine = lines[pos.lineIdx - 1];
  #|             let targetCol = pos.colOffset;
  #|             let newCursor = prevLine.startIdx;
  #|             let w = 0;
  #|             for (let j = 0; j < prevLine.chars.length; j++) {
  #|               const cw = getCharWidth(prevLine.chars[j]);
  #|               if (w + cw > targetCol) break;
  #|               w += cw;
  #|               newCursor = prevLine.startIdx + j + 1;
  #|             }
  #|             cursor = Math.min(newCursor, prevLine.startIdx + prevLine.chars.length);
  #|             needRender = true;
  #|           }
  #|           i += 3;
  #|           continue;
  #|         }
  #|         if (chunk.startsWith('\x1b[B', i)) {
  #|           const lines = wrapText(chars);
  #|           const pos = findCursorPos(lines, cursor);
  #|           if (pos.lineIdx < lines.length - 1) {
  #|             const nextLine = lines[pos.lineIdx + 1];
  #|             let targetCol = pos.colOffset;
  #|             let newCursor = nextLine.startIdx;
  #|             let w = 0;
  #|             for (let j = 0; j < nextLine.chars.length; j++) {
  #|               const cw = getCharWidth(nextLine.chars[j]);
  #|               if (w + cw > targetCol) break;
  #|               w += cw;
  #|               newCursor = nextLine.startIdx + j + 1;
  #|             }
  #|             cursor = Math.min(newCursor, nextLine.startIdx + nextLine.chars.length);
  #|             needRender = true;
  #|           }
  #|           i += 3;
  #|           continue;
  #|         }
  #|         if (chunk.startsWith('\x1b[1~', i)) {
  #|           cursor = 0;
  #|           needRender = true;
  #|           i += 4;
  #|           continue;
  #|         }
  #|         if (chunk.startsWith('\x1b[F', i)) {
  #|           cursor = chars.length;
  #|           needRender = true;
  #|           i += 3;
  #|           continue;
  #|         }
  #|         if (chunk.startsWith('\x1b[4~', i)) {
  #|           cursor = chars.length;
  #|           needRender = true;
  #|           i += 4;
  #|           continue;
  #|         }
  #|         if (chunk.startsWith('\x1b[', i) || chunk.startsWith('\x1bO', i)) {
  #|           i += 2;
  #|           while (i < chunk.length) {
  #|             const c = chunk[i];
  #|             i += 1;
  #|             if (c >= '@' && c <= '~') {
  #|               break;
  #|             }
  #|           }
  #|           continue;
  #|         }
  #|         if (chunk.length === 1) {
  #|           if (escCancels) {
  #|             cancel();
  #|             return;
  #|           }
  #|           i += 1;
  #|           continue;
  #|         }
  #|         i += 1;
  #|         continue;
  #|       }
  #|
  #|       const code = chunk.codePointAt(i);
  #|       const ch = String.fromCodePoint(code);
  #|       const size = ch.length;
  #|       i += size;
  #|
  #|       if (ch === '\x03') {
  #|         forceQuit();
  #|         return;
  #|       }
  #|       if (ch === '\x7f' || ch === '\x08') {
  #|         if (cursor > 0) {
  #|           chars.splice(cursor - 1, 1);
  #|           cursor -= 1;
  #|           needRender = true;
  #|         }
  #|         continue;
  #|       }
  #|       if (ch === '\x01') {
  #|         const bounds = lineBounds(cursor);
  #|         cursor = bounds.start;
  #|         needRender = true;
  #|         continue;
  #|       }
  #|       if (ch === '\x05') {
  #|         const bounds = lineBounds(cursor);
  #|         cursor = bounds.end;
  #|         needRender = true;
  #|         continue;
  #|       }
  #|       if (ch === '\r' || ch === '\n') {
  #|         if (confirmOnShiftEnter) {
  #|           chars.splice(cursor, 0, '\n');
  #|           cursor += 1;
  #|           needRender = true;
  #|           continue;
  #|         }
  #|         const result = chars.length > 0 ? bufferString() : initialText;
  #|         finish(result);
  #|         return;
  #|       }
  #|
  #|       chars.splice(cursor, 0, ch);
  #|       cursor += 1;
  #|       needRender = true;
  #|     }
  #|
  #|     if (needRender) {
  #|       if (!renderAll()) {
  #|         requestCursorPos();
  #|         if (chars.length > 0) {
  #|           stdout.write(bufferString());
  #|         }
  #|       }
  #|     }
  #|   };
  #|
  #|   stdin.__cookedHandler = onData;
  #|   stdin.on('data', onData);
  #| }

///|
/// Start an inline input session (stays in current screen)
/// Uses raw mode for reliable input handling
/// Enter confirms, Escape cancels, Backspace deletes
/// Supports text wrapping within max_width
extern "js" fn js_start_inline_input(
  label : String,
  initial : String,
  start_row : Int,
  start_col : Int,
  max_width : Int,
  max_height : Int,
  on_confirmed : (String) -> Unit,
  on_cancelled : () -> Unit,
  on_tab_next : (String) -> Unit,
  on_tab_prev : (String) -> Unit,
) -> Unit =
  #| async (label, initial, startRow, startCol, maxWidth, maxHeight, onConfirmed, onCancelled, onTabNext, onTabPrev) => {
  #|   const { stdin, stdout } = await import('node:process');
  #|
  #|   // Helper to get display width of a character (1 for half-width, 2 for full-width)
  #|   const getCharWidth = (char) => {
  #|     const code = char.codePointAt(0);
  #|     if (code >= 0x1100 && (
  #|       code <= 0x115F ||
  #|       code === 0x2329 || code === 0x232A ||
  #|       (code >= 0x2E80 && code <= 0x303E) ||
  #|       (code >= 0x3040 && code <= 0x33FF) ||
  #|       (code >= 0x3400 && code <= 0x4DBF) ||
  #|       (code >= 0x4E00 && code <= 0x9FFF) ||
  #|       (code >= 0xAC00 && code <= 0xD7A3) ||
  #|       (code >= 0xF900 && code <= 0xFAFF) ||
  #|       (code >= 0xFE10 && code <= 0xFE1F) ||
  #|       (code >= 0xFE30 && code <= 0xFE6F) ||
  #|       (code >= 0xFF00 && code <= 0xFF60) ||
  #|       (code >= 0xFFE0 && code <= 0xFFE6) ||
  #|       (code >= 0x20000 && code <= 0x2FFFF)
  #|     )) {
  #|       return 2;
  #|     }
  #|     return 1;
  #|   };
  #|
  #|   // Get total display width of a string
  #|   const getStringWidth = (str) => {
  #|     let width = 0;
  #|     for (const char of str) {
  #|       width += getCharWidth(char);
  #|     }
  #|     return width;
  #|   };
  #|
  #|   // Render buffer with wrapping, returns cursor position
  #|   const renderBuffer = (buf) => {
  #|     let row = startRow;
  #|     let col = startCol;
  #|     let output = '';
  #|
  #|     // Move to start position and clear area
  #|     output += `\x1b[${startRow};${startCol}H`;
  #|     for (let r = 0; r < maxHeight; r++) {
  #|       output += `\x1b[${startRow + r};${startCol}H`;
  #|       output += ' '.repeat(maxWidth);
  #|     }
  #|     output += `\x1b[${startRow};${startCol}H`;
  #|
  #|     // Render text with wrapping
  #|     let lineWidth = 0;
  #|     for (const char of buf) {
  #|       const charWidth = getCharWidth(char);
  #|       if (lineWidth + charWidth > maxWidth) {
  #|         // Wrap to next line
  #|         row++;
  #|         col = startCol;
  #|         lineWidth = 0;
  #|         output += `\x1b[${row};${col}H`;
  #|       }
  #|       output += char;
  #|       lineWidth += charWidth;
  #|       col += charWidth;
  #|     }
  #|
  #|     stdout.write(output);
  #|     return { row, col };
  #|   };
  #|
  #|   // Clear all listeners for clean state
  #|   stdin.removeAllListeners('keypress');
  #|   stdin.removeAllListeners('data');
  #|   stdin.__dataHandler = null;
  #|
  #|   // Use raw mode for character-by-character input
  #|   if (stdin.isTTY) {
  #|     stdin.setRawMode(true);
  #|   }
  #|   stdin.resume();
  #|   stdin.setEncoding('utf8');
  #|
  #|   // Display initial value
  #|   let buffer = initial || '';
  #|   renderBuffer(buffer);
  #|
  #|   let done = false;
  #|
  #|   const cleanup = () => {
  #|     if (done) return;
  #|     done = true;
  #|     stdin.removeListener('data', onData);
  #|   };
  #|
  #|   const onData = (chunk) => {
  #|     if (done) return;
  #|
  #|     // Check for escape sequences first (they come as multi-char chunks)
  #|     if (chunk === '\x1b[Z') {
  #|       // Shift+Tab - confirm and go to previous
  #|       cleanup();
  #|       onTabPrev(buffer);
  #|       return;
  #|     }
  #|     if (chunk === '\x1b' || chunk.startsWith('\x1b[')) {
  #|       // Escape or other escape sequence - cancel
  #|       cleanup();
  #|       onCancelled();
  #|       return;
  #|     }
  #|
  #|     let needsRender = false;
  #|     for (const char of chunk) {
  #|       const code = char.charCodeAt(0);
  #|
  #|       if (code === 9) {
  #|         // Tab - confirm and go to next
  #|         cleanup();
  #|         onTabNext(buffer);
  #|         return;
  #|       } else if (code === 13) {
  #|         // Enter - confirm
  #|         cleanup();
  #|         onConfirmed(buffer);
  #|         return;
  #|       } else if (code === 3) {
  #|         // Ctrl+C - cancel
  #|         cleanup();
  #|         onCancelled();
  #|         return;
  #|       } else if (code === 127 || code === 8) {
  #|         // Backspace - delete last character
  #|         if (buffer.length > 0) {
  #|           const chars = [...buffer];
  #|           chars.pop();
  #|           buffer = chars.join('');
  #|           needsRender = true;
  #|         }
  #|       } else if (code >= 32) {
  #|         // Printable character - check if within bounds
  #|         const newWidth = getStringWidth(buffer + char);
  #|         const maxTotalWidth = maxWidth * maxHeight;
  #|         if (newWidth <= maxTotalWidth) {
  #|           buffer += char;
  #|           needsRender = true;
  #|         }
  #|       }
  #|     }
  #|
  #|     if (needsRender) {
  #|       renderBuffer(buffer);
  #|     }
  #|   };
  #|
  #|   stdin.on('data', onData);
  #| }

///|
/// Start an inline input session with cooked mode (for IME support)
/// Temporarily exits alternate screen for proper IME input
/// field_name: Display name for the field being edited
/// initial: Current value to pre-fill
pub fn start_inline_input_cooked(
  field_name : String,
  initial : String,
  on_result : (InputResult) -> Unit,
  confirm_on_shift_enter? : Bool = false,
  esc_cancels? : Bool = true,
) -> Unit {
  js_start_inline_input_cooked(
    field_name,
    initial,
    confirm_on_shift_enter,
    esc_cancels,
    fn(value) { on_result(InputResult::Confirmed(value)) },
    fn() { on_result(InputResult::Cancelled) },
    fn() { on_result(InputResult::ForceQuit) },
  )
}

///|
/// Start an inplace input session with cooked mode (IME enabled)
/// Stays in alternate screen, edits at specified position
/// row/col are 1-indexed ANSI coordinates
/// width is the max display width for the input
pub fn start_inplace_input(
  row : Int,
  col : Int,
  width : Int,
  height : Int,
  multiline : Bool,
  initial : String,
  on_result : (InputResult) -> Unit,
  confirm_on_shift_enter? : Bool = false,
  esc_cancels? : Bool = true,
  on_lines_change? : ((Int) -> Int)? = None,
  on_completion? : ((String, Int) -> String?)? = None,
) -> Unit {
  // Create controller with configuration
  let config = @input.TextInputConfig::new(
    width,
    height,
    multiline~,
    confirm_on_shift_enter~,
    esc_cancels~,
  )
  let controller = @input.TextInputController::new(config, initial)

  // Current height (can change dynamically)
  let current_height = Ref::new(height)
  // Base row is the bottom of input area (fixed)
  let base_row = row + height - 1

  // Helper to render and position cursor with scroll
  fn do_render() {
    let state = controller.get_display_state()
    // Calculate current start row (grows upward)
    let old_height = current_height.val
    let old_start_row = base_row - old_height + 1
    // Update height if callback provided
    match on_lines_change {
      Some(callback) => {
        let new_height = callback(state.total_lines)
        if new_height != current_height.val {
          current_height.val = new_height
          controller.resize(width, new_height)
        }
      }
      None => ()
    }
    // Calculate new start row
    let start_row = base_row - current_height.val + 1
    // Clear old area if height changed
    if old_height != current_height.val {
      if current_height.val < old_height {
        // Shrinking: clear above
        for r = old_start_row; r < start_row; r = r + 1 {
          print_raw(
            "\u001b[" +
            r.to_string() +
            ";" +
            col.to_string() +
            "H" +
            " ".repeat(width),
          )
        }
      } else {
        // Growing: clear new area above
        for r = start_row; r < old_start_row; r = r + 1 {
          print_raw(
            "\u001b[" +
            r.to_string() +
            ";" +
            col.to_string() +
            "H" +
            " ".repeat(width),
          )
        }
      }
    }
    // Get updated state after potential resize
    let state = controller.get_display_state()
    // Render with scroll (at calculated start row)
    render_display_state(state, start_row, col, width, current_height.val)
    // Position cursor
    let display_row = start_row + state.cursor_line - state.scroll_offset
    let display_col = col + state.cursor_col
    print_raw(
      "\u001b[" + display_row.to_string() + ";" + display_col.to_string() + "H",
    )
    print_raw(@render.ansi_show_cursor())
  }

  // Initial render
  do_render()

  // Track if done
  let done = Ref::new(false)

  // Key handler
  let handle_key : (String) -> Unit = fn(key) {
    if done.val {
      return
    }

    // Parse input and extract KeyEvent
    let input_event = @events.parse_input(key)
    let action = match input_event {
      @events.InputEvent::Key(key_event) =>
        @input.interpret_key(key_event, config)
      _ => @input.EditAction::None
    }

    // Handle special actions that require custom logic
    match action {
      @input.EditAction::Tab => {
        // Tab - try completion first, then confirm and go to next
        let mut handled_by_completion = false
        match on_completion {
          Some(provider) => {
            let text = controller.get_text()
            let completion_result = provider(text, controller.get_cursor_pos())
            match completion_result {
              Some(suffix) =>
                if suffix.length() > 0 {
                  let _ = controller.apply_action(
                    @input.EditAction::Insert(suffix),
                  )
                  do_render()
                  handled_by_completion = true
                }
              None => ()
            }
          }
          None => ()
        }
        if not(handled_by_completion) {
          done.val = true
          js_cleanup_raw_input_listener()
          on_result(InputResult::TabNext(controller.get_text()))
        }
      }
      @input.EditAction::BackTab => {
        done.val = true
        js_cleanup_raw_input_listener()
        on_result(InputResult::TabPrev(controller.get_text()))
      }
      @input.EditAction::Confirm => {
        done.val = true
        js_cleanup_raw_input_listener()
        on_result(InputResult::Confirmed(controller.get_text()))
      }
      @input.EditAction::Cancel => {
        done.val = true
        js_cleanup_raw_input_listener()
        on_result(InputResult::Cancelled)
      }
      @input.EditAction::ForceQuit => {
        done.val = true
        js_cleanup_raw_input_listener()
        on_result(InputResult::ForceQuit)
      }
      @input.EditAction::None => ()
      _ => {
        // Apply edit action to controller
        let handled = controller.apply_action(action)
        if handled {
          do_render()
        }
      }
    }
  }

  // Cleanup handler
  let cleanup_handler : () -> Unit = fn() {
    print_raw(@render.ansi_hide_cursor())
  }

  // Setup listener
  js_setup_raw_input_listener(handle_key, cleanup_handler)
}

///|
/// Start an inline input session (for editing in place)
/// row/col are 1-indexed ANSI coordinates
/// max_width/max_height define the input area for text wrapping
pub fn start_inline_input(
  label : String,
  initial : String,
  row : Int,
  col : Int,
  max_width : Int,
  max_height : Int,
  on_result : (InputResult) -> Unit,
) -> Unit {
  js_start_inline_input(
    label,
    initial,
    row,
    col,
    max_width,
    max_height,
    fn(value) { on_result(InputResult::Confirmed(value)) },
    fn() { on_result(InputResult::Cancelled) },
    fn(value) { on_result(InputResult::TabNext(value)) },
    fn(value) { on_result(InputResult::TabPrev(value)) },
  )
}

///|
/// Read a key asynchronously
pub async fn read_key() -> String {
  @js_async.Promise::wait(js_read_key())
}

///|
/// Print string to stdout (no newline)
pub fn print_raw(s : String) -> Unit {
  js_print_raw(s)
}

///|
/// Cleanup stdin state
pub fn cleanup_stdin() -> Unit {
  js_cleanup_stdin()
  raw_mode_flag.val = false
}

///|
/// Enable raw mode
pub fn enable_raw_mode() -> Unit {
  js_enable_raw_mode()
  raw_mode_flag.val = true
}

///|
/// Get terminal size (columns, rows)
pub fn get_terminal_size() -> (Int, Int) {
  (js_get_terminal_columns(), js_get_terminal_rows())
}

///|
/// Sleep for milliseconds
pub async fn sleep(ms : Int) -> Unit {
  @js_async.Promise::wait(js_sleep(ms))
}

// --- Input Session for IME support ---

///|
/// Start an input session with callback (non-blocking)
extern "js" fn js_start_input_session_callback(
  initial : String,
  on_confirmed : (String) -> Unit,
  on_cancelled : () -> Unit,
) -> Unit =
  #| async (initial, onConfirmed, onCancelled) => {
  #|   const rl = await import('node:readline/promises');
  #|   const { stdin, stdout } = await import('node:process');
  #|
  #|   // Show cursor
  #|   stdout.write('\x1b[?25h');
  #|
  #|   // Reset stdin state for readline
  #|   stdin.removeAllListeners('keypress');
  #|   if (stdin.isTTY) {
  #|     stdin.setRawMode(false);
  #|   }
  #|
  #|   const readline = rl.createInterface({
  #|     input: stdin,
  #|     output: stdout,
  #|   });
  #|
  #|   try {
  #|     // Pre-fill and get answer
  #|     const answer = await readline.question('> ' + initial);
  #|     readline.close();
  #|     onConfirmed(answer);
  #|   } catch (err) {
  #|     readline.close();
  #|     onCancelled();
  #|   }
  #| }

///|
/// Legacy Promise-based version (kept for reference, may not work properly)
extern "js" fn js_start_input_session(
  x : Int,
  y : Int,
  initial : String,
) -> @js_async.Promise[String] =
  #| async (x, y, initial) => {
  #|   return new Promise((resolve) => {
  #|     // This version may block the event loop - use callback version instead
  #|     resolve('cancelled:');
  #|   });
  #| }

///|
/// Abort the current input session
extern "js" fn js_abort_input_session() =
  #| () => {
  #|   if (globalThis.__inputSession && globalThis.__inputSession.active) {
  #|     globalThis.__inputSession.active = false;
  #|     if (globalThis.__inputSession.rl) {
  #|       globalThis.__inputSession.rl.close();
  #|     }
  #|     if (globalThis.__inputSession.resolve) {
  #|       globalThis.__inputSession.resolve('cancelled:');
  #|     }
  #|   }
  #| }

///|
/// Start a render ticker (setInterval)
extern "js" fn js_start_render_ticker(ms : Int, callback : () -> Unit) -> Int =
  #| (ms, cb) => setInterval(cb, ms)

///|
/// Stop a render ticker
extern "js" fn js_stop_render_ticker(ticker_id : Int) =
  #| (id) => clearInterval(id)

///|
/// Start an input session (callback-based, non-blocking)
/// This is the recommended way to read input - it doesn't block the event loop
pub fn start_input_session_cb(
  initial : String,
  on_result : (InputResult) -> Unit,
) -> Unit {
  js_start_input_session_callback(
    initial,
    fn(value) { on_result(InputResult::Confirmed(value)) },
    fn() { on_result(InputResult::Cancelled) },
  )
}

///|
/// Start an input session that returns a Promise (for async/await)
/// This wraps the callback-based API in a Promise created on the JS side
extern "js" fn js_start_input_session_promise(
  initial : String,
) -> @js_async.Promise[InputResult] =
  #| async (initial) => {
  #|   const rl = await import('node:readline/promises');
  #|   const { stdin, stdout } = await import('node:process');
  #|
  #|   // Show cursor
  #|   stdout.write('\x1b[?25h');
  #|
  #|   // Reset stdin state for readline
  #|   stdin.removeAllListeners('keypress');
  #|   if (stdin.isTTY) {
  #|     stdin.setRawMode(false);
  #|   }
  #|
  #|   const readline = rl.createInterface({
  #|     input: stdin,
  #|     output: stdout,
  #|   });
  #|
  #|   try {
  #|     const answer = await readline.question('> ' + initial);
  #|     readline.close();
  #|     return { $tag: "Confirmed", _0: answer };
  #|   } catch (err) {
  #|     readline.close();
  #|     return { $tag: "Cancelled" };
  #|   }
  #| }

///|
/// Start an input session that returns a Promise (for async/await)
/// Use with @js_async.Promise::wait() in async functions
pub fn start_input_session_promise(
  initial : String,
) -> @js_async.Promise[InputResult] {
  js_start_input_session_promise(initial)
}

///|
/// Start an input session (async version - may not work with raw mode)
/// WARNING: This uses Promise::wait which can block the Node.js event loop
/// Use start_input_session_cb instead for reliable operation
pub async fn start_input_session(
  x : Int,
  y : Int,
  initial : String,
) -> InputResult {
  // This version doesn't work properly after raw mode - returns cancelled immediately
  let result = @js_async.Promise::wait(js_start_input_session(x, y, initial))
  if result.has_prefix("confirmed:") {
    InputResult::Confirmed(result[10:].to_string())
  } else {
    InputResult::Cancelled
  }
}

///|
/// Abort the current input session
pub fn abort_input_session() -> Unit {
  js_abort_input_session()
}

///|
/// Start a render ticker that calls the callback every `ms` milliseconds
pub fn start_render_ticker(ms : Int, callback : () -> Unit) -> Int {
  js_start_render_ticker(ms, callback)
}

///|
/// Stop a render ticker
pub fn stop_render_ticker(ticker_id : Int) -> Unit {
  js_stop_render_ticker(ticker_id)
}

// --- Functions for native compatibility ---

///|
/// Check if raw mode is enabled (always true after enable_raw_mode in JS)
let raw_mode_flag : Ref[Bool] = { val: false }

///|
pub fn is_raw_mode() -> Bool {
  raw_mode_flag.val
}

///|
/// Check if stdin is a TTY (always true in JS terminal context)
pub fn is_tty() -> Bool {
  true
}

///|
/// Poll for keypress (not applicable in JS - use start_keypress_listener instead)
/// Returns false as JS uses event-driven model
pub fn poll_keypress() -> Bool {
  // JS uses event-driven model, not polling
  false
}

// --- Resize Event Listener ---

///|
/// Start a resize listener (event-driven)
/// Callback receives (width, height) when terminal is resized
extern "js" fn js_start_resize_listener(callback : (Int, Int) -> Unit) =
  #| async (callback) => {
  #|   const { stdout } = await import('node:process');
  #|
  #|   const onResize = () => {
  #|     const cols = stdout.columns || 80;
  #|     const rows = stdout.rows || 24;
  #|     callback(cols, rows);
  #|   };
  #|
  #|   stdout.__resizeHandler = onResize;
  #|   stdout.on('resize', onResize);
  #| }

///|
/// Stop the resize listener
extern "js" fn js_stop_resize_listener() =
  #| async () => {
  #|   const { stdout } = await import('node:process');
  #|
  #|   if (stdout.__resizeHandler) {
  #|     stdout.removeListener('resize', stdout.__resizeHandler);
  #|     delete stdout.__resizeHandler;
  #|   }
  #| }

///|
/// Start listening for terminal resize events
/// Callback receives (width, height) when terminal is resized
pub fn start_resize_listener(callback : (Int, Int) -> Unit) -> Unit {
  js_start_resize_listener(callback)
}

///|
/// Stop listening for resize events
pub fn stop_resize_listener() -> Unit {
  js_stop_resize_listener()
}

// --- Environment and Arguments ---

///|
/// Get command line arguments (excluding node and script path)
extern "js" fn js_get_args() -> Array[String] =
  #| () => {
  #|   if (typeof process === 'undefined') return [];
  #|   return process.argv.slice(2);
  #| }

///|
/// Get an environment variable value (empty string if not set)
extern "js" fn js_get_env(name : String) -> String =
  #| (name) => {
  #|   if (typeof process === 'undefined') return '';
  #|   return process.env[name] || '';
  #| }

///|
/// Get command line arguments
pub fn get_args() -> Array[String] {
  js_get_args()
}

///|
/// Get environment variable value (empty string if not set)
pub fn get_env(name : String) -> String {
  js_get_env(name)
}

///|
/// Check if running in headless mode (TUI_HEADLESS=1 or --headless argument)
pub fn is_headless() -> Bool {
  if js_get_env("TUI_HEADLESS") == "1" {
    return true
  }
  let args = js_get_args()
  for arg in args {
    if arg == "--headless" {
      return true
    }
  }
  false
}

// ===== TextInputController-based implementation =====

///|
/// Render display state with scroll support (shared with native)
fn render_display_state(
  state : @input.DisplayState,
  start_row : Int,
  start_col : Int,
  max_width : Int,
  max_height : Int,
) -> Unit {
  let mut output = ""
  // Clear area
  for r = 0; r < max_height; r = r + 1 {
    output = output +
      "\u001b[" +
      (start_row + r).to_string() +
      ";" +
      start_col.to_string() +
      "H"
    for w = 0; w < max_width; w = w + 1 {
      output = output + " "
    }
  }
  // Draw visible lines
  for i = 0; i < max_height; i = i + 1 {
    let line_idx = state.scroll_offset + i
    if line_idx >= state.lines.length() {
      break
    }
    let line = state.lines[line_idx]
    output = output +
      "\u001b[" +
      (start_row + i).to_string() +
      ";" +
      start_col.to_string() +
      "H"
    // Show ellipsis for overflow
    if i == 0 && state.has_more_above {
      output = output + "…"
      let mut w = 1
      for c in line.chars {
        let cw = @core.char_display_width(c)
        if w + cw > max_width {
          break
        }
        output = output + c.to_string()
        w = w + cw
      }
    } else if i == max_height - 1 && state.has_more_below {
      let mut w = 0
      for c in line.chars {
        let cw = @core.char_display_width(c)
        if w + cw > max_width - 1 {
          break
        }
        output = output + c.to_string()
        w = w + cw
      }
      output = output + "…"
    } else {
      for c in line.chars {
        output = output + c.to_string()
      }
    }
  }
  print_raw(output)
}

///|
/// Setup raw input listener that calls onKey callback for each keystroke
extern "js" fn js_setup_raw_input_listener(
  on_key : (String) -> Unit,
  on_cleanup : () -> Unit,
) -> Unit =
  #| async (onKey, onCleanup) => {
  #|   const { stdin, stdout } = await import('node:process');
  #|
  #|   // Clean up existing handlers
  #|   if (stdin.__rawInputHandler) {
  #|     stdin.removeListener('data', stdin.__rawInputHandler);
  #|     stdin.__rawInputHandler = null;
  #|   }
  #|
  #|   if (stdin.isTTY) {
  #|     stdin.setRawMode(true);
  #|   }
  #|   stdin.resume();
  #|   stdin.setEncoding('utf8');
  #|
  #|   const handler = (data) => {
  #|     onKey(data);
  #|   };
  #|
  #|   stdin.__rawInputHandler = handler;
  #|   stdin.__rawInputCleanup = onCleanup;
  #|   stdin.on('data', handler);
  #| }

///|
/// Cleanup raw input listener
extern "js" fn js_cleanup_raw_input_listener() =
  #| async () => {
  #|   const { stdin } = await import('node:process');
  #|
  #|   if (stdin.__rawInputHandler) {
  #|     stdin.removeListener('data', stdin.__rawInputHandler);
  #|     stdin.__rawInputHandler = null;
  #|   }
  #|   if (stdin.__rawInputCleanup) {
  #|     stdin.__rawInputCleanup();
  #|     stdin.__rawInputCleanup = null;
  #|   }
  #|   if (stdin.isTTY) {
  #|     stdin.setRawMode(false);
  #|   }
  #| }
