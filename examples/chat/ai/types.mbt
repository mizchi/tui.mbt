///|
/// AI Client Types and Trait

///|
/// Role in conversation
pub(all) enum Role {
  User
  Assistant
  System
}

///|
pub fn Role::to_string(self : Role) -> String {
  match self {
    User => "user"
    Assistant => "assistant"
    System => "system"
  }
}

///|
/// Simple message (text only)
pub(all) struct Message {
  role : Role
  content : String
}

///|
/// Tool call from AI
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
/// Streaming event from AI API
pub(all) enum StreamEvent {
  TextDelta(String) // text chunk
  ToolUse(ToolCall) // tool call request
  MessageStop // message finished
  Error(String) // error occurred
}

///|
/// AI Provider type
pub(all) enum AIProvider {
  Claude
  OpenRouter
}

///|
pub fn AIProvider::to_string(self : AIProvider) -> String {
  match self {
    Claude => "claude"
    OpenRouter => "openrouter"
  }
}

///|
/// Common AI configuration
pub(all) struct AIConfig {
  api_key : String
  model : String
  max_tokens : Int
  system_prompt : String
  provider : AIProvider
}

///|
pub fn AIConfig::new(
  api_key : String,
  model : String,
  max_tokens? : Int = 4096,
  system_prompt? : String = "You are a helpful assistant.",
  provider? : AIProvider = Claude,
) -> AIConfig {
  { api_key, model, max_tokens, system_prompt, provider }
}

///|
/// AI Client trait - common interface for all providers
pub(open) trait AIClient {
  /// Stream response without tools
  stream(
    Self,
    Array[Message],
    (String) -> Unit,
    () -> Unit,
    (String) -> Unit,
  ) -> Unit
  /// Stream response with tool support
  stream_with_tools(
    Self,
    Array[Message],
    (String) -> Unit,
    (String, String, String) -> String,
    () -> Unit,
    (String) -> Unit,
  ) -> Unit
  /// Get the underlying config
  config(Self) -> AIConfig
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
