enum CLIHelpText {
    static let root = """
    FRAMEWORK COMMANDS
      status      Show model readiness and the runnable CLI surface at a glance.
      model       Inspect availability and supported languages.
      session     Use LanguageModelSession-style flows such as respond, stream, and chat.
      tools       Use tool calling workflows such as weather and web search.
      schemas     Run structured generation and dynamic schema workflows.
      examples    Explore higher-level demos built on top of the framework commands.

    QUICK START
      fm status
      fm model status
      fm model languages
      fm session respond --prompt "Suggest a name for a coffee shop"
      fm session stream --prompt "Write a short poem about rain"
      fm session chat --message "Hello" --message "Summarize what I just asked." --transcript
      fm tools weather get --location "San Francisco"
      fm schemas run basic-object --preset person
      fm examples list

    SESSION EXTRAS
      Add `--transcript` to include transcript output.
      Add `--log-feedback positive|negative` to attach feedback to the assistant reply.

    LEARN MORE
      Use `fm <command> --help` and `fm <command> <subcommand> --help` for detailed help.
    """

    static let model = """
    MODEL COMMANDS
      status      Check whether Apple Intelligence is available and ready.
      languages   List the supported model languages for the current locale.

    EXAMPLES
      fm model status
      fm model languages --json
    """

    static let session = """
    SESSION COMMANDS
      respond     Send one prompt through a fresh session and print the final response.
      stream      Stream one response from a fresh session as it is generated.
      chat        Send multiple prompts through one shared session.

    COMMON FLAGS
      --system-prompt          Override the default session instructions.
      --sampling-mode          Choose `greedy`, `top-k`, or `nucleus`.
      --temperature            Override the sampling temperature.
      --max-tokens             Cap the response length.
      --transcript             Include the transcript in the output.
      --log-feedback           Attach positive or negative feedback to the assistant reply.

    EXAMPLES
      fm session respond --prompt "Summarize Foundation Models in one paragraph."
      fm session stream --prompt "Write a short story about a robot gardener"
      fm session chat --message "Hello" --message "Now answer in French." --transcript
    """

    static let tools = """
    TOOLS COMMANDS
      weather     Weather tool flows backed by the shared tool runtime.
      web         Web search and page summary flows backed by the shared tool runtime.

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
      list        Show the available example demos built on top of the core commands.
      run         Execute a specific example demo.

    CORE DEMOS
      basic-chat
      structured-data
      streaming
      journaling
      generation-options

    LANGUAGE DEMOS
      multilingual
      language-session
      nutrition

    EXAMPLES
      fm examples list
      fm examples run structured-data --prompt "Suggest an uplifting science fiction novel"
      fm examples run multilingual --limit 3
      fm examples run streaming --prompt "Write a short story about a robot gardener"
    """

    static let schemas = """
    SCHEMAS COMMANDS
      list        Show the available structured schema demos and their presets.
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
}
