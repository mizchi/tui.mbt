///|
/// Claude API Client with Streaming and Tool Support (JS target only)

///|
/// Internal: Start streaming request to Claude API (without tools)
extern "js" fn js_claude_stream(
  api_key : String,
  model : String,
  max_tokens : Int,
  system_prompt : String,
  messages_json : String,
  on_chunk : (String) -> Unit,
  on_complete : () -> Unit,
  on_error : (String) -> Unit,
) -> Unit =
  #| async (apiKey, model, maxTokens, systemPrompt, messagesJson, onChunk, onComplete, onError) => {
  #|   try {
  #|     const messages = JSON.parse(messagesJson);
  #|     const response = await fetch('https://api.anthropic.com/v1/messages', {
  #|       method: 'POST',
  #|       headers: {
  #|         'Content-Type': 'application/json',
  #|         'x-api-key': apiKey,
  #|         'anthropic-version': '2023-06-01',
  #|       },
  #|       body: JSON.stringify({
  #|         model: model,
  #|         max_tokens: maxTokens,
  #|         system: systemPrompt,
  #|         messages: messages,
  #|         stream: true,
  #|       }),
  #|     });
  #|     if (!response.ok) {
  #|       const errorText = await response.text();
  #|       onError(`HTTP ${response.status}: ${errorText}`);
  #|       return;
  #|     }
  #|     const reader = response.body.getReader();
  #|     const decoder = new TextDecoder();
  #|     let buffer = '';
  #|     while (true) {
  #|       const { done, value } = await reader.read();
  #|       if (done) break;
  #|       buffer += decoder.decode(value, { stream: true });
  #|       const lines = buffer.split('\n');
  #|       buffer = lines.pop() || '';
  #|       for (const line of lines) {
  #|         if (line.startsWith('data: ')) {
  #|           const data = line.slice(6);
  #|           if (data === '[DONE]') continue;
  #|           try {
  #|             const event = JSON.parse(data);
  #|             if (event.type === 'content_block_delta' && event.delta?.text) {
  #|               onChunk(event.delta.text);
  #|             }
  #|           } catch (e) {}
  #|         }
  #|       }
  #|     }
  #|     onComplete();
  #|   } catch (e) {
  #|     onError(e.message || String(e));
  #|   }
  #| }

///|
/// Internal: Streaming with tool support
/// on_tool_call receives (tool_id, tool_name, input_json) and must return result string
extern "js" fn js_claude_stream_with_tools(
  api_key : String,
  model : String,
  max_tokens : Int,
  system_prompt : String,
  messages_json : String,
  tools_json : String,
  on_chunk : (String) -> Unit,
  on_tool_call : (String, String, String) -> String,
  on_complete : () -> Unit,
  on_error : (String) -> Unit,
) -> Unit =
  #| async (apiKey, model, maxTokens, systemPrompt, messagesJson, toolsJson, onChunk, onToolCall, onComplete, onError) => {
  #|   try {
  #|     let messages = JSON.parse(messagesJson);
  #|     const tools = JSON.parse(toolsJson);
  #|
  #|     // Tool use loop
  #|     while (true) {
  #|       const response = await fetch('https://api.anthropic.com/v1/messages', {
  #|         method: 'POST',
  #|         headers: {
  #|           'Content-Type': 'application/json',
  #|           'x-api-key': apiKey,
  #|           'anthropic-version': '2023-06-01',
  #|         },
  #|         body: JSON.stringify({
  #|           model: model,
  #|           max_tokens: maxTokens,
  #|           system: systemPrompt,
  #|           messages: messages,
  #|           tools: tools,
  #|           stream: true,
  #|         }),
  #|       });
  #|
  #|       if (!response.ok) {
  #|         const errorText = await response.text();
  #|         onError(`HTTP ${response.status}: ${errorText}`);
  #|         return;
  #|       }
  #|
  #|       const reader = response.body.getReader();
  #|       const decoder = new TextDecoder();
  #|       let buffer = '';
  #|       let stopReason = null;
  #|       let currentToolUse = null;
  #|       let toolUses = [];
  #|       let assistantContent = [];
  #|
  #|       while (true) {
  #|         const { done, value } = await reader.read();
  #|         if (done) break;
  #|         buffer += decoder.decode(value, { stream: true });
  #|         const lines = buffer.split('\n');
  #|         buffer = lines.pop() || '';
  #|
  #|         for (const line of lines) {
  #|           if (!line.startsWith('data: ')) continue;
  #|           const data = line.slice(6);
  #|           if (data === '[DONE]') continue;
  #|
  #|           try {
  #|             const event = JSON.parse(data);
  #|
  #|             if (event.type === 'content_block_start') {
  #|               if (event.content_block?.type === 'tool_use') {
  #|                 currentToolUse = {
  #|                   id: event.content_block.id,
  #|                   name: event.content_block.name,
  #|                   input: ''
  #|                 };
  #|                 onChunk('\n[Calling ' + event.content_block.name + '...]\n');
  #|               }
  #|             } else if (event.type === 'content_block_delta') {
  #|               if (event.delta?.text) {
  #|                 onChunk(event.delta.text);
  #|               } else if (event.delta?.partial_json && currentToolUse) {
  #|                 currentToolUse.input += event.delta.partial_json;
  #|               }
  #|             } else if (event.type === 'content_block_stop') {
  #|               if (currentToolUse) {
  #|                 toolUses.push(currentToolUse);
  #|                 assistantContent.push({
  #|                   type: 'tool_use',
  #|                   id: currentToolUse.id,
  #|                   name: currentToolUse.name,
  #|                   input: JSON.parse(currentToolUse.input || '{}')
  #|                 });
  #|                 currentToolUse = null;
  #|               }
  #|             } else if (event.type === 'message_delta') {
  #|               stopReason = event.delta?.stop_reason;
  #|             }
  #|           } catch (e) {}
  #|         }
  #|       }
  #|
  #|       // If no tool use, we're done
  #|       if (stopReason !== 'tool_use' || toolUses.length === 0) {
  #|         break;
  #|       }
  #|
  #|       // Execute tools and add results
  #|       messages.push({ role: 'assistant', content: assistantContent });
  #|
  #|       const toolResults = [];
  #|       for (const tool of toolUses) {
  #|         const result = onToolCall(tool.id, tool.name, tool.input);
  #|         toolResults.push({
  #|           type: 'tool_result',
  #|           tool_use_id: tool.id,
  #|           content: result
  #|         });
  #|         onChunk('\n[Result: ' + result.substring(0, 100) + (result.length > 100 ? '...' : '') + ']\n\n');
  #|       }
  #|
  #|       messages.push({ role: 'user', content: toolResults });
  #|     }
  #|
  #|     onComplete();
  #|   } catch (e) {
  #|     onError(e.message || String(e));
  #|   }
  #| }

///|
/// Convert messages to JSON string for API call
fn messages_to_json(messages : Array[Message]) -> String {
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
fn escape_json_string(s : String) -> String {
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
/// Claude API Client
pub(all) struct ClaudeClient {
  config : ClaudeConfig
}

///|
pub fn ClaudeClient::new(config : ClaudeConfig) -> ClaudeClient {
  { config, }
}

///|
/// Create client from environment variable ANTHROPIC_API_KEY
pub fn ClaudeClient::from_env(
  model? : String = "claude-sonnet-4-20250514",
  max_tokens? : Int = 4096,
  system_prompt? : String = "You are a helpful assistant.",
) -> ClaudeClient? {
  let api_key = @io.get_env("ANTHROPIC_API_KEY")
  if api_key.length() == 0 {
    None
  } else {
    Some(
      ClaudeClient::new(
        ClaudeConfig::new(api_key, model~, max_tokens~, system_prompt~),
      ),
    )
  }
}

///|
/// Send messages and stream response (without tools)
pub fn ClaudeClient::stream(
  self : ClaudeClient,
  messages : Array[Message],
  on_chunk : (String) -> Unit,
  on_complete : () -> Unit,
  on_error : (String) -> Unit,
) -> Unit {
  let json = messages_to_json(messages)
  js_claude_stream(
    self.config.api_key,
    self.config.model,
    self.config.max_tokens,
    self.config.system_prompt,
    json,
    on_chunk,
    on_complete,
    on_error,
  )
}

///|
/// Send messages with tool support
/// on_tool_call receives (tool_id, tool_name, input_json) and must return result
pub fn ClaudeClient::stream_with_tools(
  self : ClaudeClient,
  messages : Array[Message],
  on_chunk : (String) -> Unit,
  on_tool_call : (String, String, String) -> String,
  on_complete : () -> Unit,
  on_error : (String) -> Unit,
) -> Unit {
  let messages_json = messages_to_json(messages)
  let tools_json = get_tool_definitions()
  js_claude_stream_with_tools(
    self.config.api_key,
    self.config.model,
    self.config.max_tokens,
    self.config.system_prompt,
    messages_json,
    tools_json,
    on_chunk,
    on_tool_call,
    on_complete,
    on_error,
  )
}
