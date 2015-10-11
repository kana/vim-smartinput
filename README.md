# SmartInput
What does this plugin do? It auto-completes your input as you type, without asking you for permission or giving you options. Think of it like a more aggressive version of `snipmate`! "And how is that a good thing?", you may ask. Well, let me ask you this:

- Do you like when your editor auto-completes matching parentheses and brackets for you?
- Do you like when your editor auto-indents stuff for you (assuming it gets it right)?
- Do you like when your editor automatically determines that there should be a semicolon at the end?
- Do you like when your editor spaces things correctly for you (space after that comma before next argument)?
- Do you like when your editor auto-aligns things?
- Do you like when your editor lets you quickly jump out of a block you're in?
- Do you like when your editor auto-completes your code patterns?
- Do you like when your editor helps you with code conventions automatically?
- Do you keep forgetting which language conventions ask for camelCase and which ask for snake_case?
- Do you like when your backspace is smart enough to undo the macro you may have unintentionally triggered?
- Do you want a single plugin to give vim all those type-completion features that your friend gets for free with Sublime/Atom?
- Do you want to one-up that Sublime/Atom friend?

If you answered "yes" to any of the above, you, my friend, probably want this plugin (cheesy car salesman grin).


# Features
- Everything `auto-pairs` plugin can do
- snake_case vs camelCase auto-correction based on language
- Support for most of the popular languages, with unique auto-completion macros for each (as well as some common ones)
- Easy way to add your own macros to the plugin
- Automatic bracket/quote/parentheses completion/pairing
- Proper detection of `\` to prevent pairing in quotes
- Backspace to undo both pairs (if inside the pair, undo only trailing when outside)
- Unfold brackets/parentheses when space/enter is used
- Undo unfold with backspace
- Automatic semi-colons in Perl/JS
- Automatic whitespace insertion (after commas, around binary operators, and when in markdown, for punctuation as well)
- Automatic escape out of parentheses/brackets when you type the closing brace
