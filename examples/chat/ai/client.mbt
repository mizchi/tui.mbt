///|
/// AI Client Factory and Utilities

///|
/// Convert messages to JSON string for API call
pub fn messages_to_json(messages : Array[Message]) -> String {
  let parts : Array[String] = []
  for msg in messages {
    let role = msg.role.to_string()
    let content = escape_json_string(msg.content)
    parts.push("{\"role\":\"" + role + "\",\"content\":\"" + content + "\"}")
  }
  "[" +
  parts
  .iter()
  .fold(init="", fn(acc, s) {
    if acc.length() == 0 {
      s
    } else {
      acc + "," + s
    }
  }) +
  "]"
}

///|
/// Escape string for JSON
pub fn escape_json_string(s : String) -> String {
  let mut result = ""
  for c in s {
    match c {
      '"' => result = result + "\\\""
      '\\' => result = result + "\\\\"
      '\n' => result = result + "\\n"
      '\r' => result = result + "\\r"
      '\t' => result = result + "\\t"
      _ => result = result + c.to_string()
    }
  }
  result
}

///|
/// Boxed AI Client for dynamic dispatch
pub(all) struct BoxedAIClient {
  inner : &AIClient
}

///|
pub fn BoxedAIClient::stream(
  self : BoxedAIClient,
  messages : Array[Message],
  on_chunk : (String) -> Unit,
  on_complete : () -> Unit,
  on_error : (String) -> Unit,
) -> Unit {
  self.inner.stream(messages, on_chunk, on_complete, on_error)
}

///|
pub fn BoxedAIClient::stream_with_tools(
  self : BoxedAIClient,
  messages : Array[Message],
  on_chunk : (String) -> Unit,
  on_tool_call : (String, String, String) -> String,
  on_complete : () -> Unit,
  on_error : (String) -> Unit,
) -> Unit {
  self.inner.stream_with_tools(
    messages,
    on_chunk,
    on_tool_call,
    on_complete,
    on_error,
  )
}

///|
pub fn BoxedAIClient::config(self : BoxedAIClient) -> AIConfig {
  self.inner.config()
}

///|
/// Create AI client from environment variables
/// Priority: ANTHROPIC_API_KEY > OPENROUTER_API_KEY
pub fn create_client_from_env(
  system_prompt? : String = "You are a helpful assistant.",
  max_tokens? : Int = 4096,
) -> BoxedAIClient? {
  // Try Claude first
  let anthropic_key = @io.get_env("ANTHROPIC_API_KEY")
  if anthropic_key.length() > 0 {
    let model = @io.get_env("ANTHROPIC_MODEL")
    let model = if model.length() > 0 {
      model
    } else {
      "claude-sonnet-4-20250514"
    }
    let client = ClaudeClient::new(
      AIConfig::new(
        anthropic_key,
        model,
        max_tokens~,
        system_prompt~,
        provider=Claude,
      ),
    )
    return Some({ inner: client })
  }

  // Try OpenRouter
  let openrouter_key = @io.get_env("OPENROUTER_API_KEY")
  if openrouter_key.length() > 0 {
    let model = @io.get_env("OPENROUTER_MODEL")
    let model = if model.length() > 0 {
      model
    } else {
      "anthropic/claude-3.5-sonnet"
    }
    let client = OpenRouterClient::new(
      AIConfig::new(
        openrouter_key,
        model,
        max_tokens~,
        system_prompt~,
        provider=OpenRouter,
      ),
    )
    return Some({ inner: client })
  }

  None
}

///|
/// Get provider name from boxed client
pub fn BoxedAIClient::provider_name(self : BoxedAIClient) -> String {
  self.config().provider.to_string()
}

///|
/// Get model name from boxed client
pub fn BoxedAIClient::model_name(self : BoxedAIClient) -> String {
  self.config().model
}
