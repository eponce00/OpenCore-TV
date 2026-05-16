# OpenCore Wallpaper Catalog

Wallpapers are stored in folders for easy browsing. `assets/wallpapers/catalog.json` is the small offline catalog bundled in the APK, while `assets/wallpapers/remote-catalog.json` is fetched from GitHub raw when the TV has internet.

Recommended structure:

```text
assets/wallpapers/
  catalog.json
  dark/
  light/
```

Catalog fields:

- `id`: stable wallpaper id.
- `asset`: Flutter asset path for offline bundled entries.
- `url`: GitHub raw URL for online entries.
- `brightness`: `dark` or `light`.
- `categories`: flexible tags such as `art`, `earth`, `city`, `space`, or `minimal`.
- `default`: optional default for the active bucket.

The current APK bundles 10 full-resolution WebP wallpapers: 5 dark and 5 light. The larger library stays in the repo as high-quality WebP files and is exposed through `remote-catalog.json`; selected online wallpapers are cached in app storage after the first download.

Appearance modes:

- `Dark`: always use dark UI/wallpaper bucket.
- `Light`: use light UI/wallpaper bucket, falling back to dark wallpapers if empty.
- `Auto: room light`: use the TV ambient light sensor when available.
- `Auto: sunrise/sunset`: use the configured weather location's sunrise and sunset times.

## fal.ai Generation Helper

Use `scripts/generate-wallpapers.ps1` to discover fal text-to-image models or generate new bundled wallpapers. Keep the API key in the shell environment; do not commit it.

```powershell
$env:FAL_KEY = "<fal key>"
.\scripts\generate-wallpapers.ps1 -Mode List4kModels
.\scripts\generate-wallpapers.ps1 -Mode SearchModels -Search "gpt-image-2 flux-2 imagen4 seedream qwen kling recraft"
```

Dry-run a generation request before spending credits:

```powershell
.\scripts\generate-wallpapers.ps1 `
  -Prompt "Matte black painted field with deep pine green diagonal oil strokes, small ochre marks near center, thick raised impasto ridges, visible bristle texture, no text" `
  -Brightness dark `
  -Categories art,minimal `
  -DryRun
```

Generate and add the downloaded image to `assets/wallpapers/catalog.json`:

```powershell
.\scripts\generate-wallpapers.ps1 `
  -Prompt "White plaster facade in daylight, warm white wall plane, soft gray rectangular shadow at lower left, pale limestone trim, fine limewash texture, clean geometric composition, no text" `
  -Brightness light `
  -Categories art,minimal `
  -Model fal-ai/nano-banana-2 `
  -Count 4
```

Generate the curated Kling wallpaper library from `assets/wallpapers/prompt-library.json`:

```powershell
$env:FAL_KEY = "<fal key>"
.\scripts\generate-wallpaper-library.ps1 -DryRun
.\scripts\generate-wallpaper-library.ps1
```

Useful smaller batches:

```powershell
.\scripts\generate-wallpaper-library.ps1 -Category earth -Theme dark
.\scripts\generate-wallpaper-library.ps1 -Category fine_art -Theme clear
.\scripts\generate-wallpaper-library.ps1 -Theme clear -LimitPerCategoryTheme 3
```

The prompt library currently contains 4 broad categories (`earth`, `fine_art`, `abstract_art`, `architecture`) with 10 `dark` and 10 `clear` prompts each. Tulips and floral subjects live inside the broader fine-art and abstract prompts rather than as their own top-level category. `clear` prompts are saved as light wallpapers in `assets/wallpapers/light`.

The API model listing currently exposes these explicit 4K text-to-image price notes:

- `fal-ai/nano-banana-2`: $0.08 per standard image; 4K is 2x, roughly $0.16 per image.
- `fal-ai/nano-banana-pro`: $0.15 per standard image; 4K is 2x, roughly $0.30 per image.
- `fal-ai/gemini-3.1-flash-image-preview`: $0.08 per standard image; 4K is 2x, roughly $0.16 per image.
- `fal-ai/gemini-3-pro-image-preview`: $0.15 per standard image; 4K is 2x, roughly $0.30 per image.
- `fal-ai/kling-image/o3/text-to-image`: $0.028 for 1K/2K; 4K is double, roughly $0.056 per image.
- `fal-ai/phota`: $0.09 per 1K image; $0.18 per 4K image.

The broader API-derived wallpaper candidate list also includes models whose listing does not literally say `4K`, but whose family is worth checking for large wallpaper generation:

- `openai/gpt-image-2`: token priced. Text tokens are $5 input / $1.25 cached / $10 output per 1M. Image tokens are $8 input / $2 cached / $30 output per 1M. fal notes that `quality` significantly affects cost and defaults to `high`.
- `fal-ai/flux-2-max`: first processed megapixel is $0.07; each additional megapixel is $0.03.
- `fal-ai/flux-2-pro`: first megapixel is $0.03; additional input/output megapixels are $0.015 each, rounded up.
- `fal-ai/qwen-image-2512`: $0.02 per megapixel, rounded up.
- `fal-ai/ernie-image`: $0.03 per megapixel. `fal-ai/ernie-image/turbo` is $0.01 per megapixel.
- `fal-ai/gpt-image-1.5`: size/quality based. The API listing gives high quality examples at $0.133 for 1024x1024, about $0.20 for 1024x1536 / 1536x1024.
- `fal-ai/minimax/image-01`: $0.01 per image.
- `xai/grok-imagine-image/quality/text-to-image`: $0.05 per 1K image, $0.07 per 2K image.

Several newer Explore entries, including Imagen 4, Seedream 5 Lite, Qwen Image 2 Pro, and Recraft V4.1 Pro, appear in fal's model API without explicit price text. Use `-Mode SearchModels` before a large batch and dry-run the chosen endpoint payload first.
