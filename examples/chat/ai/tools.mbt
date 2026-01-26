///|
/// Tool execution for Claude API (JS target only)

///|
/// Read file contents
extern "js" fn js_read_file(path : String) -> String =
  #| (path) => {
  #|   try {
  #|     const fs = require('fs');
  #|     return fs.readFileSync(path, 'utf-8');
  #|   } catch (e) {
  #|     return '[Error: ' + e.message + ']';
  #|   }
  #| }

///|
/// Write content to file
extern "js" fn js_write_file(path : String, content : String) -> String =
  #| (path, content) => {
  #|   try {
  #|     const fs = require('fs');
  #|     fs.writeFileSync(path, content, 'utf-8');
  #|     return 'Successfully wrote to ' + path;
  #|   } catch (e) {
  #|     return '[Error: ' + e.message + ']';
  #|   }
  #| }

///|
/// List directory contents
extern "js" fn js_list_dir(path : String) -> String =
  #| (path) => {
  #|   try {
  #|     const fs = require('fs');
  #|     const entries = fs.readdirSync(path, { withFileTypes: true });
  #|     return entries.map(e => (e.isDirectory() ? '[DIR] ' : '      ') + e.name).join('\n');
  #|   } catch (e) {
  #|     return '[Error: ' + e.message + ']';
  #|   }
  #| }

///|
/// Run shell command
extern "js" fn js_run_command(command : String) -> String =
  #| (command) => {
  #|   try {
  #|     const { execSync } = require('child_process');
  #|     const result = execSync(command, { encoding: 'utf-8', timeout: 30000 });
  #|     return result;
  #|   } catch (e) {
  #|     if (e.stdout) return e.stdout + '\n[Exit code: ' + e.status + ']';
  #|     return '[Error: ' + e.message + ']';
  #|   }
  #| }

///|
/// Parse JSON string to get a field value
extern "js" fn js_json_get(json_str : String, field : String) -> String =
  #| (jsonStr, field) => {
  #|   try {
  #|     const obj = JSON.parse(jsonStr);
  #|     const val = obj[field];
  #|     return val === undefined || val === null ? '' : String(val);
  #|   } catch (e) {
  #|     return '';
  #|   }
  #| }

///|
/// Escape string for shell command (prevent injection)
extern "js" fn js_shell_escape(s : String) -> String =
  #| (s) => {
  #|   // Replace dangerous characters with escaped versions
  #|   return s.replace(/[`$\\;"'|&<>(){}[\]!#~*?\n\r]/g, '');
  #| }

///|
/// Parse JSON to get integer field
extern "js" fn js_json_get_int(
  json_str : String,
  field : String,
  default_val : Int,
) -> Int =
  #| (jsonStr, field, defaultVal) => {
  #|   try {
  #|     const obj = JSON.parse(jsonStr);
  #|     return typeof obj[field] === 'number' ? obj[field] : defaultVal;
  #|   } catch (e) {
  #|     return defaultVal;
  #|   }
  #| }

///|
/// Parse JSON to get boolean field
extern "js" fn js_json_get_bool(json_str : String, field : String) -> Bool =
  #| (jsonStr, field) => {
  #|   try {
  #|     const obj = JSON.parse(jsonStr);
  #|     return Boolean(obj[field]);
  #|   } catch (e) {
  #|     return false;
  #|   }
  #| }

///|
/// Grep search in files (with input sanitization)
extern "js" fn js_grep_search(
  pattern : String,
  path : String,
  file_pattern : String,
) -> String =
  #| (pattern, path, filePattern) => {
  #|   try {
  #|     const { execSync } = require('child_process');
  #|     // Sanitize inputs - remove shell metacharacters
  #|     const sanitize = s => s.replace(/[`$\\;"'|&<>(){}[\]!#~?\n\r]/g, '');
  #|     const safePattern = sanitize(pattern);
  #|     const safePath = sanitize(path) || '.';
  #|     const safeFilePattern = sanitize(filePattern) || '*';
  #|     let cmd = `grep -rn --include="${safeFilePattern}" "${safePattern}" "${safePath}" 2>/dev/null | head -50`;
  #|     const result = execSync(cmd, { encoding: 'utf-8', timeout: 10000 });
  #|     return result || '[No matches found]';
  #|   } catch (e) {
  #|     if (e.status === 1) return '[No matches found]';
  #|     return '[Error: ' + e.message + ']';
  #|   }
  #| }

///|
/// Git diff (with input sanitization)
extern "js" fn js_git_diff(file : String, staged : Bool) -> String =
  #| (file, staged) => {
  #|   try {
  #|     const { execSync } = require('child_process');
  #|     let cmd = staged ? 'git diff --staged' : 'git diff';
  #|     if (file) {
  #|       // Sanitize file path
  #|       const safeFile = file.replace(/[`$\\;"'|&<>(){}[\]!#~*?\n\r]/g, '');
  #|       cmd += ` "${safeFile}"`;
  #|     }
  #|     const result = execSync(cmd, { encoding: 'utf-8', timeout: 10000 });
  #|     return result || '[No changes]';
  #|   } catch (e) {
  #|     return '[Error: ' + e.message + ']';
  #|   }
  #| }

///|
/// Directory tree
extern "js" fn js_tree(path : String, depth : Int, pattern : String) -> String =
  #| (path, depth, pattern) => {
  #|   try {
  #|     const fs = require('fs');
  #|     const nodePath = require('path');
  #|     const rootPath = path || '.';
  #|     const maxDepth = depth || 3;
  #|     const results = [];
  #|
  #|     function walk(dir, prefix, currentDepth) {
  #|       if (currentDepth > maxDepth) return;
  #|       let entries;
  #|       try {
  #|         entries = fs.readdirSync(dir, { withFileTypes: true });
  #|       } catch (e) { return; }
  #|
  #|       // Filter hidden and common ignore patterns
  #|       entries = entries.filter(e => !e.name.startsWith('.') &&
  #|         !['node_modules', '_build', 'target', '.mooncakes'].includes(e.name));
  #|
  #|       // Apply pattern filter if specified
  #|       if (pattern) {
  #|         const regex = new RegExp(pattern.replace(/\*/g, '.*'));
  #|         entries = entries.filter(e => e.isDirectory() || regex.test(e.name));
  #|       }
  #|
  #|       entries.forEach((entry, i) => {
  #|         const isLast = i === entries.length - 1;
  #|         const connector = isLast ? '└── ' : '├── ';
  #|         const icon = entry.isDirectory() ? '📁 ' : '   ';
  #|         results.push(prefix + connector + icon + entry.name);
  #|
  #|         if (entry.isDirectory()) {
  #|           const newPrefix = prefix + (isLast ? '    ' : '│   ');
  #|           walk(nodePath.join(dir, entry.name), newPrefix, currentDepth + 1);
  #|         }
  #|       });
  #|     }
  #|
  #|     results.push('📁 ' + rootPath);
  #|     walk(rootPath, '', 1);
  #|     return results.join('\n');
  #|   } catch (e) {
  #|     return '[Error: ' + e.message + ']';
  #|   }
  #| }

///|
/// Execute tool by name with input JSON
pub fn execute_tool(tool_name : String, input_json : String) -> String {
  match tool_name {
    "read_file" => {
      let path = js_json_get(input_json, "path")
      if path.length() == 0 {
        "[Error: missing 'path' parameter]"
      } else {
        js_read_file(path)
      }
    }
    "write_file" => {
      let path = js_json_get(input_json, "path")
      let content = js_json_get(input_json, "content")
      if path.length() == 0 {
        "[Error: missing 'path' parameter]"
      } else {
        js_write_file(path, content)
      }
    }
    "list_dir" => {
      let path = js_json_get(input_json, "path")
      let target = if path.length() == 0 { "." } else { path }
      js_list_dir(target)
    }
    "run_command" => {
      let command = js_json_get(input_json, "command")
      if command.length() == 0 {
        "[Error: missing 'command' parameter]"
      } else {
        js_run_command(command)
      }
    }
    "grep_search" => {
      let pattern = js_json_get(input_json, "pattern")
      if pattern.length() == 0 {
        "[Error: missing 'pattern' parameter]"
      } else {
        let path = js_json_get(input_json, "path")
        let file_pattern = js_json_get(input_json, "file_pattern")
        js_grep_search(pattern, path, file_pattern)
      }
    }
    "git_diff" => {
      let file = js_json_get(input_json, "file")
      let staged = js_json_get_bool(input_json, "staged")
      js_git_diff(file, staged)
    }
    "tree" => {
      let path = js_json_get(input_json, "path")
      let depth = js_json_get_int(input_json, "depth", 3)
      let pattern = js_json_get(input_json, "pattern")
      js_tree(path, depth, pattern)
    }
    "moon_peek_def" => {
      let symbol = js_json_get(input_json, "symbol")
      if symbol.length() == 0 {
        "[Error: missing 'symbol' parameter]"
      } else {
        let safe_symbol = js_shell_escape(symbol)
        js_run_command("moon ide peek-def " + safe_symbol + " 2>&1 | head -100")
      }
    }
    "moon_outline" => {
      let file = js_json_get(input_json, "file")
      if file.length() == 0 {
        "[Error: missing 'file' parameter]"
      } else {
        let safe_file = js_shell_escape(file)
        js_run_command("moon ide outline " + safe_file + " 2>&1")
      }
    }
    "moon_doc" => {
      let query = js_json_get(input_json, "query")
      if query.length() == 0 {
        "[Error: missing 'query' parameter]"
      } else {
        let safe_query = js_shell_escape(query)
        js_run_command("moon doc '" + safe_query + "' 2>&1 | head -100")
      }
    }
    _ => "[Error: unknown tool '" + tool_name + "']"
  }
}
