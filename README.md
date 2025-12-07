# AI Combinator for Factorio

[![Download Launcher](https://img.shields.io/badge/Download-AI%20Combinator%20Launcher-orange?style=for-the-badge&logo=windows)](https://github.com/galgtonold/ai_combinator/releases/latest)

**A combinator you program with words, not wires.**

The AI Combinator reads signals from red/green wires and outputs signals - just like any other combinator. The difference? You describe what you want in plain English instead of building complex arithmetic/decider logic.

![AI Combinator Interface](images/ai-combinator-ui.png)

## Why Use It?

- **Beginners**: Skip the combinator learning curve. Describe what you want and learn from the generated code.
- **Veterans**: Automate tedious signal processing. Focus on system design, not implementation details.
- **Everyone**: Built-in test cases make your circuits reliable and debuggable.

## What's Included

- **Natural Language Input** - Describe logic in plain English
- **Test Case System** - Define inputs/outputs, validate behavior, auto-fix failures
- **Full Signal Support** - Items, fluids, virtual signals, persistent variables
- **Game Tick Access** - Time-based operations and delays

![AI Code Generation](images/code-generation-demo.gif)

## 🚀 Getting Started

### Requirements
- Factorio 2.0+
- API key from a supported AI provider (OpenAI, Anthropic, Google, xAI, or DeepSeek)

### Installation

1. **[Download the AI Combinator Launcher](https://github.com/galgtonold/ai_combinator/releases/latest)**
   
   ⚠️ The launcher is required - it bridges Factorio to the AI service.

2. **Run the installer** and launch the app

3. **Configure your AI provider:**
   - Select provider and enter your API key
   - Choose a model

4. **Start Factorio through the launcher** - mod installation is automatic

![Launcher Interface](images/launcher-setup.png)

### First Combinator

1. Research **AI Combinator** in the circuit network tech tree
2. Craft and place one, connect it to your circuit network
3. Click to open the interface
4. Describe what you want: *"Output signal A = 1 when iron-plate signal is below 1000"*
5. Click **Generate** and wire the output to your system

![In-Game Usage](images/combinator-placement.gif)

## 🔧 How It Works

The AI Combinator is a standard combinator with one key difference: you describe its behavior in natural language.

**Inputs:**
- Red wire signals
- Green wire signals
- Current game tick

**Outputs:**
- Calculated signals to connected devices
- Optional console messages for debugging

**Persistent State:**
- Variables survive between game ticks
- Useful for counters, timers, and tracking

**Limitations:**
- Cannot directly control entities - only circuit signals
- Cannot read inventories - use circuit-connected sensors
- All interaction happens through the circuit network

## 🧪 Test Cases: Making AI Reliable

AI-generated code can be unpredictable. The test case system solves this by letting you **define expected behavior before generating code**.

### How It Works

1. **Define test cases** with specific input signals and expected outputs
2. **Generate code** - the AI sees your test cases and writes code to pass them
3. **Run tests** - instantly verify the code works correctly
4. **Auto-fix failures** - if tests fail, click "Fix with AI" to regenerate

![Test Case Interface](images/test-cases-ui.png)

### Example: Low Resource Warning

You want a combinator that outputs a warning signal when iron is low:

| Test Case | Red Wire Input | Expected Output |
|-----------|---------------|-----------------|
| Iron OK | iron-plate: 5000 | (nothing) |
| Iron Low | iron-plate: 500 | signal-A: 1 |
| Iron Empty | iron-plate: 0 | signal-A: 1 |

With these test cases defined, the AI generates code that handles all scenarios correctly - and you can verify it instantly.

![Test Case Validation](images/test-case-validation.gif)

### Why This Matters

- **Reproducible results** - same test cases = same behavior
- **Catch edge cases** - define the tricky scenarios upfront
- **Easy iteration** - modify tests, regenerate, verify
- **Documentation** - test cases describe what the combinator does

## 🎮 Example Use Cases

### Low Resource Alert
*"Output signal-A = 1 when iron-plate < 1000 or copper-plate < 1000"*

Wire to a speaker or warning lamp. Combine with other combinators for complex alert systems.

### Production Counter
*"Add all incoming iron-plate signals to a running total, output on signal-I"*

Tracks cumulative production. Wire to a display or use for milestone detection.

### Throughput Calculator
*"Calculate items per minute from the incoming signal, output on signal-T"*

Measures flow rate over time using persistent variables and game tick.

### Priority Switcher
*"Output the signal type with the highest value, set to 1"*

Useful for selecting which resource needs attention most.

### Threshold Gate
*"Pass through all signals only when signal-C > 0"*

Creates a circuit-controlled gate for signal routing.

![Example Circuits](images/example-circuits.png)

## 💡 Prompt Tips

**Be specific about signals:**
```
"Output signal-A = 1 when iron-plate < 1000"
"Sum all input signals, output result on signal-T"
"Pass through copper-plate signal only, ignore everything else"
```

**Time-based operations:**
```
"Toggle signal-A every 60 ticks"
"Output the average of signal-X over the last 60 ticks"
"Only update output once per second (60 ticks)"
```

**Complex logic:**
```
"Output the signal type with the lowest value"
"Count how many different signal types have value > 0"
"Multiply iron-plate by 2 and copper-plate by 3, sum the results"
```

## ⚙️ Technical Details

**Performance:** Heavier than vanilla combinators, but lighter than building equivalent logic manually. For UPS-sensitive builds, update less frequently ("check once per second").

**AI Providers:** OpenAI, Anthropic, Google, xAI, DeepSeek. All paid services - typical usage costs pennies per session.

**Under the hood:** The AI generates Lua code that reads from `red`/`green` tables, stores state in `var`, and writes to `out`. You can view and edit the code directly if needed.

## 🛠️ Troubleshooting

**"No AI Bridge Connection"**
- Launch Factorio through the launcher, not Steam directly
- Check the launcher is running (system tray)
- Verify your API key is valid

**Combinator not responding**
- AI generation takes a few seconds - wait for it
- Check for error messages in the combinator interface
- Try rephrasing your request more specifically

**UPS issues**
- Reduce update frequency in your prompts
- Use fewer AI combinators for complex operations
- Consider combining logic into fewer combinators

**Need help?**
- [Discord Community](https://discord.gg/HYVuqC8kdP)
- [GitHub Issues](https://github.com/galgtonold/ai_combinator/issues)

## 🤝 Contributing

See `DEVELOPMENT.md` for technical details and development setup.

## 📜 License

Based on Moon Logic 2, distributed under the same open-source license.

---

**⭐ Like this mod?** Star us on GitHub and share your builds with the community!