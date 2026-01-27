///|
/// Claude API Adapter (Anthropic)

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
/// Claude API Client
pub(all) struct ClaudeClient {
  ai_config : AIConfig
}

///|
pub fn ClaudeClient::new(config : AIConfig) -> ClaudeClient {
  { ai_config: config }
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
        AIConfig::new(api_key, model, max_tokens~, system_prompt~, provider=Claude),
      ),
    )
  }
}

///|
/// Implement AIClient trait for ClaudeClient
pub impl AIClient for ClaudeClient with stream(
  self,
  messages,
  on_chunk,
  on_complete,
  on_error,
) {
  let json = messages_to_json(messages)
  js_claude_stream(
    self.ai_config.api_key,
    self.ai_config.model,
    self.ai_config.max_tokens,
    self.ai_config.system_prompt,
    json,
    on_chunk,
    on_complete,
    on_error,
  )
}

///|
pub impl AIClient for ClaudeClient with stream_with_tools(
  self,
  messages,
  on_chunk,
  on_tool_call,
  on_complete,
  on_error,
) {
  let messages_json = messages_to_json(messages)
  let tools_json = get_claude_tool_definitions()
  js_claude_stream_with_tools(
    self.ai_config.api_key,
    self.ai_config.model,
    self.ai_config.max_tokens,
    self.ai_config.system_prompt,
    messages_json,
    tools_json,
    on_chunk,
    on_tool_call,
    on_complete,
    on_error,
  )
}

///|
pub impl AIClient for ClaudeClient with config(self) {
  self.ai_config
}
