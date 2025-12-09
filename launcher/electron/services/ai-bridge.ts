import * as dgram from 'dgram';
import { generateText } from 'ai';
import { createOpenAI } from '@ai-sdk/openai';
import { createAnthropic } from '@ai-sdk/anthropic';
import { createGoogleGenerativeAI } from '@ai-sdk/google';
import { createXai } from '@ai-sdk/xai';
import { createDeepSeek } from '@ai-sdk/deepseek';
import {
  type AIProvider,
  AI_BRIDGE_LISTEN_PORT,
  AI_BRIDGE_RESPONSE_PORT,
  AI_BRIDGE_RESPONSE_HOST,
  DEFAULT_AI_PROVIDER,
  DEFAULT_AI_MODEL,
  createLogger,
  getErrorMessage
} from "../../shared";

const log = createLogger('AIBridge');

// The same prompt used in the Python bridge
const PROMPT = `
You are an expert Factorio Moon Logic combinator AI. Generate executable Lua code satisfying these strict rules:
1. ONLY output raw Lua code (version 5.2) or "ERROR: <brief reason>". NO explanations, markdown, or extra text.
2. Use this environment:
   - Inputs: \`red\`/\`green\` (read-only signal tables, e.g., \`red['iron']\`)
   - Output: \`out\` (write signals, e.g., \`out['signal-A'] = 1\`)
   - Persistence: \`var\` (stores between runs)
   - Timing: \`delay\` (ticks until next run)
   - Available: \`game.tick\`, math/bit32/table functions, game.print() - user Factorio Rich Text format where sensible
3. Forbidden: Function declarations, external libraries, advanced Factorio API
4. Handle ambiguity:
   - Missing signal names → ERROR
   - Unclear logic → ERROR
   - Undefined wire colors → Sum both inputs

DO NOT DECLARE FUNCTIONS EVEN NO LOCAL FUNCTIONS.

Some more things:

* All signals are integer numbers
* The signal name must be a valid Factorio signal name, e.g., 'signal-A', 'iron-ore', 'copper-ore', 'metallic-asteroid-chunk', etc.
* if no name for the output signal is given, the output signal must be 'signal-A'
* only specify the delay if it should not be executed every tick
* Setting a delay of more than 1 means no signals will be processed at all until the delay has elapsed
* Do not use delays when measuring items per second or something siliar that requires per-tick updates
* loops, ifs and calling basic lua functions ARE ALLOWED
* Use code duplication to avoid function declarations if necessary
* if just return something is specified then return that thing as it was provided in the input
* If the user asks to return something, assign that result to out['signal-A']
* if not specified take the signals from both red and green wire inputs
* DO NOT INITIALIZE red, green, out and var, they are already initialized and available to use.
* When you want to use binary notation, use a list of bits instead, e. g {1, 0, 1} instead of 0b101.
* When generating code for music for the programmable speaker using "signal value is pitch", then 1 corresponds to F3, 2 to f#3, 13 to f4 and so on. For durations keep in mind 60 ticks is one second
* Coloured signals follow the naming scheme of signal-red, signal-blue etc
* When printing something to the chat, use Rich Text as much as possible to improve formatting. Don't use utility sprites as they don't work in chat but feel free to use [item=...] etc. [b] tags are not available either, but you can have a [font=default-bold] for example.
* You can only output the signal for a single point in time. For future points in time the code will be called again.

Example valid code:
if (red['iron-ore'] or 0) + (green['iron-ore'] or 0) > 100 then
  out['signal-A'] = 1
  var.triggered = true
  delay = 1
else
  if var.triggered then out['signal-A'] = 0 end
  delay = 60
end

IF YOU TRY TO DECLARE A FUNCTION YOU WILL BE ASKED AGAIN UNTIL YOU PROVIDE A SOLUTION NOT DECLARING A FUNCTION - SO DO NOT DO IT.
FUNCTION DECLARATIONS ARE ALSO ANONYMOUS FUNCTIONS; YOU CANNOT USE THEM DUE TO TECHNICAL LIMITATIONS.

Now process this user request:
`;

const TEST_GENERATION_PROMPT = `
You are an expert Factorio Moon Logic combinator AI. Your task is to generate comprehensive test cases for a given combinator implementation.

CONTEXT:
The Moon Logic combinator runs Lua code in a sandboxed environment with these features:
- Inputs: \`red\`/\`green\` (read-only signal tables, e.g., \`red['iron-ore'] = 50\`)
- Output: \`out\` (write signals, e.g., \`out['signal-A'] = 1\`)
- Persistence: \`var\` (stores values between runs, e.g., \`var.counter = 5\`)
- Timing: \`delay\` (ticks until next run, e.g., \`delay = 60\` means run again in 1 second)
- Available: \`game.tick\`, math/bit32/table functions, game.print() with Factorio Rich Text
- All signals are integer numbers
- Signal names: 'signal-A' through 'signal-Z', 'iron-ore', 'copper-ore', etc.

TESTING SYSTEM:
Test cases evaluate the code by providing input signals and comparing expected vs actual outputs.
Each test case can specify:
- red_input: Array of {signal: "signal-name", count: number}
- green_input: Array of {signal: "signal-name", count: number}  
- expected_output: Array of {signal: "signal-name", count: number}
- variables: Array of {name: "var_name", value: number} for pre-setting var.name
- game_tick: Number (optional, defaults to 1)
- expected_print: String (optional, for testing game.print output)

OUTPUT FORMAT:
Generate ONLY a JSON array of test case objects. NO explanations, markdown, or extra text.

Example format:
[
  {
    "name": "Basic threshold test",
    "red_input": [{"signal": "iron-ore", "count": 150}],
    "green_input": [],
    "expected_output": [{"signal": "signal-A", "count": 1}],
    "variables": [],
    "game_tick": 1
  },
  {
    "name": "Below threshold test", 
    "red_input": [{"signal": "iron-ore", "count": 50}],
    "green_input": [],
    "expected_output": [],
    "variables": [],
    "game_tick": 1
  }
]

REQUIREMENTS:
1. Generate 3-8 test cases based on code complexity
2. Cover edge cases: zero values, boundary conditions, state transitions
3. Test different input combinations (red vs green wires)
4. Test persistence with var if used in code
5. Test timing with different game_tick values if delay is used
6. Test print output if game.print is used
7. Use realistic Factorio signal names
8. Ensure test names are descriptive

TASK DESCRIPTION: {task_description}

SOURCE CODE TO TEST:
{source_code}

Generate comprehensive test cases for this implementation:
`;

export class AIBridge {
  private listenPort: number;
  private responsePort: number;
  private responseHost: string;
  private apiKey: string;
  private provider: AIProvider;
  private model: string;
  private listenSocket: dgram.Socket;
  private responseSocket: dgram.Socket;
  private isRunning: boolean = false;

  constructor(
    apiKey: string,
    provider: AIProvider = DEFAULT_AI_PROVIDER,
    model: string = DEFAULT_AI_MODEL,
    listenPort: number = AI_BRIDGE_LISTEN_PORT,
    responsePort: number = AI_BRIDGE_RESPONSE_PORT,
    responseHost: string = AI_BRIDGE_RESPONSE_HOST
  ) {
    this.apiKey = apiKey;
    this.provider = provider;
    this.model = model;
    this.listenPort = listenPort;
    this.responsePort = responsePort;
    this.responseHost = responseHost;
    
    // Create UDP sockets
    this.listenSocket = dgram.createSocket('udp4');
    this.responseSocket = dgram.createSocket('udp4');
    
    // Set up message handler
    this.listenSocket.on('message', this.handleMessage.bind(this));
    
    // Set up error handler
    this.listenSocket.on('error', (err) => {
      log.error(`UDP Server error: ${err.stack}`);
      this.listenSocket.close();
    });
  }

  private getAIProvider() {
    switch (this.provider) {
      case 'openai':
        return createOpenAI({ apiKey: this.apiKey });
      case 'anthropic':
        return createAnthropic({ apiKey: this.apiKey });
      case 'google':
        return createGoogleGenerativeAI({ apiKey: this.apiKey });
      case 'xai':
        return createXai({ apiKey: this.apiKey });
      case 'deepseek':
        return createDeepSeek({ apiKey: this.apiKey });
      default:
        throw new Error(`Unsupported AI provider: ${this.provider}`);
    }
  }

  private async callAI(userMessage: string): Promise<string> {
    try {
      // Build the prompt
      const prompt = `${PROMPT} ${userMessage}`;
      
      log.info(`Calling ${this.provider} API with model ${this.model}...`);
      const startTime = Date.now();
      
      // Get the appropriate provider
      const provider = this.getAIProvider();
      
      // Make API call using the generateText function
      const { text } = await generateText({
        model: provider(this.model),
        prompt: prompt,
        temperature: 0
      });
      
      const endTime = Date.now();
      log.info(`AI Response (took ${(endTime - startTime) / 1000}s)`);
      log.debug(text);
      
      return text;
    } catch (error) {
      log.error('AI API Error:', getErrorMessage(error));
      return `ERROR: ${getErrorMessage(error)}`;
    }
  }

  private async callAIForTestGeneration(prompt: string): Promise<string> {
    try {
      log.info(`Calling ${this.provider} API for test generation with model ${this.model}...`);
      const startTime = Date.now();
      
      // Get the appropriate provider
      const provider = this.getAIProvider();
      
      // Make API call using the generateText function
      const { text } = await generateText({
        model: provider(this.model),
        prompt: prompt,
        temperature: 0.3 // Slightly higher temperature for more diverse test cases
      });
      
      const endTime = Date.now();
      log.info(`AI Test Generation Response (took ${(endTime - startTime) / 1000}s)`);
      
      return text;
    } catch (error) {
      log.error('AI API Error during test generation:', getErrorMessage(error));
      return `ERROR: ${getErrorMessage(error)}`;
    }
  }

  private sendResponse(message: string | object): void {
    let messageStr: string;
    if (typeof message === 'object') {
      messageStr = JSON.stringify(message);
    } else {
      messageStr = message;
    }

    try {
      this.responseSocket.send(
        Buffer.from(messageStr, 'utf-8'),
        this.responsePort,
        this.responseHost,
        (err) => {
          if (err) {
            log.error('Error sending response:', getErrorMessage(err));
          } else {
            log.debug(`Response sent to ${this.responseHost}:${this.responsePort}`);
          }
        }
      );
    } catch (error) {
      log.error('Error sending response:', getErrorMessage(error));
    }
  }

  private async handleMessage(msg: Buffer, rinfo: dgram.RemoteInfo): Promise<void> {
    const message = msg.toString('utf-8');
    log.debug(`Received message from ${rinfo.address}:${rinfo.port}: ${message}`);
    try {
      const payload = JSON.parse(message) as {
        type?: string;
        uid?: number;
        task_text?: string;
        task_description?: string;
        source_code?: string;
        correlation_id?: number;
      };

      if (!payload.type) {
        log.error('Invalid message format. "type" field is missing.');
        return;
      }
      
      if (payload.type === 'task_request') {
        await this.handleTaskRequest(payload.uid ?? 0, payload.task_text ?? '', payload.correlation_id);
      } else if (payload.type === 'fix_request') {
        await this.handleFixRequest(payload.uid ?? 0, payload.task_text ?? '', payload.correlation_id);
      } else if (payload.type === 'test_generation_request') {
        await this.handleTestGenerationRequest(payload.uid ?? 0, payload.task_description ?? '', payload.source_code ?? '', payload.correlation_id);
      } else if (payload.type === 'ping_request') {
        this.handlePingRequest(payload.uid ?? 0);
      }
    } catch (error) {
      log.error('Error processing message:', getErrorMessage(error));
    }
  }

  private async handleTaskRequest(uid: number, taskText: string, correlationId?: number): Promise<void> {
    log.info('Handling task request:', taskText);
    this.sendResponse({
      type: 'task_request_completed',
      uid: uid,
      correlation_id: correlationId,
      response: await this.callAI(taskText)
    });
  }

  private async handleFixRequest(uid: number, taskText: string, correlationId?: number): Promise<void> {
    log.info('Handling fix request:', taskText);
    this.sendResponse({
      type: 'fix_completed',
      uid: uid,
      correlation_id: correlationId,
      response: await this.callAI(taskText)
    });
  }  

  private async handleTestGenerationRequest(uid: number, taskDescription: string, sourceCode: string, correlationId?: number): Promise<void> {
    log.info('Handling test generation request for task:', taskDescription);
    
    // Build the test generation prompt
    const prompt = TEST_GENERATION_PROMPT
      .replace('{task_description}', taskDescription || 'No task description provided')
      .replace('{source_code}', sourceCode || 'No source code provided');
    
    // Call AI API for test generation
    const startTime = Date.now();
    const apiResponse = await this.callAIForTestGeneration(prompt);
    const endTime = Date.now();
    
    log.info(`AI Test Generation Response (took ${(endTime - startTime) / 1000}s)`);
    log.debug(apiResponse);
    
    // Send response back via UDP
    this.sendResponse({
      type: 'test_generation_completed',
      uid: uid,
      correlation_id: correlationId,
      test_cases: apiResponse
    });
  }

  private handlePingRequest(uid: number): void {
    log.debug('Handling ping request');
    
    // Send ping response back via UDP
    this.sendResponse({
      type: 'ping_response',
      uid: uid,
      timestamp: Date.now(),
      status: 'ok'
    });
  }

  public start(): void {
    if (this.isRunning) {
      log.warn('AI Bridge is already running');
      return;
    }
    
    if (!this.apiKey) {
      log.error('ERROR: API key not provided!');
      return;
    }
    
    try {
      // Bind the listen socket to the specified port
      this.listenSocket.bind(this.listenPort, () => {
        log.info(`UDP AI Bridge started on port ${this.listenPort}`);
        log.info(`Responses will be sent to ${this.responseHost}:${this.responsePort}`);
        log.info(`Using model: ${this.model}`);
        this.isRunning = true;
      });
    } catch (error) {
      log.error('Failed to start AI Bridge:', getErrorMessage(error));
    }
  }

  public stop(): void {
    if (!this.isRunning) {
      log.debug('AI Bridge is not running');
      return;
    }
    
    try {
      this.listenSocket.close(() => {
        log.info('UDP AI Bridge stopped');
        this.isRunning = false;
      });
      this.responseSocket.close();
    } catch (error) {
      log.error('Error stopping AI Bridge:', getErrorMessage(error));
    }
  }

  public isActive(): boolean {
    return this.isRunning;
  }

  public updateApiKey(apiKey: string): void {
    this.apiKey = apiKey;
  }

  public updateModel(model: string): void {
    this.model = model;
  }

  public sendPing(uid: number = 0): void {
    if (!this.isRunning) {
      log.warn('Cannot send ping: AI Bridge is not running');
      return;
    }
    
    const pingMessage = {
      type: 'ping_request',
      uid: uid,
      timestamp: Date.now()
    };
    
    this.sendResponse(pingMessage);
    log.debug('Ping request sent');
  }
}
