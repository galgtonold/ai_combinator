# AI Combinator for Factorio

🤖 **Transform your circuit networks with the power of AI!**

The AI Combinator is a revolutionary Factorio mod that adds an intelligent combinator to your circuit networks. Like any combinator, it reads input signals and produces output signals - but instead of manually configuring complex logic, you simply describe what you want in plain English and AI figures out the rest!

![AI Combinator Interface](images/ai-combinator-ui.png)
*The AI Combinator interface with natural language input*

## ✨ Features

- **Smart Circuit Logic**: Describe complex combinator behavior in natural language
- **Signal Processing**: Read input signals from red/green wires and output calculated results
- **Persistent Memory**: Remember values between game ticks for advanced logic
- **Game Integration**: Can print messages and information to the game console
- **Visual Signal Display**: See all circuit signals with helpful visual indicators
- **Error Handling**: Clear error messages and debugging information

![AI Code Generation](images/code-generation-demo.gif)
*Watch the AI create circuit logic from your description*

## 🚀 Quick Start

### Prerequisites
- Factorio 2.0 or later
- API key for a supported AI service (configured through the launcher)

### Installation

1. **Download the AI Combinator Launcher** from the [releases page](https://github.com/galgtonold/ai_combinator/releases)
   
   ⚠️ **Important**: This mod requires the launcher application to work! The launcher handles AI communication and configuration.

2. **Install the launcher** by running the downloaded executable

3. **Launch the application** and configure your settings:
   - Enter your AI service API key
   - Select your Factorio installation (auto-detected in most cases)
   - Choose your preferred AI model and provider

4. **Start Factorio** through the launcher - it will automatically enable the AI Combinator mod

![Launcher Interface](images/launcher-setup.png)
*The launcher configuration screen*

### First Steps

1. **Research the AI Combinator technology** in your Factorio game
2. **Craft an AI Combinator** using the recipe (requires advanced circuits)
3. **Place the combinator** in your circuit network like any other combinator
4. **Connect red/green wires** to provide input signals and receive outputs
5. **Click on the combinator** to open the AI interface
6. **Describe the logic you want** (e.g., "Output signal A when iron plates < 1000")
7. **Click Generate** and watch the combinator process signals intelligently!

![In-Game Usage](images/combinator-placement.gif)
*Placing and configuring an AI Combinator*

## 🔧 How It Works

The AI Combinator functions like any other combinator in Factorio, but with intelligent behavior:

**Input/Output Capabilities:**
- **Red and Green Wire Inputs**: Reads signals from connected circuit networks
- **Signal Output**: Produces calculated output signals to connected devices
- **Persistent Variables**: Maintains state between game ticks for complex logic
- **Game Messages**: Can print information to the game console for debugging
- **Timing Control**: Access to game tick for time-based operations

**Combinator Limitations:**
- Cannot directly control entities (inserters, belts, etc.) - only through circuit signals
- Cannot access inventory contents directly - must rely on circuit-connected sensors
- Output is limited to circuit signals that other devices can interpret
- Cannot perform actions outside the circuit network system

Under the hood, the AI generates Lua code that processes your input signals and produces the desired output, but you don't need to know any programming!

### Example Prompts & What They Do

**Basic Signal Logic**:
- *"Output signal A when iron plates signal is greater than 1000"*
  → Reads iron plate count from input, outputs signal A when threshold met

- *"Count inserters and output the total on signal C"* 
  → Adds up all inserter signals from input, outputs sum on signal C

**Smart Processing**:
- *"Set red signal to 1 when any green input exceeds 5000, but only every 60 seconds"*
  → Time-based signal switching with persistent memory

- *"Output the highest value among all input signals on signal MAX"*
  → Signal comparison and maximum value detection

**Advanced Logic**:
- *"Track iron consumption rate and warn when usage exceeds production"*
  → Calculates consumption trends, outputs warning signal

- *"Create a train request signal when cargo wagon is 80% full"*
  → Processes cargo signals to determine fullness percentage

![Complex Circuit Example](images/complex-circuit.png)
*An AI-generated inventory monitoring system*

## ⚙️ Technical Details

For those interested in the technical implementation: the AI Combinator works by generating Lua code that processes circuit signals. The AI creates safe, sandboxed code that:

- Reads input signals from `red` and `green` wire networks
- Performs calculations and logic operations
- Outputs results to the `out` signal table
- Maintains persistent state in `var` for complex behaviors
- Can access `game.tick` for timing-based logic

This code generation happens behind the scenes - you just describe what you want, and the AI handles the programming complexity!

## 🛠️ Troubleshooting

### Common Issues

**"AI Bridge not connected"**
- Make sure you launched Factorio through the AI Combinator Launcher
- Check that your AI service API key is valid and properly configured
- Verify the launcher is still running in the background

**Code not updating**
- The combinator updates every few ticks - wait a moment
- Check for error messages in the combinator interface
- Try rephrasing your prompt more clearly

**Performance issues**
- Avoid creating too many AI combinators in a single factory
- Use simpler logic when possible - the AI is very capable!

### Getting Help

- Check the [GitHub Issues](https://github.com/galgtonold/ai_combinator/issues) for known problems
- Join our [Discord community](https://discord.gg/factorio-ai-combinator) for support
- Submit bug reports with your mod version and error logs

## 🤝 Contributing

We welcome contributions! See `DEVELOPMENT.md` for technical details about the mod architecture and development setup.

## 📜 License

This mod is based on Moon Logic 2 and is distributed under the same open-source license.

---

**⭐ Like this mod?** Star us on GitHub and share your amazing AI-powered factories with the community!