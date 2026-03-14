# FoundationLabCLI

`fm` is the standalone command-line interface for Foundation Lab.

It intentionally stays as its own Swift package even though the repository also includes a native Xcode `fm` target.

## Why Both Exist

- `FoundationLabCLI` is the distributable unit for `swift run`, tagged releases, and Homebrew.
- The Xcode `fm` target is for local development inside `FoundationLab.xcodeproj`.
- Shared capability logic stays in `FoundationLabCore`; the CLI only handles argument parsing, availability checks, and output formatting.

## Local Development

```bash
cd FoundationLabCLI
swift run fm book recommend --dry-run --json --prompt "Suggest an uplifting science fiction novel"
```

## Homebrew Distribution

Homebrew should build the standalone `FoundationLabCLI` package from a tagged archive of this repository.

The package keeps a relative dependency on `../FoundationLabCore`, which is fine for Homebrew because the tagged source archive contains both directories.

### Release Flow

1. Tag a release in this repository, for example `0.3.0`.
2. Generate a formula from that tag:

```bash
./Scripts/generate-homebrew-formula.sh 0.3.0
```

3. Commit the generated formula to a tap repo such as `rudrankriyam/homebrew-tap` under `Formula/fm.rb`.
4. Users can then install it with:

```bash
brew install rudrankriyam/homebrew-tap/fm
```

### Formula Build Strategy

The generated formula builds the CLI from the tagged source archive like this:

```ruby
cd "FoundationLabCLI" do
  system "swift", "build", "--configuration", "release", "--disable-sandbox"
  bin.install ".build/release/fm"
end
```

## Requirements

- macOS 26.0+
- Xcode 26.0+
- Apple Intelligence enabled for non-`--dry-run` commands
