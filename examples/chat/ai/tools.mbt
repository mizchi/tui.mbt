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
pub extern "js" fn js_write_file(path : String, content : String) -> String =
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
/// Get current working directory
pub extern "js" fn js_get_cwd() -> String =
  #| () => {
  #|   try {
  #|     return process.cwd();
  #|   } catch (e) {
  #|     return '.';
  #|   }
  #| }

///|
/// Join path components
pub extern "js" fn js_path_join(base : String, name : String) -> String =
  #| (base, name) => {
  #|   const path = require('path');
  #|   return path.join(base, name);
  #| }

///|
/// Get parent directory
pub extern "js" fn js_path_dirname(path : String) -> String =
  #| (p) => {
  #|   const path = require('path');
  #|   return path.dirname(p);
  #| }

///|
/// Get basename
pub extern "js" fn js_path_basename(path : String) -> String =
  #| (p) => {
  #|   const path = require('path');
  #|   return path.basename(p);
  #| }

///|
/// Get git status for a directory
/// Returns JSON: {"files": {"path": "status", ...}, "is_repo": true/false}
/// Status: "M" (modified), "A" (added), "D" (deleted), "?" (untracked), "R" (renamed)
/// File paths are relative to the given directory
pub extern "js" fn js_git_status(dir : String) -> String =
  #| (dir) => {
  #|   try {
  #|     const { execSync } = require('child_process');
  #|     const path = require('path');
  #|     // Check if in git repo
  #|     try {
  #|       execSync('git rev-parse --is-inside-work-tree', { cwd: dir, encoding: 'utf-8', stdio: 'pipe' });
  #|     } catch (e) {
  #|       return JSON.stringify({ files: {}, is_repo: false });
  #|     }
  #|     // Get git root directory
  #|     const gitRoot = execSync('git rev-parse --show-toplevel', { cwd: dir, encoding: 'utf-8', stdio: 'pipe' }).trim();
  #|     // Get status (paths are relative to git root)
  #|     const status = execSync('git status --porcelain', { cwd: dir, encoding: 'utf-8', stdio: 'pipe' });
  #|     const files = {};
  #|     for (const line of status.split('\n')) {
  #|       if (line.length < 3) continue;
  #|       const statusCode = line.substring(0, 2).trim();
  #|       const filePath = line.substring(3);
  #|       // Convert to path relative to current dir
  #|       const absPath = path.join(gitRoot, filePath);
  #|       const relPath = path.relative(dir, absPath);
  #|       // Only include files that are in or under current dir (not parent dirs)
  #|       if (!relPath.startsWith('..')) {
  #|         files[relPath] = statusCode[0] || statusCode[1] || '?';
  #|       }
  #|     }
  #|     return JSON.stringify({ files: files, is_repo: true });
  #|   } catch (e) {
  #|     return JSON.stringify({ files: {}, is_repo: false });
  #|   }
  #| }

///|
/// Get list of files with uncommitted changes (git diff + untracked)
/// Returns JSON array of file paths relative to current directory
pub extern "js" fn js_git_changed_files(dir : String) -> String =
  #| (dir) => {
  #|   try {
  #|     const { execSync } = require('child_process');
  #|     const path = require('path');
  #|     // Check if in git repo
  #|     try {
  #|       execSync('git rev-parse --is-inside-work-tree', { cwd: dir, encoding: 'utf-8', stdio: 'pipe' });
  #|     } catch (e) {
  #|       return '[]';
  #|     }
  #|     // Get git root directory
  #|     const gitRoot = execSync('git rev-parse --show-toplevel', { cwd: dir, encoding: 'utf-8', stdio: 'pipe' }).trim();
  #|     // Get changed files (staged + unstaged + untracked)
  #|     const status = execSync('git status --porcelain', { cwd: dir, encoding: 'utf-8', stdio: 'pipe' });
  #|     const files = [];
  #|     for (const line of status.split('\n')) {
  #|       if (line.length < 3) continue;
  #|       const filePath = line.substring(3);
  #|       // Convert to path relative to current dir
  #|       const absPath = path.join(gitRoot, filePath);
  #|       const relPath = path.relative(dir, absPath);
  #|       // Only include files that are in or under current dir
  #|       if (!relPath.startsWith('..')) {
  #|         files.push(relPath);
  #|       }
  #|     }
  #|     return JSON.stringify(files);
  #|   } catch (e) {
  #|     return '[]';
  #|   }
  #| }

///|
/// Read file content (public version for filer)
pub extern "js" fn js_read_file_content(path : String) -> String =
  #| (path) => {
  #|   try {
  #|     const fs = require('fs');
  #|     const stat = fs.statSync(path);
  #|     if (stat.size > 100000) {
  #|       return '[File too large: ' + stat.size + ' bytes]';
  #|     }
  #|     return fs.readFileSync(path, 'utf-8');
  #|   } catch (e) {
  #|     return '[Error: ' + e.message + ']';
  #|   }
  #| }

///|
/// Get git diff for a specific file (unified diff format)
/// Returns empty string if no diff or not in git repo
pub extern "js" fn js_git_diff_file(file_path : String) -> String =
  #| (filePath) => {
  #|   try {
  #|     const { execSync } = require('child_process');
  #|     const path = require('path');
  #|     const dir = path.dirname(filePath);
  #|     // Check if in git repo
  #|     try {
  #|       execSync('git rev-parse --is-inside-work-tree', { cwd: dir, encoding: 'utf-8', stdio: 'pipe' });
  #|     } catch (e) {
  #|       return '';
  #|     }
  #|     // Get diff (both staged and unstaged)
  #|     const diff = execSync(`git diff HEAD -- "${filePath}" 2>/dev/null || git diff -- "${filePath}" 2>/dev/null`, {
  #|       cwd: dir,
  #|       encoding: 'utf-8',
  #|       stdio: 'pipe',
  #|       maxBuffer: 1024 * 1024
  #|     });
  #|     return diff || '';
  #|   } catch (e) {
  #|     return '';
  #|   }
  #| }

///|
/// List directory contents as JSON array
/// Returns: [{"name": "file.txt", "is_dir": false}, ...]
pub extern "js" fn js_list_dir_json(path : String) -> String =
  #| (path) => {
  #|   try {
  #|     const fs = require('fs');
  #|     const entries = fs.readdirSync(path, { withFileTypes: true });
  #|     const result = entries
  #|       .filter(e => !e.name.startsWith('.'))
  #|       .sort((a, b) => {
  #|         if (a.isDirectory() !== b.isDirectory()) {
  #|           return a.isDirectory() ? -1 : 1;
  #|         }
  #|         return a.name.localeCompare(b.name);
  #|       })
  #|       .map(e => ({ name: e.name, is_dir: e.isDirectory() }));
  #|     return JSON.stringify(result);
  #|   } catch (e) {
  #|     return '[]';
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
    "moon_find_refs" => {
      let symbol = js_json_get(input_json, "symbol")
      if symbol.length() == 0 {
        "[Error: missing 'symbol' parameter]"
      } else {
        let safe_symbol = js_shell_escape(symbol)
        js_run_command("moon ide find-references " + safe_symbol + " 2>&1 | head -100")
      }
    }
    _ => "[Error: unknown tool '" + tool_name + "']"
  }
}

///|
/// Get tool definitions in Claude/Anthropic format
pub fn get_claude_tool_definitions() -> String {
  let json =
    #|[
  #|  {
  #|    "name": "read_file",
  #|    "description": "Read the contents of a file at the specified path",
  #|    "input_schema": {
  #|      "type": "object",
  #|      "properties": {
  #|        "path": { "type": "string", "description": "The file path to read" }
  #|      },
  #|      "required": ["path"]
  #|    }
  #|  },
  #|  {
  #|    "name": "write_file",
  #|    "description": "Write content to a file at the specified path",
  #|    "input_schema": {
  #|      "type": "object",
  #|      "properties": {
  #|        "path": { "type": "string", "description": "The file path to write to" },
  #|        "content": { "type": "string", "description": "The content to write" }
  #|      },
  #|      "required": ["path", "content"]
  #|    }
  #|  },
  #|  {
  #|    "name": "list_dir",
  #|    "description": "List contents of a directory",
  #|    "input_schema": {
  #|      "type": "object",
  #|      "properties": {
  #|        "path": { "type": "string", "description": "The directory path to list (defaults to current directory)" }
  #|      },
  #|      "required": []
  #|    }
  #|  },
  #|  {
  #|    "name": "run_command",
  #|    "description": "Run a shell command and return the output",
  #|    "input_schema": {
  #|      "type": "object",
  #|      "properties": {
  #|        "command": { "type": "string", "description": "The shell command to execute" }
  #|      },
  #|      "required": ["command"]
  #|    }
  #|  },
  #|  {
  #|    "name": "grep_search",
  #|    "description": "Search for a pattern in files using grep",
  #|    "input_schema": {
  #|      "type": "object",
  #|      "properties": {
  #|        "pattern": { "type": "string", "description": "The search pattern (regex)" },
  #|        "path": { "type": "string", "description": "Directory to search in (defaults to current directory)" },
  #|        "file_pattern": { "type": "string", "description": "File glob pattern (e.g. '*.mbt')" }
  #|      },
  #|      "required": ["pattern"]
  #|    }
  #|  },
  #|  {
  #|    "name": "git_diff",
  #|    "description": "Show git diff for files",
  #|    "input_schema": {
  #|      "type": "object",
  #|      "properties": {
  #|        "file": { "type": "string", "description": "Specific file to diff (optional)" },
  #|        "staged": { "type": "boolean", "description": "Show staged changes if true" }
  #|      },
  #|      "required": []
  #|    }
  #|  },
  #|  {
  #|    "name": "tree",
  #|    "description": "Show directory tree structure",
  #|    "input_schema": {
  #|      "type": "object",
  #|      "properties": {
  #|        "path": { "type": "string", "description": "Root directory (defaults to current directory)" },
  #|        "depth": { "type": "integer", "description": "Maximum depth (default 3)" },
  #|        "pattern": { "type": "string", "description": "File pattern to filter (e.g. '*.mbt')" }
  #|      },
  #|      "required": []
  #|    }
  #|  },
  #|  {
  #|    "name": "moon_peek_def",
  #|    "description": "Show definition of a MoonBit symbol using moon ide peek-def",
  #|    "input_schema": {
  #|      "type": "object",
  #|      "properties": {
  #|        "symbol": { "type": "string", "description": "Symbol name (e.g. 'fib', 'Type::method')" }
  #|      },
  #|      "required": ["symbol"]
  #|    }
  #|  },
  #|  {
  #|    "name": "moon_outline",
  #|    "description": "List symbols in a MoonBit file using moon ide outline",
  #|    "input_schema": {
  #|      "type": "object",
  #|      "properties": {
  #|        "file": { "type": "string", "description": "File path to analyze (e.g. 'src/lib.mbt')" }
  #|      },
  #|      "required": ["file"]
  #|    }
  #|  },
  #|  {
  #|    "name": "moon_doc",
  #|    "description": "Search MoonBit documentation and standard library using moon doc",
  #|    "input_schema": {
  #|      "type": "object",
  #|      "properties": {
  #|        "query": { "type": "string", "description": "Query string (e.g. 'String', '@json', 'Array::*map*')" }
  #|      },
  #|      "required": ["query"]
  #|    }
  #|  },
  #|  {
  #|    "name": "moon_find_refs",
  #|    "description": "Find all references to a MoonBit symbol using moon ide find-references",
  #|    "input_schema": {
  #|      "type": "object",
  #|      "properties": {
  #|        "symbol": { "type": "string", "description": "Symbol name to find references for" }
  #|      },
  #|      "required": ["symbol"]
  #|    }
  #|  }
  #|]
  json
}

///|
/// Get tool definitions in OpenAI format (for OpenRouter and OpenAI-compatible APIs)
pub fn get_openai_tool_definitions() -> String {
  let json =
    #|[
  #|  {
  #|    "type": "function",
  #|    "function": {
  #|      "name": "read_file",
  #|      "description": "Read the contents of a file at the specified path",
  #|      "parameters": {
  #|        "type": "object",
  #|        "properties": {
  #|          "path": { "type": "string", "description": "The file path to read" }
  #|        },
  #|        "required": ["path"]
  #|      }
  #|    }
  #|  },
  #|  {
  #|    "type": "function",
  #|    "function": {
  #|      "name": "write_file",
  #|      "description": "Write content to a file at the specified path",
  #|      "parameters": {
  #|        "type": "object",
  #|        "properties": {
  #|          "path": { "type": "string", "description": "The file path to write to" },
  #|          "content": { "type": "string", "description": "The content to write" }
  #|        },
  #|        "required": ["path", "content"]
  #|      }
  #|    }
  #|  },
  #|  {
  #|    "type": "function",
  #|    "function": {
  #|      "name": "list_dir",
  #|      "description": "List contents of a directory",
  #|      "parameters": {
  #|        "type": "object",
  #|        "properties": {
  #|          "path": { "type": "string", "description": "The directory path to list (defaults to current directory)" }
  #|        },
  #|        "required": []
  #|      }
  #|    }
  #|  },
  #|  {
  #|    "type": "function",
  #|    "function": {
  #|      "name": "run_command",
  #|      "description": "Run a shell command and return the output",
  #|      "parameters": {
  #|        "type": "object",
  #|        "properties": {
  #|          "command": { "type": "string", "description": "The shell command to execute" }
  #|        },
  #|        "required": ["command"]
  #|      }
  #|    }
  #|  },
  #|  {
  #|    "type": "function",
  #|    "function": {
  #|      "name": "grep_search",
  #|      "description": "Search for a pattern in files using grep",
  #|      "parameters": {
  #|        "type": "object",
  #|        "properties": {
  #|          "pattern": { "type": "string", "description": "The search pattern (regex)" },
  #|          "path": { "type": "string", "description": "Directory to search in (defaults to current directory)" },
  #|          "file_pattern": { "type": "string", "description": "File glob pattern (e.g. '*.mbt')" }
  #|        },
  #|        "required": ["pattern"]
  #|      }
  #|    }
  #|  },
  #|  {
  #|    "type": "function",
  #|    "function": {
  #|      "name": "git_diff",
  #|      "description": "Show git diff for files",
  #|      "parameters": {
  #|        "type": "object",
  #|        "properties": {
  #|          "file": { "type": "string", "description": "Specific file to diff (optional)" },
  #|          "staged": { "type": "boolean", "description": "Show staged changes if true" }
  #|        },
  #|        "required": []
  #|      }
  #|    }
  #|  },
  #|  {
  #|    "type": "function",
  #|    "function": {
  #|      "name": "tree",
  #|      "description": "Show directory tree structure",
  #|      "parameters": {
  #|        "type": "object",
  #|        "properties": {
  #|          "path": { "type": "string", "description": "Root directory (defaults to current directory)" },
  #|          "depth": { "type": "integer", "description": "Maximum depth (default 3)" },
  #|          "pattern": { "type": "string", "description": "File pattern to filter (e.g. '*.mbt')" }
  #|        },
  #|        "required": []
  #|      }
  #|    }
  #|  },
  #|  {
  #|    "type": "function",
  #|    "function": {
  #|      "name": "moon_peek_def",
  #|      "description": "Show definition of a MoonBit symbol using moon ide peek-def",
  #|      "parameters": {
  #|        "type": "object",
  #|        "properties": {
  #|          "symbol": { "type": "string", "description": "Symbol name (e.g. 'fib', 'Type::method')" }
  #|        },
  #|        "required": ["symbol"]
  #|      }
  #|    }
  #|  },
  #|  {
  #|    "type": "function",
  #|    "function": {
  #|      "name": "moon_outline",
  #|      "description": "List symbols in a MoonBit file using moon ide outline",
  #|      "parameters": {
  #|        "type": "object",
  #|        "properties": {
  #|          "file": { "type": "string", "description": "File path to analyze (e.g. 'src/lib.mbt')" }
  #|        },
  #|        "required": ["file"]
  #|      }
  #|    }
  #|  },
  #|  {
  #|    "type": "function",
  #|    "function": {
  #|      "name": "moon_doc",
  #|      "description": "Search MoonBit documentation and standard library using moon doc",
  #|      "parameters": {
  #|        "type": "object",
  #|        "properties": {
  #|          "query": { "type": "string", "description": "Query string (e.g. 'String', '@json', 'Array::*map*')" }
  #|        },
  #|        "required": ["query"]
  #|      }
  #|    }
  #|  },
  #|  {
  #|    "type": "function",
  #|    "function": {
  #|      "name": "moon_find_refs",
  #|      "description": "Find all references to a MoonBit symbol using moon ide find-references",
  #|      "parameters": {
  #|        "type": "object",
  #|        "properties": {
  #|          "symbol": { "type": "string", "description": "Symbol name to find references for" }
  #|        },
  #|        "required": ["symbol"]
  #|      }
  #|    }
  #|  }
  #|]
  json
}

///|
/// Start watching a directory for file changes
/// Calls callback when files are added, changed, or deleted
/// Uses debouncing to avoid excessive callbacks
/// Also watches git index for status changes
pub extern "js" fn js_watch_directory(
  dir : String,
  callback : () -> Unit,
) -> Unit =
  #| (dir, callback) => {
  #|   const fs = require('fs');
  #|   const path = require('path');
  #|   const { execSync } = require('child_process');
  #|
  #|   // Stop any existing watchers
  #|   if (globalThis.__file_watcher) {
  #|     globalThis.__file_watcher.close();
  #|     globalThis.__file_watcher = null;
  #|   }
  #|   if (globalThis.__git_watcher) {
  #|     globalThis.__git_watcher.close();
  #|     globalThis.__git_watcher = null;
  #|   }
  #|
  #|   let debounceTimer = null;
  #|   const DEBOUNCE_MS = 300;
  #|
  #|   const debouncedCallback = () => {
  #|     if (debounceTimer) clearTimeout(debounceTimer);
  #|     debounceTimer = setTimeout(() => {
  #|       callback();
  #|     }, DEBOUNCE_MS);
  #|   };
  #|
  #|   try {
  #|     // Watch current directory for file changes
  #|     globalThis.__file_watcher = fs.watch(dir, { recursive: true }, (eventType, filename) => {
  #|       if (!filename) return;
  #|       // Ignore common non-source files
  #|       if (filename.includes('node_modules') ||
  #|           filename.includes('.git') ||
  #|           filename.includes('_build') ||
  #|           filename.includes('.mooncakes') ||
  #|           filename.endsWith('.swp') ||
  #|           filename.endsWith('~')) {
  #|         return;
  #|       }
  #|       debouncedCallback();
  #|     });
  #|
  #|     // Also watch git index for status changes
  #|     try {
  #|       const gitRoot = execSync('git rev-parse --show-toplevel', { cwd: dir, encoding: 'utf-8', stdio: 'pipe' }).trim();
  #|       const gitIndexPath = path.join(gitRoot, '.git', 'index');
  #|       if (fs.existsSync(gitIndexPath)) {
  #|         globalThis.__git_watcher = fs.watch(gitIndexPath, (eventType) => {
  #|           debouncedCallback();
  #|         });
  #|       }
  #|     } catch (e) {
  #|       // Not in a git repo, ignore
  #|     }
  #|   } catch (e) {
  #|     console.error('Failed to watch directory:', e.message);
  #|   }
  #| }

///|
/// Stop watching directory and git index
pub extern "js" fn js_stop_watch() -> Unit =
  #| () => {
  #|   if (globalThis.__file_watcher) {
  #|     globalThis.__file_watcher.close();
  #|     globalThis.__file_watcher = null;
  #|   }
  #|   if (globalThis.__git_watcher) {
  #|     globalThis.__git_watcher.close();
  #|     globalThis.__git_watcher = null;
  #|   }
  #| }
