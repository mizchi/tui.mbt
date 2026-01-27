///|
/// OpenRouter API Adapter (OpenAI-compatible)

///|
/// Internal: Start streaming request to OpenRouter API (without tools)
extern "js" fn js_openrouter_stream(
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
  #|     // Add system message at the beginning
  #|     const allMessages = [
  #|       { role: 'system', content: systemPrompt },
  #|       ...messages
  #|     ];
  #|     const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
  #|       method: 'POST',
  #|       headers: {
  #|         'Content-Type': 'application/json',
  #|         'Authorization': `Bearer ${apiKey}`,
  #|         'HTTP-Referer': 'https://github.com/mizchi/tui.mbt',
  #|         'X-Title': 'tui.mbt chat',
  #|       },
  #|       body: JSON.stringify({
  #|         model: model,
  #|         max_tokens: maxTokens,
  #|         messages: allMessages,
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
  #|             const delta = event.choices?.[0]?.delta?.content;
  #|             if (delta) {
  #|               onChunk(delta);
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
/// Internal: Streaming with tool support (OpenAI format)
extern "js" fn js_openrouter_stream_with_tools(
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
  #|     // Add system message at the beginning
  #|     messages = [
  #|       { role: 'system', content: systemPrompt },
  #|       ...messages
  #|     ];
  #|
  #|     // Tool use loop
  #|     while (true) {
  #|       const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
  #|         method: 'POST',
  #|         headers: {
  #|           'Content-Type': 'application/json',
  #|           'Authorization': `Bearer ${apiKey}`,
  #|           'HTTP-Referer': 'https://github.com/mizchi/tui.mbt',
  #|           'X-Title': 'tui.mbt chat',
  #|         },
  #|         body: JSON.stringify({
  #|           model: model,
  #|           max_tokens: maxTokens,
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
  #|       let finishReason = null;
  #|       let toolCalls = [];
  #|       let currentToolCall = null;
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
  #|             const choice = event.choices?.[0];
  #|             if (!choice) continue;
  #|
  #|             // Handle text content
  #|             if (choice.delta?.content) {
  #|               onChunk(choice.delta.content);
  #|             }
  #|
  #|             // Handle tool calls (OpenAI format)
  #|             if (choice.delta?.tool_calls) {
  #|               for (const tc of choice.delta.tool_calls) {
  #|                 const idx = tc.index ?? 0;
  #|                 if (!toolCalls[idx]) {
  #|                   toolCalls[idx] = { id: '', name: '', arguments: '' };
  #|                 }
  #|                 if (tc.id) toolCalls[idx].id = tc.id;
  #|                 if (tc.function?.name) {
  #|                   toolCalls[idx].name = tc.function.name;
  #|                   onChunk('\n[Calling ' + tc.function.name + '...]\n');
  #|                 }
  #|                 if (tc.function?.arguments) {
  #|                   toolCalls[idx].arguments += tc.function.arguments;
  #|                 }
  #|               }
  #|             }
  #|
  #|             if (choice.finish_reason) {
  #|               finishReason = choice.finish_reason;
  #|             }
  #|           } catch (e) {}
  #|         }
  #|       }
  #|
  #|       // If no tool calls, we're done
  #|       if (finishReason !== 'tool_calls' || toolCalls.length === 0) {
  #|         break;
  #|       }
  #|
  #|       // Execute tools and add results
  #|       messages.push({
  #|         role: 'assistant',
  #|         content: null,
  #|         tool_calls: toolCalls.map((tc, i) => ({
  #|           id: tc.id || `call_${i}`,
  #|           type: 'function',
  #|           function: { name: tc.name, arguments: tc.arguments }
  #|         }))
  #|       });
  #|
  #|       for (const tc of toolCalls) {
  #|         const result = onToolCall(tc.id || 'call_0', tc.name, tc.arguments);
  #|         messages.push({
  #|           role: 'tool',
  #|           tool_call_id: tc.id || 'call_0',
  #|           content: result
  #|         });
  #|         onChunk('\n[Result: ' + result.substring(0, 100) + (result.length > 100 ? '...' : '') + ']\n\n');
  #|       }
  #|       toolCalls = [];
  #|     }
  #|
  #|     onComplete();
  #|   } catch (e) {
  #|     onError(e.message || String(e));
  #|   }
  #| }

///|
/// OpenRouter API Client
pub(all) struct OpenRouterClient {
  ai_config : AIConfig
}

///|
pub fn OpenRouterClient::new(config : AIConfig) -> OpenRouterClient {
  { ai_config: config }
}

///|
/// Create client from environment variable OPENROUTER_API_KEY
pub fn OpenRouterClient::from_env(
  model? : String = "anthropic/claude-3.5-sonnet",
  max_tokens? : Int = 4096,
  system_prompt? : String = "You are a helpful assistant.",
) -> OpenRouterClient? {
  let api_key = @io.get_env("OPENROUTER_API_KEY")
  if api_key.length() == 0 {
    None
  } else {
    Some(
      OpenRouterClient::new(
        AIConfig::new(
          api_key,
          model,
          max_tokens~,
          system_prompt~,
          provider=OpenRouter,
        ),
      ),
    )
  }
}

///|
/// Implement AIClient trait for OpenRouterClient
pub impl AIClient for OpenRouterClient with stream(
  self,
  messages,
  on_chunk,
  on_complete,
  on_error,
) {
  let json = messages_to_json(messages)
  js_openrouter_stream(
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
pub impl AIClient for OpenRouterClient with stream_with_tools(
  self,
  messages,
  on_chunk,
  on_tool_call,
  on_complete,
  on_error,
) {
  let messages_json = messages_to_json(messages)
  let tools_json = get_openai_tool_definitions()
  js_openrouter_stream_with_tools(
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
pub impl AIClient for OpenRouterClient with config(self) {
  self.ai_config
}
