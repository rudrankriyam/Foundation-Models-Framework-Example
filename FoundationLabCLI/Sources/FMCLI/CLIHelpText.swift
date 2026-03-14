enum CLIHelpText {
    static let root = """
    COMMAND GROUPS
      status      Check Foundation Models readiness and the available CLI surface.
      tools       Run tool-backed demos such as weather lookup and web search.
      examples    Run app-style demos like one-shot, streaming, and structured data.
      schemas     Run structured schema demos and inspect available presets.
      languages   Run multilingual and language-aware demos.
      chat        Use the shared multi-turn conversation engine.

    QUICK START
      fm status
      fm examples list
      fm examples run structured-data --prompt "Suggest an uplifting science fiction novel"
      fm schemas run basic-object --preset person
      fm languages run nutrition --description "Greek yogurt and blueberries"
      fm tools weather get --location "San Francisco"
      fm chat run --message "Hello" --message "Summarize what I just asked."

    LEARN MORE
      Use `fm <command> --help` and `fm <command> <subcommand> --help` for detailed help.
    """

    static let tools = """
    TOOLS COMMANDS
      weather     Weather tool flows backed by the shared core runtime.
      web         Web search and page summary flows backed by the shared core runtime.

    EXAMPLES
      fm tools weather get --location "San Francisco"
      fm tools web search --query "Apple Foundation Models"
      fm tools web summary --url "https://developer.apple.com/machine-learning/foundation-models/"
    """

    static let weather = """
    WEATHER COMMANDS
      get         Resolve the weather for a location using the shared tool orchestration path.

    EXAMPLE
      fm tools weather get --location "San Francisco"
    """

    static let web = """
    WEB COMMANDS
      search      Search the web through the shared web-search capability.
      summary     Summarize a web page through the shared web-summary capability.

    EXAMPLES
      fm tools web search --query "Foundation Models framework"
      fm tools web summary --url "https://developer.apple.com/machine-learning/foundation-models/"
    """

    static let examples = """
    EXAMPLES COMMANDS
      list        Show the available example demos.
      run         Execute a specific example demo.

    POPULAR DEMOS
      basic-chat
      structured-data
      streaming
      journaling
      generation-options

    EXAMPLES
      fm examples list
      fm examples run structured-data --prompt "Suggest an uplifting science fiction novel"
      fm examples run streaming --prompt "Write a short story about a robot gardener"
    """

    static let schemas = """
    SCHEMAS COMMANDS
      list        Show the available schema demos and their presets.
      run         Execute a specific schema demo.

    AVAILABLE DEMOS
      basic-object
      array-schema
      enum-schema

    EXAMPLES
      fm schemas list
      fm schemas run basic-object --preset person
      fm schemas run array-schema --preset todo
      fm schemas run enum-schema --preset weather
    """

    static let languages = """
    LANGUAGES COMMANDS
      list        Show supported languages using the shared language catalog.
      run         Execute a specific language demo.

    AVAILABLE DEMOS
      multilingual
      session
      nutrition

    EXAMPLES
      fm languages list
      fm languages run multilingual --limit 3
      fm languages run nutrition --description "I had oatmeal and berries" --language "French"
    """

    static let chat = """
    CHAT COMMANDS
      run         Send one or more messages through the shared conversation engine.

    EXAMPLE
      fm chat run --message "Hello" --message "Summarize what I just asked."
    """
}
