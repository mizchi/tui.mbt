///|
/// AI Client Types

///|
/// Role in conversation
pub(all) enum Role {
  User
  Assistant
}

///|
pub fn Role::to_string(self : Role) -> String {
  match self {
    User => "user"
    Assistant => "assistant"
  }
}

///|
/// Simple message (text only)
pub(all) struct Message {
  role : Role
  content : String
}

///|
/// Tool call from Claude
pub(all) struct ToolCall {
  id : String
  name : String
  input_json : String // JSON string of input parameters
}

///|
/// Tool result to send back
pub(all) struct ToolResult {
  tool_use_id : String
  content : String
  is_error : Bool
}

///|
/// Streaming event from Claude API
pub(all) enum StreamEvent {
  TextDelta(String) // text chunk
  ToolUse(ToolCall) // tool call request
  MessageStop // message finished
  Error(String) // error occurred
}

///|
/// Available tools
pub(all) enum ToolType {
  ReadFile
  WriteFile
  ListDir
  RunCommand
}

///|
pub fn ToolType::name(self : ToolType) -> String {
  match self {
    ReadFile => "read_file"
    WriteFile => "write_file"
    ListDir => "list_dir"
    RunCommand => "run_command"
  }
}

///|
/// Tool definitions for API
pub fn get_tool_definitions() -> String {
  (
    #|[
    #|  {
    #|    "name": "read_file",
    #|    "description": "Read the contents of a file at the specified path",
    #|    "input_schema": {
    #|      "type": "object",
    #|      "properties": {
    #|        "path": {
    #|          "type": "string",
    #|          "description": "The file path to read"
    #|        }
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
    #|        "path": {
    #|          "type": "string",
    #|          "description": "The file path to write to"
    #|        },
    #|        "content": {
    #|          "type": "string",
    #|          "description": "The content to write"
    #|        }
    #|      },
    #|      "required": ["path", "content"]
    #|    }
    #|  },
    #|  {
    #|    "name": "list_dir",
    #|    "description": "List files and directories at the specified path",
    #|    "input_schema": {
    #|      "type": "object",
    #|      "properties": {
    #|        "path": {
    #|          "type": "string",
    #|          "description": "The directory path to list"
    #|        }
    #|      },
    #|      "required": ["path"]
    #|    }
    #|  },
    #|  {
    #|    "name": "run_command",
    #|    "description": "Run a shell command and return its output",
    #|    "input_schema": {
    #|      "type": "object",
    #|      "properties": {
    #|        "command": {
    #|          "type": "string",
    #|          "description": "The shell command to execute"
    #|        }
    #|      },
    #|      "required": ["command"]
    #|    }
    #|  },
    #|  {
    #|    "name": "grep_search",
    #|    "description": "Search for a pattern in files using grep. Returns matching lines with file names and line numbers.",
    #|    "input_schema": {
    #|      "type": "object",
    #|      "properties": {
    #|        "pattern": {
    #|          "type": "string",
    #|          "description": "The regex pattern to search for"
    #|        },
    #|        "path": {
    #|          "type": "string",
    #|          "description": "The directory or file to search in (default: current directory)"
    #|        },
    #|        "file_pattern": {
    #|          "type": "string",
    #|          "description": "File glob pattern to filter (e.g., '*.mbt', '*.js')"
    #|        }
    #|      },
    #|      "required": ["pattern"]
    #|    }
    #|  },
    #|  {
    #|    "name": "git_diff",
    #|    "description": "Show git diff for the repository. Shows uncommitted changes.",
    #|    "input_schema": {
    #|      "type": "object",
    #|      "properties": {
    #|        "file": {
    #|          "type": "string",
    #|          "description": "Specific file to diff (optional, defaults to all changes)"
    #|        },
    #|        "staged": {
    #|          "type": "boolean",
    #|          "description": "Show staged changes only (default: false)"
    #|        }
    #|      },
    #|      "required": []
    #|    }
    #|  },
    #|  {
    #|    "name": "tree",
    #|    "description": "Show directory structure as a tree. Useful for understanding project layout.",
    #|    "input_schema": {
    #|      "type": "object",
    #|      "properties": {
    #|        "path": {
    #|          "type": "string",
    #|          "description": "Root directory to start from (default: current directory)"
    #|        },
    #|        "depth": {
    #|          "type": "integer",
    #|          "description": "Maximum depth to traverse (default: 3)"
    #|        },
    #|        "pattern": {
    #|          "type": "string",
    #|          "description": "File pattern to include (e.g., '*.mbt')"
    #|        }
    #|      },
    #|      "required": []
    #|    }
    #|  },
    #|  {
    #|    "name": "moon_peek_def",
    #|    "description": "Show MoonBit symbol definition with source code. Use for finding function/type implementations.",
    #|    "input_schema": {
    #|      "type": "object",
    #|      "properties": {
    #|        "symbol": {
    #|          "type": "string",
    #|          "description": "Symbol name to look up (e.g., 'StreamingState::append', 'char_width')"
    #|        }
    #|      },
    #|      "required": ["symbol"]
    #|    }
    #|  },
    #|  {
    #|    "name": "moon_outline",
    #|    "description": "List all symbols (functions, types, etc.) in a MoonBit file.",
    #|    "input_schema": {
    #|      "type": "object",
    #|      "properties": {
    #|        "file": {
    #|          "type": "string",
    #|          "description": "Path to the .mbt file to analyze"
    #|        }
    #|      },
    #|      "required": ["file"]
    #|    }
    #|  },
    #|  {
    #|    "name": "moon_doc",
    #|    "description": "Search MoonBit API documentation. Find methods on types or symbols in packages.",
    #|    "input_schema": {
    #|      "type": "object",
    #|      "properties": {
    #|        "query": {
    #|          "type": "string",
    #|          "description": "Search query (e.g., 'String', 'Array', '@json', 'String::*rev*')"
    #|        }
    #|      },
    #|      "required": ["query"]
    #|    }
    #|  }
    #|]
  )
}

///|
/// Claude API configuration
pub(all) struct ClaudeConfig {
  api_key : String
  model : String
  max_tokens : Int
  system_prompt : String
}

///|
pub fn ClaudeConfig::new(
  api_key : String,
  model? : String = "claude-sonnet-4-20250514",
  max_tokens? : Int = 4096,
  system_prompt? : String = "You are a helpful assistant.",
) -> ClaudeConfig {
  { api_key, model, max_tokens, system_prompt }
}
