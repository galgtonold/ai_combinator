# AI Combinator for Factorio

[![Download Latest Release](https://img.shields.io/github/v/release/galgtonold/ai_combinator?label=Download%20Launcher&style=for-the-badge&color=orange)](https://github.com/galgtonold/ai_combinator/releases/latest/download/AI-Combinator-Launcher-Setup-0.1.0.exe)
[![Latest Release](https://img.shields.io/github/v/release/galgtonold/ai_combinator?label=Latest%20Version&style=for-the-badge)](https://github.com/galgtonold/ai_combinator/releases/latest)

🤖 **Finally, a combinator that speaks human!**

Tired of building spaghetti circuits that even you can't understand? Meet the AI Combinator - it reads signals and outputs results just like any other combinator, except you tell it what to do in plain English instead of drowning in a sea of arithmetic and decider combinators.

It's like having a personal circuit engineer who never sleeps, never complains about your blueprint organization, and somehow makes sense of your "temporary" factory sections.

![AI Combinator Interface](images/ai-combinator-ui.png)
*Just tell it what you want - no combinatorics degree required*

## 🌟 Why This Changes Everything

**Finally, circuit networks for everyone!** Whether you're a complete beginner intimidated by combinator logic or an experienced player who just wants to build cooler stuff faster, the AI Combinator opens doors that were previously locked behind circuit complexity.

**For Circuit Beginners:** Jump straight into building smart factories without getting lost in arithmetic combinator hell. Want train automation? Smart production balancing? Resource monitoring? Just describe what you want and watch it work - then peek under the hood to learn how it's done.

**For Circuit Veterans:** Stop spending hours on tedious signal processing and focus on the creative challenges. Let AI handle the boring math while you design the interesting systems. Think of it as having a junior engineer who handles the grunt work.

**The Learning Bridge:** Start with simple AI-generated circuits, then gradually build your own components as you understand the patterns. The built-in testing system helps you experiment safely - no more wondering if your logic actually works!

## ✨ What's in the Box

**🗣️ Natural Language Programming**  
Type "make the lights rainbow" and watch it happen. No more counting ticks or debugging why your simple "if iron < 1000" took 47 combinators.

**🧪 Built-in Testing**  
Create test cases like a proper engineer! Set up inputs, define expected outputs, and let the system tell you when your logic actually works (revolutionary concept, we know).

**🔧 Smart Signal Wizardry**  
Handles all the signal types Factorio throws at it - items, fluids, virtuals, you name it. Even remembers things between ticks, which is more than we can say for most of our blueprints.

**🎨 Real Factory Examples**  
We've got rainbow lights, production achievement tracking, and smart asteroid processing. Because apparently teaching a computer to play Factorio was easier than organizing our own spaghetti.

![AI Code Generation](images/code-generation-demo.gif)
*AI doing the combinatorics so you don't have to*

## 🚀 Getting Started

### What You'll Need
- Factorio 2.0+ (because who's still running 1.1?)
- An API key from any supported AI service (we'll help you set this up)
- Basic understanding that belts go in straight lines (optional)

### Installation - Easier Than Balancing Your Smelter Setup

1. **Download the AI Combinator Launcher**
   
   👉 **[Download Latest Version](https://github.com/galgtonold/ai_combinator/releases/latest)** 👈
   
   ⚠️ **Important**: This isn't just a regular mod - you need the launcher! It's like the main bus for AI communication.

2. **Run the installer** - it's more reliable than your train signals, we promise

3. **Launch the app** and tell it about your AI service:
   - Pick your AI provider (OpenAI, Anthropic, Google, xAI, or DeepSeek)
   - Enter your API key (costs less than researching everything)
   - Choose a model (they're all smarter than your first spaghetti factory)

4. **Start Factorio through the launcher** - it'll handle the mod installation automatically

![Launcher Interface](images/launcher-setup.png)
*The launcher - cleaner than your circuit networks*

### Your First AI Combinator

1. **Enable the mod** for your specific save file (check your mod settings in-game)
2. **Research the AI Combinator technology** (it's in the circuit network tree, naturally)
3. **Craft one** - requires advanced circuits, because of course it does
4. **Plop it down** and wire it up like any other combinator
5. **Click on it** to open the magic window
6. **Tell it what you want** in actual English: "Turn on the lights when iron is low"
7. **Hit Generate** and watch it work better than your hand-crafted mess

![In-Game Usage](images/combinator-placement.gif)
*Placing your new favorite combinator*

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

Under the hood, the AI writes Lua code that handles all the signal processing - but you don't need to understand any of that mess!

## 🎮 What Can This Thing Actually Do?

### 🌈 RGB Rainbow Lights
*"Create a rainbow pattern that cycles through colors on connected lamps"*

Finally, decorative lighting that doesn't require a PhD in shift registers! The AI builds a proper color-cycling system that makes your factory look like a disco (in a good way).

![Rainbow Lights Demo](images/rainbow-lights-demo.gif)
*Your factory, but make it fabulous*

### 📊 Production Achievement Tracker  
*"Track items passing through this wire and announce milestones in chat"*

Remember when you hit your first million iron plates? Now the game will actually tell you! Set it up on your main bus and get congratulated for your factory's growth spurts.

"🎉 Milestone reached: 10,000 copper cables produced!"
"🏆 Achievement unlocked: 1,000,000 iron plates processed!"

![Production Tracking](images/production-tracking.png)
*Finally, recognition for your hard work*

### 🚀 Smart Asteroid Processing (Space Age)
*"Reprocess asteroids when stockpile exceeds threshold"*

Tired of manually managing your space platform's asteroid processing? This combinator watches your storage and automatically triggers reprocessing when you've got too much of the chunky stuff floating around.

![Asteroid Processing](images/asteroid-processing.png)
*Space logistics, but actually intelligent*

## 🧪 Test Your Circuits Like a Pro

One of the coolest features nobody talks about enough: **built-in testing!** Set up test cases with specific inputs and expected outputs, then watch the AI validate everything automatically.

- Define input signal scenarios
- Set expected output results  
- Run tests and get pass/fail reports
- AI can even auto-fix broken implementations

It's like unit testing, but for factory automation. Your circuits will actually work correctly on the first try (revolutionary concept, we know).

![Test Case Interface](images/test-case-ui.png)
*Testing circuits like the responsible engineer you pretend to be*

## 💡 Prompt Writing Tips

**Keep it simple and specific:**
```
"Output signal A when iron plates > 1000"
"Sum all input signals and put the result on signal TOTAL"
"Flash the warning light every 2 seconds when any resource is low"
```

**For time-based stuff:**
```
"Toggle signal every 60 seconds"
"Remember the highest value seen in the last 5 minutes"
"Only check inventory levels once per second to save UPS"
```

**Get creative with complex logic:**
```
"Calculate how many items per minute are flowing through"
"Alert when production rate drops below consumption"
"Create a smart train dispatcher that prevents deadlocks"
```

The AI is surprisingly good at understanding factory terminology and Factorio concepts!

## ⚙️ The Nerdy Bits (Optional Reading)

**What signals can it handle?** Everything a normal combinator can! Items, fluids, virtual signals - if it goes through a wire, this thing can process it.

**Performance impact?** It's definitely heavier than your average combinator (AI isn't free), but way lighter than building the same logic by hand. Think 10s to 100s of combinators per factory, not 1000s. If your UPS starts looking sad, maybe don't update every tick - once per second is often plenty.

**AI Providers:** OpenAI, Anthropic, Google, xAI, and DeepSeek are all supported. They're all paid services, but we're talking pennies here - cheaper than your daily coffee habit.

**Under the hood:** The AI writes Lua code that handles all the signal processing, but you don't need to understand any of that mess! It reads from `red` and `green` wires, remembers stuff between ticks, and outputs whatever you asked for.

## 🛠️ When Things Go Wrong

**"No AI Bridge Connection"**
- Did you launch Factorio through the launcher? (Not Steam directly!)
- Is your API key still valid? (Check the launcher settings)
- Is the launcher still running? (Check your system tray)

**Combinator seems brain-dead**
- Give it a moment - AI combinators think a bit slower than normal ones
- Check for error messages in the combinator interface  
- Try rephrasing your request - maybe be more specific?

**Factory turning into a slideshow**
- Too many AI combinators doing complex stuff every tick
- Try making some update less frequently ("only check this once per second")
- Monitor your UPS and dial it back if needed

**Still stuck?**
- Join our [Discord community](https://discord.gg/HYVuqC8kdP) for help, examples, and general factory chat
- Check [GitHub Issues](https://github.com/galgtonold/ai_combinator/issues) for known bugs
- The Discord has a gallery of working examples - great for inspiration!

## 🤝 Contributing

We welcome contributions! See `DEVELOPMENT.md` for technical details about the mod architecture and development setup.

## 📜 License

This mod is based on Moon Logic 2 and is distributed under the same open-source license.

---

**⭐ Like this mod?** Star us on GitHub and share your amazing AI-powered factories with the community!