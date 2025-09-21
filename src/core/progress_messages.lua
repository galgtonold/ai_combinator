-- Progress messages for AI operations with Factorio theme and humor
-- Distribution: 30% Encouraging, 25% Memes, 20% Trolly, 15% Technical, 10% Humorous

local progress_messages = {}

-- Task evaluation messages - understanding what the human wants
progress_messages.TASK_EVALUATION = {
  -- Encouraging (30%)
  "Your logic blueprints are taking shape nicely...",
  "Calculating optimal factory expansion paths...",
  "Your automation skills are improving rapidly...",
  "Building efficient neural pathways...",
  "Your code efficiency rivals a well-tuned main bus...",
  "Analyzing with the precision of a perfect ratio...",
  "Your requirements are clearer than filtered water...",
  "Processing at maximum assembler efficiency...",
  "Your task complexity deserves quality modules...",
  "Mapping logic flows like a master engineer...",
  "Your specifications run smoother than lubricant...",
  "Building understanding at rocket-fuel pace...",
  "Your requirements shine brighter than uranium...",
  "Crafting solutions with legendary precision...",
  "Your logic flows like a perfectly balanced belt...",
  "Analyzing with the focus of a dedicated miner...",
  "Your code architecture rivals Factorio's engine...",
  "Processing requirements with nuclear efficiency...",

  -- Meme References (25%)
  "The factory must grow... and so must understanding...",
  "Just one more requirement to analyze...",
  "The task is expanding faster than biters...",
  "Your logic is less spaghetti than expected...",
  "This won't take long, just like iron mining...",
  "The factory must grow, but first, comprehension...",
  "One does not simply understand requirements...",
  "I'll just quickly analyze this... 8 hours later...",
  "Your task is growing like pollution clouds...",
  "The spice must flow... I mean, logic must flow...",
  "Expanding analysis like a perfectly planned city...",
  "Your requirements are more organized than most bases...",
  "This is fine... everything is under control...",
  "The factory must grow, but slowly, methodically...",
  "Just redesigning this small analysis section...",

  -- Trolly/Taunting (20%)
  "Still trying to decode your engineering decisions...",
  "Your logic needs more than yellow inserters...",
  "Even biters could plan this better...",
  "Your specifications are as clear as pollution...",
  "I've seen cleaner spaghetti in kindergarten...",
  "Your requirements change faster than biter evolution...",
  "Are you sure this isn't just random button pressing?",
  "Your planning skills make trains look organized...",
  "Even a burner inserter works more efficiently...",
  "Your logic tree has more branches than a forest...",
  "This analysis is taking longer than your last rebuild...",
  "Your specifications are vaguer than early game research...",

  -- Technical/Flavor (15%)
  "Initializing requirement parsing algorithms...",
  "Running semantic analysis on factory specifications...",
  "Compiling task definitions with belt-level throughput...",
  "Optimizing understanding matrices for UPS efficiency...",
  "Processing inputs through combinatorial networks...",
  "Executing deep learning on automation patterns...",
  "Parsing requirements through circuit logic gates...",
  "Analyzing complexity using factorio-grade algorithms...",
  "Implementing understanding with main-bus architecture...",

  -- Humorous Observations (10%)
  "Teaching AI to think like a sleep-deprived engineer...",
  "Running requirement analysis on potato-powered servers...",
  "Your task makes my circuits smoke more than coal...",
  "Converting human chaos into robot-readable format...",
  "This analysis burns more power than your laser turrets...",
  "Your requirements generate more heat than nuclear reactors...",
}

-- Test generation messages - creating test scenarios
progress_messages.TEST_GENERATION = {
  -- Encouraging (30%)
  "Crafting test scenarios with legendary precision...",
  "Your test factory is expanding beautifully...",
  "Building quality control systems...",
  "Engineering robust testing infrastructure...",
  "Your test coverage rivals a well-defended perimeter...",
  "Designing tests with assembly-line efficiency...",
  "Creating comprehensive validation blueprints...",
  "Your testing strategy deserves productivity modules...",
  "Building test cases like a master builder...",
  "Generating scenarios worthy of science packs...",
  "Your test architecture shines like beacons...",
  "Crafting edge cases with surgical precision...",
  "Building testing empire brick by brick...",
  "Your validation logic flows like perfect ratios...",
  "Creating test scenarios at light-speed efficiency...",
  "Engineering tests that would make robots proud...",
  "Your test factory runs smoother than trains...",
  "Building quality assurance with nuclear precision...",

  -- Meme References (25%)
  "The factory must grow... these test cases too...",
  "Just one more test scenario... surely...",
  "Your tests are expanding like biter territory...",
  "This won't take long, just like belt optimization...",
  "The tests must flow, the tests must grow...",
  "One does not simply generate perfect tests...",
  "I'll just add one more edge case... 50 tests later...",
  "Your test coverage grows like pollution on a map...",
  "The factory of tests must grow exponentially...",
  "Just redesigning this small testing section...",
  "Tests are like iron patches, you always need more...",
  "Your testing factory is less spaghetti than most...",
  "This test generation is more addictive than the game...",
  "The factory must grow, and so must test coverage...",
  "Building tests like there's no tomorrow...",

  -- Trolly/Taunting (20%)
  "Creating tests to break your precious creation...",
  "Your code will cry when it meets these tests...",
  "Designing scenarios where your logic fails spectacularly...",
  "Even biters could write better test cases...",
  "Your future self will thank me for these edge cases...",
  "Building tests that would make a train conductor blush...",
  "Creating chaos worthy of your spaghetti code...",
  "Your logic will meet its match in these scenarios...",
  "Designing tests meaner than evolution-maxed biters...",
  "Your code is about to face its final boss...",
  "Creating tests that break things you didn't know existed...",
  "Your confidence is about to be thoroughly tested...",

  -- Technical/Flavor (15%)
  "Initializing test case generation protocols...",
  "Compiling edge case scenarios with belt throughput...",
  "Generating validation matrices for optimal coverage...",
  "Processing test blueprints through quality modules...",
  "Executing scenario generation with UPS optimization...",
  "Implementing test frameworks with circuit precision...",
  "Building test suites with main-bus methodology...",
  "Optimizing test generation for maximum efficiency...",
  "Deploying automated testing infrastructure...",

  -- Humorous Observations (10%)
  "Teaching robots to be more creative than humans...",
  "Your tests generate more heat than steam engines...",
  "Building scenarios that defy the laws of logic...",
  "Creating tests on servers powered by copper wire dreams...",
  "Your test factory produces more chaos than your main base...",
  "These tests will consume more resources than your megabase...",
}

-- Test fixing messages - debugging and improving code  
progress_messages.TEST_FIXING = {
  -- Encouraging (30%)
  "Optimizing your logic with legendary efficiency...",
  "Your code is evolving beautifully...",
  "Refining algorithms with master craftsmanship...",
  "Your fixes flow smoother than oil processing...",
  "Debugging with the precision of laser surgery...",
  "Your improvements shine brighter than beacons...",
  "Optimizing code like a well-tuned factory floor...",
  "Your logic is reaching perfect ratio harmony...",
  "Fixing bugs with assembly-line efficiency...",
  "Your code transformation rivals factory evolution...",
  "Debugging with the focus of a dedicated researcher...",
  "Your improvements run smoother than express belts...",
  "Optimizing logic with nuclear-grade precision...",
  "Your fixes deserve quality module recognition...",
  "Refining code like a master engineer...",
  "Your debugging skills rival automation itself...",
  "Building better logic, one fix at a time...",
  "Your code efficiency is reaching rocket fuel levels...",

  -- Meme References (25%)
  "The factory must grow... away from these bugs...",
  "Just one more small fix... 12 hours later...",
  "Your code is evolving faster than biters...",
  "This won't take long, just like factory redesigns...",
  "The bugs must die, the factory must live...",
  "One does not simply fix spaghetti code...",
  "I'll just fix this one thing... rebuilds entire system...",
  "Your code is getting less spaghetti by the minute...",
  "The factory must grow, but first, bug fixes...",
  "Just redesigning this small logic section...",
  "Fixes are like iron, you always need more...",
  "Your code is becoming more organized than most bases...",
  "This debugging session is more engaging than the game...",
  "The factory must grow, and so must code quality...",
  "Building fixes like there's no production deadline...",

  -- Trolly/Taunting (20%)
  "Fixing your beautiful disaster of logic...",
  "Your code called, it wants a complete makeover...",
  "Even burner inserters work more reliably...",
  "Your bugs are more persistent than biters...",
  "Applying fixes despite your best efforts to break things...",
  "Your logic needs more help than a stranded engineer...",
  "Debugging code that defies the laws of programming...",
  "Your bugs multiply faster than rabbit populations...",
  "Even pollution clears up faster than your code...",
  "Your logic has more holes than swiss cheese...",
  "Fixing code that would make circuits weep...",
  "Your bugs are more evolved than late-game biters...",

  -- Technical/Flavor (15%)
  "Executing debug protocols with circuit precision...",
  "Implementing fixes through combinatorial optimization...",
  "Processing error correction with belt-level throughput...",
  "Optimizing code paths for maximum UPS efficiency...",
  "Deploying patch algorithms with main-bus architecture...",
  "Executing repair sequences through logic networks...",
  "Implementing solutions with assembler-grade reliability...",
  "Processing fixes with quality module enhancement...",
  "Running optimization algorithms on factory-grade hardware...",

  -- Humorous Observations (10%)
  "Your bugs are achieving sentience faster than AI...",
  "This debugging session consumes more power than your base...",
  "Fixing code on servers held together by copper wire...",
  "Your logic generates more smoke than coal processing...",
  "These fixes require more resources than space science...",
  "Your code complexity rivals rocket fuel production chains...",
}

return progress_messages
