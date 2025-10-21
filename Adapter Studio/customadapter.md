
Apple Intelligence

    Overview
    What’s New
    Get Started
    Resources

Get started with Foundation Models adapter training

Teach the on-device language model new skills specific to your app by training a custom adapter. This toolkit contains a Python training workflow and utilities to package adapters for use with the Foundation Models framework.

    Overview
    Download toolkit
    How to train adapters

Overview

While the on-device system language model is powerful, it may not be capable of all specialized tasks. Adapters are an advanced technique that adapt a large language model (LLM) with new skills or domains. With the adapter training toolkit, you can train adapters to specialize the on-device system LLM's abilities, and then use your adapter in apps with the Foundation Models framework. On this page you can download the toolkit and learn about the adapter training process. To use custom adapters in your app, see the framework guide Loading and using a custom adapter with Foundation Models.

The adapter training toolkit contains:

    Python sample code for each adapter training step
    Model assets that match a specific system model version
    Utilities to export an .fmadapter package
    Utilities to bundle adapters as asset packs for Background Assets

Important

Each adapter is compatible with a single specific system model version. To support people using your app who have devices on OS versions using different system model versions, you will need to train a different adapter for every version of the system model.
Foundation Models Framework Adapter Entitlement

When you’re ready to deploy adapters in your app, the Account Holder of a membership in the Apple Developer Program will need to request the Foundation Models Framework Adapter Entitlement. You don't need this entitlement to train or locally test adapters.

Get entitlement
Download toolkit

To download any adapter training toolkit version, you’ll need to be a member of the Apple Developer Program and will first need to agree to the terms and conditions of the toolkit.

Get toolkit

Remember you may need to download multiple toolkit versions. Each version contains the unique model assets compatible with a specific OS version range. To support people on different OS versions using your app, you must train an adapter for each version of the toolkit.
Version 	Changes 	OS Compatibility
Beta 0.1.0 (removed) 	Initial release. 	macOS 26, iOS 26, iPadOS 26, visionOS 26
Beta 0.2.0 (removed) 	Updates for new base model version. Updated data schema with support for tool-calling. New data schema utility for guided generation. 	macOS 26, iOS 26, iPadOS 26, visionOS 26
26.0.0 	First full toolkit version. New support for custom data transforms in training pipeline. Updated guided generation transform utility. 	macOS 26, iOS 26, iPadOS 26, visionOS 26

When do new versions come out? A new toolkit will be released for every system model update. The system model is shared across iOS, macOS, and visionOS, and system model updates will occur as part of those platforms’ OS updates (though not every OS update will have a model update). Be sure to install and use the latest beta software releases so that you have time to train a new adapter before people start using your app with the new system model version. Additionally, with the Foundation Models Framework Adapter Entitlement, the Account Holder of your membership in the Apple Developer Program will get an email update when a new toolkit version is available. Otherwise, when a new beta comes out, check here for any new toolkit versions.
How to train adapters

This guide provides a conceptual walkthrough of the steps to train an adapter. Each toolkit version also includes a sample code end-to-end Jupyter notebook in ./examples.
Requirements

    Mac with Apple silicon and at least 32GB memory, or Linux GPU machines
    Python 3.11 or later

1. When to consider an adapter

Adapters are an effective way to teach the model specialized tasks, but they have steep requirements to train (and re-train for OS updates), so adapters aren’t suitable for all situations. Before considering adapters, try to get the most out of the system model using prompt engineering or tool calling. With the Foundation Models framework, tool calling is an effective way to give the system model access to outside knowledge sources or services.

Adapter training is worth considering if you have a dataset suitable for use with an LLM, or if your app is already using a fine-tuned server-based LLM and you want to try replicating that functionality with the on-device LLM for reduced costs. Other reasons to use an adapter include:

    You need the model to become a subject-matter expert.
    You need the model to adhere to a specific style, format, or policy.
    Prompt engineering isn’t achieving the required accuracy or consistency for your task.
    You want lower latency at inference. If your prompt-engineered solutions require lengthy prompts with examples for every call, an adapter specialized for that task offers minimal prompting.

Take into consideration that you will need:

    A dataset of prompt and response pairs that demonstrate your target skill
    A process for evaluating the quality of your adapters
    A process to load your adapters into your app from a server

Each adapter will take approximately 160 MB of storage space in your app. Like other big assets, adapters shouldn’t be part of your app’s main bundle because with multiple adapter versions your app will become too big for people to install. Instead, host your adapters on a server so that each person using your app can download just one adapter compatible with their device using the Background Assets framework. For more on how, see the documentation guide Loading and using a custom adapter with Foundation Models.
2. Set up virtual environment

Once you’ve downloaded the toolkit, it’s recommended to set up a Python virtual environment, using a Python environment manager like conda or venv:

conda create -n adapter-training python=3.11
conda activate adapter-training
cd /path/to/toolkit

3. Install dependencies

Next, use pip to install all the packages required by the toolkit:

pip install -r requirements.txt

Finally, start running the toolkit’s walkthrough Jupyter notebook to finish setup:

jupyter notebook ./examples/end_to_end_example.ipynb

4. Test generation

Verify your setup is ready by loading and running inference with system base model assets in the assets folder. The Jupyter notebook in examples demonstrates how to run inference, or you can run examples/generate.py from the command line:

python -m examples.generate --prompt "Prompt here"

Note

This toolkit includes system model weights optimized for efficient adapter training. You are only permitted to use these model assets for training adapters. The behavior of the toolkit system model may not match the performance of the Foundation Models framework or other features exactly.
5. Prepare a dataset

To train an adapter, you’ll need to prepare a dataset in the jsonl format expected by the model. As a rough estimate of how much data you’ll need, consider:

    100 to 1,000 samples to teach the model basic tasks
    5,000+ samples to teach the model complex tasks

The full expected data schema, including special fields you need to support guided generation and improve AI safety, can be found in the toolkit in Schema.md. The most basic schema is a list of prompt and response pairs:

jsonl
[{"role": "user", "content": "PROMPT"}, {"role": "assistant", "content": "RESPONSE"}]

Here "role" identifies who is providing the content. The role "user" can refer to any entity providing the input prompt, such as you the developer, people using your app, or a mix of sources. The role "assistant" always refers to the model. Replace the "content" values above with your prompt and response, which can be text written in any language supported by Apple Intelligence.

Utilities to help you prepare your data, including options for specifying language and locale, can be found in examples/data.py.

After formatting, split your data into train and eval sets. The train set is used to optimize the adapter parameters during training. The eval set is used to monitor performance during training, such as identifying overfitting, and providing feedback to help you tune hyper-parameters.

Tip

Focus on quality over quantity. A smaller dataset of clear, consistent, and well-structured samples may be more effective than larger dataset of noisy, low-quality samples.
6. Start adapter training

Adapter training is faster and less memory-intensive than fine-tuning an entire large language model. This is because the system model uses a parameter-efficient fine-tuning (PEFT) approach known as LoRA (Low-Rank Adaptation). In LoRA, the original model weights are frozen, and small trainable weight matrices called “adapters” are embedded through the model’s network. During training, only adapter weights are updated, significantly reducing the number of parameters to train. This approach also allows the base system model to be shared across many different use cases and apps that can each have a specialized adapter.

Start training by running the walkthrough Jupyter notebook in examples, or the sample code in examples/train_adapter.py. You can modify and customize the training sample code to meet your use cases’s needs. For convenience, examples/train_adapter.py can be run from the command line:

python -m examples.train_adapter \
--train-data /path/to/train.jsonl \
--eval-data /path/to/valid.jsonl \
--epochs 5 \
--learning-rate 1e-3 \
--batch-size 4 \
--checkpoint-dir /path/to/my_checkpoints/

Use the data you prepared for train-data and eval-data. The additional training arguments are:

    epochs is number of training iterations. More epochs will take longer, but may improve your adapter’s quality.
    learning-rate is a floating-point number indicating how much to adjust the model’s parameters at each step. Adjustments should be tailored to the specific use case.
    batch-size is the number of examples in a single training step. Choose batch size based on the machine you’re running the training process on.
    checkpoint-dir is a folder you create so that the training process can save checkpoints of your adapter as it trains.

During and after training, you can compare your adapter’s checkpoints to pick the one that best meets your quality goals. Checkpoints are also handy for resuming training in case the process fails midway, or you decide to train again for a few more epochs.
7. Optionally train the draft model

After training an adapter, you can train a matching draft model. Each toolkit includes assets for the system draft model, which is a small version of the system base model that can speed up inference via a technique called speculative decoding. Training the draft model is very similar to training an adapter, with some additional metrics so that you can measure how much your draft model speeds up inference. This step is optional. If you choose not to train the draft model, speculative decoding will not be available for your adapter’s use case. For more details on how draft models work, please refer to the papers Leviathan et al., 2022 (arXiv:2211.17192) and Chen et al., 2023 (arXiv:2302.01318).

Just like adapter training, you can train using the examples Jupyter notebook, or by running the sample code in train_draft_model.py from the command line:

python -m examples.train_draft_model \
--checkpoint /path/to/my_checkpoints/adapter-final.pt \
--train-data /path/to/train.jsonl \
--eval-data /path/to/valid.jsonl \
--epochs 5 \
--learning-rate 1e-3 \
--batch-size 4 \
--checkpoint-dir /path/to/my_checkpoints/

Training arguments are the same as training an adapter, except for:

    checkpoint is the base model checkpoint after adapter training as the target for draft model training. Choose the checkpoint you intend to export for your adapter.
    checkpoint-dir is where you’d like your draft model checkpoints saved

After you train the draft model, if you’re not seeing much inference speedup, try experimenting with retraining the draft model using different hyper-parameters, more epochs, or alternative data to improve performance.
8. Evaluate adapter quality

Congratulations, you’ve trained an adapter! After training, you will need to evaluate how well your adapter has improved the system model’s behavior for your specific use case. Since each adapter is specialized, evaluation needs to be a custom process that makes sense for your specific use case. Typically, adapters are evaluated by both quantitative metrics, such as match to a target dataset, and qualitative metrics, such as human grading or auto-grading by a larger server-based LLM. You will want to come up with a standardized eval process, so that you can evaluate each of your adapters for each model version, and ensure they all meet your performance goals. Be sure to also evaluate your adapter for AI safety.

To start running inference with your new adapter, see the walkthrough Jupyter notebook, or call the sample code examples/generate.py from the command line:

python -m examples.generate \
--prompt "Your prompt here" \
--checkpoint /path/to/my_checkpoints/adapter-final.pt \
--draft-checkpoint /path/to/my_checkpoints/draft-model-final.pt

Include the arguments draft_checkpoint only if you trained a draft model.
9. Export adapter

When you’re ready to export, the toolkit includes utility functions to export your adapter in the .fmadapter package format Xcode and Foundation Models framework expect. Unlike all the customizable sample code for training, code in the export folder should not be modified, since the export logic must match exactly to make your adapter compatible with the system model and Xcode.

Export is covered in the walkthrough Jupyter notebook in examples, and the export utility can be run from the command line:

python -m export.export_fmadapter \
--adapter-name my_adapter \
--checkpoint /path/to/my_checkpoints/adapter-final.pt \
--draft-checkpoint /path/to/my_checkpoints/draft-model-final.pt \
--output-dir /path/to/my_exports/

If you trained the draft model, the --draft_checkpoint argument will bundle your draft model checkpoint as part of the .fmadapter package. Exclude this argument otherwise.

Now that you have my_adapter.fmadapter, you’re ready to start using your custom adapter with the Foundation Models framework. For next steps, check out the framework documentation guide Loading and using a custom adapter with Foundation Models.
Developer Footer

SystemLanguageModel.UseCase
P

static let `default`: SystemLanguageModel

Getting the default model
M

func supportsLocale(Locale) -> Bool

Determining whether the model supports a locale
P

var supportedLanguages: Set<Locale.Language>

Retrieving the supported languages
E

SystemLanguageModel.Availability
P

var availability: SystemLanguageModel.Availability
P

var isAvailable: Bool

Checking model availability
S

SystemLanguageModel.Adapter
M

convenience init(adapter: SystemLanguageModel.Adapter, guardrails: SystemLanguageModel.Guardrails)
T

com.apple.developer.foundation-model-adapter

Loading and using a custom adapter with Foundation Models

Loading the model with an adapter
S

SystemLanguageModel.Guardrails
S

SystemLanguageModel.UseCase
M

convenience init(useCase: SystemLanguageModel.UseCase, guardrails: SystemLanguageModel.Guardrails)

Loading the model with a use case
C

    Foundation Models
    SystemLanguageModel
    Loading and using a custom adapter with Foundation Models 

Article
Loading and using a custom adapter with Foundation Models
Specialize the behavior of the system language model by using a custom adapter you train.
Overview

Use an adapter to adapt the on-device foundation model to fit your specific use case without needing to retrain the entire model from scratch. Before you can load a custom adapter, you first need to train one with an adapter training toolkit. The toolkit uses Python and Pytorch, and requires familiarity with training machine-learning models. After you train an adapter, you can use the toolkit to export a package in the format that Xcode and the Foundation Models framework expects.

When you train an adapter you need to make it available for deployment into your app. An adapter file is large — 160 MB or more — so don’t bundle them in your app. Instead, use App Store Connect, or host the asset on your server, and download the correct adapter for a person’s device on-demand.

Important

Each adapter is compatible with a single specific system model version. You must train a new adapter for every new base model version. A runtime error occurs if your app runs on a person’s device without a compatible adapter.

For more information about the adapter training toolkit, see Get started with Foundation Models adapter training. For more information about asset packs, see Background Assets.
Test a local adapter in Xcode

After you train an adapter with the adapter training toolkit, store your .fmadapter package files in a different directory from your app. Then, open .fmadapter packages with Xcode to locally preview each adapter’s metadata and version compatibility before you deploy the adapter.

If you train multiple adapters:

    Find the adapter package that’s compatible with the macOS version of the Mac on which you run Xcode.

    Select the compatible adapter file in Finder.

    Copy its full file path to the clipboard by pressing Option + Command + C.

    Initialize SystemLanguageModel.Adapter with the file path.

// The absolute path to your adapter.
let localURL = URL(filePath: "absolute/path/to/my_adapter.fmadapter")


// Initialize the adapter by using the local URL.
let adapter = try SystemLanguageModel.Adapter(fileURL: localURL)

After you initialize an Adapter, create an instance of SystemLanguageModel with it:

// An instance of the the system language model using your adapter.
let customAdapterModel = SystemLanguageModel(adapter: adapter)


// Create a session and prompt the model.
let session = LanguageModelSession(model: customAdapterModel)
let response = try await session.respond(to: "Your prompt here")

Important

Only import adapter files into your Xcode project for local testing, then remove them before you publish your app. Adapter files are large, so download them on-demand by using Background Assets.

Testing adapters requires a physical device and isn’t supported on Simulator. When you’re ready to deploy adapters in your app, you need the com.apple.developer.foundation-model-adapter entitlement. You don’t need this entitlement to train or locally test adapters. To request access to use the entitlement, log in to Apple Developer and see Foundation Models Framework Adapter Entitlement.
Bundle adapters as asset packs

When people use your app they only need the specific adapter that’s compatible with their device. Host your adapter assets on a server and use Background Assets to manage downloads. For hosting, you can use your own server or have Apple host your adapter assets. For more information about Apple-hosted asset packs, see Overview of Apple-hosted asset packs.

The Background Assets framework has a type of asset pack specific to adapters that you create for the Foundation Models framework. The Foundation Models adapter training toolkit helps you bundle your adapters in the correct asset pack format. The toolkit uses the ba-package command line tool that’s included with Xcode 16 or later. If you train your adapters on a Linux GPU machine, see How to train adapters to set up a Python environment on your Mac. The adapter toolkit includes example code that shows how to create the asset pack in the correct format.

After you generate an asset pack for each adapter, upload the asset packs to your server. For more information about uploading Apple-hosted adapters, see Upload Apple-Hosted asset packs.
Configure an asset-download target in Xcode

To download adapters at runtime, you need to add an asset-downloader extension target to your Xcode project:

    In Xcode, choose File > New > Target.

    Choose the Background Download template under the Application Extension section.

    Click next.

    Enter a descriptive name, like “AssetDownloader”, for the product name.

    Select the type of extension.

    Click Finish.

The type of extension depends on whether you self-host them or Apple hosts them:

Apple-Hosted, Managed

    Apple hosts your adapter assets.
Self-Hosted, Managed

    You use your server and make each device’s operating system automatically handle the download life cycle.
Self-Hosted, Unmanaged

    You use your server and manage the download life cycle.

After you create an asset-downloader extension target, check that your app target’s info property list contains the required fields specific to your extension type:

Apple-Hosted, Managed

    BAHasManagedAssetPacks = YES

    BAAppGroupID = The string ID of the app group that your app and downloader extension targets share.

    BAUsesAppleHosting = YES

Self-Hosted, Managed

    BAHasManagedAssetPacks = YES

    BAAppGroupID = The string ID of the app group that your app and downloader extension targets share.

If you use Self-Hosted, Unmanaged, then you don’t need additional keys. For more information about configuring background assets with an extension, see Configuring an unmanaged Background Assets project
Choose a compatible adapter at runtime

When you create an asset-downloader extension, Xcode generates a Swift file — BackgroundDownloadHandler.swift — that Background Assets uses to download your adapters. Open the Swift file in Xcode and fill in the code based on your target type. For Apple-Hosted, Managed or Self-Hosted, Managed extension types, complete the function shouldDownload with the following code that chooses an adapter asset compatible with the runtime device:

func shouldDownload(_ assetPack: AssetPack) -> Bool {
    // Check for any non-adapter assets your app has, like shaders. Remove the
    // check if your app doesn't have any non-adapter assets.
    if assetPack.id.hasPrefix("mygameshader") {
        // Return false to filter out asset packs, or true to allow download.
        return true
    }


    // Use the Foundation Models framework to check adapter compatibility with the runtime device.
    return SystemLanguageModel.Adapter.isCompatible(assetPack)
}

If your extension type is Self-Hosted, Unmanaged, the file Xcode generates has many functions in it for manual control over the download life cycle of your assets.
Load adapter assets in your app

After you configure an asset-downloader extension, you can start loading adapters. Before you download an adapter, remove any outdated adapters that might be on a person’s device:

SystemLanguageModel.Adapter.removeObsoleteAdapters()

Create an instance of SystemLanguageModel.Adapter using your adapter’s base name, but exclude the file extension. If a person’s device doesn’t have a compatible adapter downloaded, your asset-downloader extension starts downloading a compatible adapter asset pack:

let adapter = try SystemLanguageModel.Adapter(name: "myAdapter")

Initializing a SystemLanguageModel.Adapter starts a download automatically when a person launches your app for the first time or their device needs an updated adapter. Because adapters can have a large data size they can take some time to download, especially if a person is on Wi-Fi or a cell network. If a person doesn’t have a network connection, they aren’t able to use your adapter right away. This method shows how to track the download status of an adapter:

func checkAdapterDownload(name: String) async -> Bool {
    // Get the ID of the compatible adapter.
    let assetpackIDList = SystemLanguageModel.Adapter.compatibleAdapterIdentifiers(
        name: name
    )


    if let assetPackID = assetpackIDList.first {
        // Get the download status asynchronous sequence.
        let statusUpdates = AssetPackManager.shared.statusUpdates(forAssetPackWithID: assetPackID)


        // Use the current status to update any loading UI.
        for await status in statusUpdates {
            switch status {
            case .began(let assetPack):
                // The download started.
            case .paused(let assetPack):
                // The download is in a paused state.
            case .downloading(let assetPack, let progress):
                // The download in progress.
            case .finished(let assetPack):
                // The download is complete and the adapter is ready to use.
                return true
            case .failed(let assetPack, let error):
                // The download failed.
                return false
            @unknown default:
                // The download encountered an unknown status.
                fatalError()
            }
        }
    }
}

For more details on tracking downloads for general assets, see Downloading Apple-hosted asset packs.

Before you attempt to use the adapter, you need to wait for the status to be in a AssetPackManager.DownloadStatusUpdate.finished(_:) state. The system returns AssetPackManager.DownloadStatusUpdate.finished(_:) immediately if no download is necessary.

// Load the adapter.
let adapter = try SystemLanguageModel.Adapter(name: "myAdapter")


// Wait for download to complete.
if await checkAdapterDownload(name: "myAdapter") {
    // Adapt the base model with your adapter.
    let adaptedModel = SystemLanguageModel(adapter: adapter)
    
    // Start a session with the adapted model.
    let session = LanguageModelSession(model: adaptedModel)
    
    // Start prompting the adapted model.
}

Compile your draft model

A draft model is an optional step when training your adapter that can speed up inference. If your adapter includes a draft model, you can compile it for faster inference:

// Load the adapter.
let adapter = try SystemLanguageModel.Adapter(name: "myAdapter")


// Wait for download to complete.
if await checkAdapterDownload(name: "myAdapter") {
    do {
        // You can use your adapter without compiling the draft model, or during
        // compilation, but running inference with your adapter might be slower.
        try await adapter.compile()
    } catch let error {
        // Handle the draft model compilation error.
    }
}

For more about training draft models, see the “Optionally train the draft model” section in Get started with Foundation Models adapter training.

Compiling a draft model is a computationally expensive step, so use the Background Tasks framework to configure a background task for your app. In your background task, call compile() on your adapter to start compilation. For more information about using background tasks, see Using background tasks to update your app.

Compilation doesn’t run every time a person uses your app:

    The first time a device downloads a new version of your adapter, a call to compile() fully compiles your draft model and saves it to the device.

    During subsequent launches of your app, a call to compile() checks for a saved compiled draft model and returns it immediately if it exists.

Important

Rate limiting protects device resources that are shared between all apps and processes. If the framework determines that a new compilation is necessary, it rate-limits the compilation process on all platforms, excluding macOS, to three draft model compilations per-app, per-day.

The full compilation process runs every time you launch your app through Xcode because Xcode assigns your app a new UUID for every launch. If you receive a rate-limiting error while testing your app, stop your app in Xcode and re-launch it to reset the rate counter.
See Also
Loading the model with an adapter
com.apple.developer.foundation-model-adapter
A Boolean value that indicates whether the app can enable custom adapters for the Foundation Models framework.
convenience init(adapter: SystemLanguageModel.Adapter, guardrails: SystemLanguageModel.Guardrails)
Creates the base version of the model with an adapter.
struct Adapter
Specializes the system language model for custom use cases.
Current page is Loading and using a custom adapter with Foundation Models