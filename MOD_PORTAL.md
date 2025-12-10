# AI Combinator

**A combinator you program with words, not wires.**

The AI Combinator reads signals from red/green wires and outputs signals - just like any other combinator. The difference? You describe what you want in plain English instead of building complex arithmetic/decider logic.

<img width="570" height="590" alt="image" src="https://github.com/user-attachments/assets/64cc46a5-f045-43d1-95a9-734cbc538f0f" />

---

## Why Use It?

- **Beginners**: Skip the combinator learning curve. Describe what you want and learn from the generated code.
- **Veterans**: Automate tedious signal processing. Focus on system design, not implementation details.
- **Everyone**: Built-in test cases make your circuits reliable and debuggable.

---

## Features

- **Natural Language Input** - Describe logic in plain English
- **Test Case System** - Define inputs/outputs, validate behavior, auto-fix failures
- **Full Signal Support** - Items, fluids, virtual signals, persistent variables
- **Game Tick Access** - Time-based operations and delays


---

## 🚀 Getting Started

### Requirements
- Factorio 2.0+
- API key from a supported AI provider (OpenAI, Anthropic, Google, xAI, or DeepSeek)
- **[AI Combinator Launcher](https://github.com/galgtonold/ai_combinator/)** (required - bridges Factorio to the AI service)

### Installation

1. **[Download the AI Combinator Launcher](https://github.com/galgtonold/ai_combinator/)**
2. **Run the installer** and launch the app
3. **Configure your AI provider:** Select provider and enter your API key
4. **Start Factorio through the launcher** and activate the mod

<img width="770" height="730" alt="image" src="https://github.com/user-attachments/assets/901fa091-d7f4-4c14-b109-707b0b811b5a" />

### First Combinator

1. Research **AI Combinator** in the circuit network tech tree
2. Craft and place one, connect it to your circuit network
3. Click to open the interface
4. Describe what you want: *"Output signal A = 1 when at least 3 input signals are below 1000"*
5. Click **Generate** and wire the output to your system


---

## How It Works

The AI Combinator is a standard combinator with one key difference: you describe its behavior in natural language.

**Inputs:**
- Red wire signals
- Green wire signals
- Current game tick

**Outputs:**
- Calculated signals to connected devices
- Optional console messages for player communication

**Persistent State:**
- Variables survive between game ticks
- Useful for counters, timers, and tracking

**Limitations:**
- Cannot directly control entities - only circuit signals
- Cannot read inventories
- All interaction happens through the circuit network

---

## 🧪 Test Cases: Making AI Reliable

AI-generated code can be unpredictable. The test case system solves this by letting you **define expected behavior before generating code**.

1. **Define test cases** with specific input signals and expected outputs - or autogenerate baseline test cases using AI
2. **Run tests** - instantly verify the code works correctly
3. **Auto-fix failures** - if tests fail, click "Fix with AI" to regenerate

<img width="559" height="607" alt="image" src="https://github.com/user-attachments/assets/5f9ddaff-316a-4687-9b5d-d2d80e12f562" />

**Why This Matters:**
- **Reproducible results** - same test cases = same behavior
- **Catch edge cases** - define the tricky scenarios upfront
- **Easy iteration** - modify tests, regenerate, verify
- **Documentation** - test cases describe what the combinator does

---

## 🎮 Example Use Cases

### Low Resource Alert
*"Output signal-A = 1 when iron-plate < 1000 or copper-plate < 1000"*

Wire to a speaker or warning lamp.

### Production Counter
*"Add all incoming iron-plate signals to a running total, output on signal-I"*

Tracks cumulative production. Wire to a display or use for milestone detection.

### Throughput Calculator
*"Calculate items per minute (measured over 5 seconds) from the iron plate signal, output on signal-T"*

Measures flow rate over time using persistent variables and game tick.

### Priority Switcher
*"Output the signal type with the highest value, set to 1"*

Useful for selecting which resource needs attention most.

---

## 💡 Prompt Tips

**Be specific about signals:**
- "Output signal-A = 1 when iron-plate < 1000"
- "Sum all input signals, output result on signal-T"
- "Pass through copper-plate signal only, ignore everything else"

**Time-based operations:**
- "Toggle signal-A every 60 ticks"
- "Output the average of signal-X over the last 60 ticks"
- "Only update output once per second (60 ticks)"

**Complex logic:**
- "Output the signal type with the lowest value"
- "Count how many different signal types have value > 0"
- "Multiply iron-plate by 2 and copper-plate by 3, sum the results"

---

## ⚙️ Technical Details

**Performance:** Heavier than vanilla combinators, but lighter than building equivalent logic manually. For UPS-sensitive builds, update less frequently ("check once per second").

**AI Providers:** OpenAI, Anthropic, Google, xAI, DeepSeek. All paid services - typical usage costs pennies per session.

**Under the hood:** The AI generates Lua code that reads from `red`/`green` tables, stores state in `var`, and writes to `out`. You can view and edit the code directly if needed.

---

## 🛠️ Troubleshooting

**"No AI Bridge Connection"**
- Launch Factorio through the launcher, not Steam directly
- Check the launcher is running (system tray)
- Verify your API key is valid

**Combinator not responding**
- AI generation takes a few seconds - wait for it
- Check for error messages in the combinator interface
- Try rephrasing your request more specifically

---

## Need Help?

- [Discord Community](https://discord.gg/HYVuqC8kdP)
- [GitHub Issues](https://github.com/galgtonold/ai_combinator/issues)
- [Source Code & Documentation](https://github.com/galgtonold/ai_combinator)

---

## License

Based on Moon Logic 2, distributed under the MIT open-source license.
