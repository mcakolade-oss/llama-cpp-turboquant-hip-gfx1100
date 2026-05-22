# llama.cpp TurboQuant HIP/ROCm on AMD Radeon RX 7900 XTX

Community notes for building and running
[`TheTom/llama-cpp-turboquant`](https://github.com/TheTom/llama-cpp-turboquant)
on Windows with AMD HIP/ROCm acceleration for the Radeon RX 7900 XTX.

The RX 7900 XTX is an RDNA 3 card and uses the `gfx1100` AMDGPU target.

## Scope

This repository is a guide plus small launcher templates. It does not
redistribute:

- llama.cpp binaries
- AMD ROCm runtime files
- GGUF model files
- vendor SDK installers or wheels

That keeps the repo small, auditable, and easier to maintain. Build the binaries
locally from the upstream source repositories.

## Tested Setup

The notes here were validated on:

- Windows
- AMD Radeon RX 7900 XTX
- HIP/ROCm backend
- `gfx1100` GPU target
- llama.cpp server with the embedded web UI enabled

Other RDNA 3 GPUs may work with a different target, but this guide is written
specifically for `gfx1100`.

## Prerequisites

Install or prepare:

- Visual Studio 2022 Build Tools with C++ tools
- CMake
- Ninja
- Git
- AMD HIP/ROCm SDK/runtime for Windows
- A GGUF model file

You should be able to run the ROCm tools and see your GPU before building. For
example, `hipInfo.exe` should report an AMD GPU.

## Source Repositories

Clone the upstream project:

```powershell
git clone https://github.com/TheTom/llama-cpp-turboquant.git
cd llama-cpp-turboquant
```

If you also need the related TurboQuant repository:

```powershell
git clone https://github.com/TheTom/turboquant_plus.git
```

## Build Notes

The important options for this GPU are:

- Enable HIP/ROCm
- Target `gfx1100`
- Build the server
- Build the embedded UI if you want `http://127.0.0.1:8080/` to show the web UI

Example CMake configuration:

```powershell
$env:HIP_PATH = "C:\path\to\rocm"
$env:ROCM_PATH = "C:\path\to\rocm"

cmake -S . -B build-hip-gfx1100 -G Ninja `
  -DCMAKE_BUILD_TYPE=Release `
  -DGGML_HIP=ON `
  -DAMDGPU_TARGETS=gfx1100 `
  -DLLAMA_BUILD_SERVER=ON `
  -DLLAMA_BUILD_UI=ON

cmake --build build-hip-gfx1100 --config Release
```

Depending on your ROCm SDK layout, you may also need to point CMake at AMD clang
and the ROCm device bitcode directory. Use the upstream build output as the
source of truth if option names change.

## Package Layout

A convenient local package layout is:

```text
llama-cpp-turboquant-hip-gfx1100/
  bin/
    llama-server.exe
    llama-cli.exe
    llama-completion.exe
    ...
  rocm/
    bin/
      AMD/ROCm runtime DLLs
  llama-server-hip.cmd
  llama-hip.cmd
```

The launchers in this repository assume that layout.

## Start the Server

From PowerShell:

```powershell
C:\path\to\llama-cpp-turboquant-hip-gfx1100\llama-server-hip.cmd `
  -m C:\path\to\model.gguf `
  -ngl 99 `
  --host 127.0.0.1 `
  --port 8080 `
  --no-warmup
```

Open the web UI:

```text
http://127.0.0.1:8080/
```

OpenAI-compatible API base URL:

```text
http://127.0.0.1:8080/v1
```

## Test the API from PowerShell

Windows PowerShell aliases `curl` to `Invoke-WebRequest`, so
`Invoke-RestMethod` is usually clearer:

```powershell
Invoke-RestMethod `
  -Uri http://127.0.0.1:8080/v1/chat/completions `
  -Method Post `
  -ContentType "application/json" `
  -Body '{ "model": "local", "messages": [ { "role": "user", "content": "Say hello in one sentence." } ], "max_tokens": 80 }'
```

If you want real curl, call `curl.exe` explicitly:

```powershell
curl.exe http://127.0.0.1:8080/v1/chat/completions `
  -H "Content-Type: application/json" `
  -d '{ "model": "local", "messages": [ { "role": "user", "content": "Say hello in one sentence." } ], "max_tokens": 80 }'
```

## Cursor or OpenAI-Compatible Clients

Use:

- Base URL: `http://127.0.0.1:8080/v1`
- API key: any placeholder value, for example `sk-local`
- Model: `local`, or the model name reported by the server

Use `/v1` for API clients. Use `/` for the browser UI.

## CLI Completion

```powershell
C:\path\to\llama-cpp-turboquant-hip-gfx1100\bin\llama-completion.exe `
  -m C:\path\to\model.gguf `
  -p "Say hello in one short sentence." `
  -n 32 `
  -ngl 99 `
  --no-warmup `
  --simple-io
```

## Expected GPU Detection

When the server starts successfully, the logs should show a ROCm device similar
to:

```text
ROCm0 : AMD Radeon RX 7900 XTX
```

Performance varies by model, quantization, context size, driver version, and
system power/thermal limits.

## Troubleshooting

### PowerShell cannot find the launcher

If you are already inside the package folder, prefix the launcher with `.\`:

```powershell
.\llama-server-hip.cmd -m C:\path\to\model.gguf -ngl 99
```

From another folder, use the full path:

```powershell
C:\path\to\llama-cpp-turboquant-hip-gfx1100\llama-server-hip.cmd -m C:\path\to\model.gguf -ngl 99
```

### The browser UI is blank

The server may have been built without the embedded UI. Rebuild with:

```text
LLAMA_BUILD_UI=ON
```

The API can still work at `/v1` even if the root page is blank.

### The model fails to load

Make sure `-m` points to a real `.gguf` file:

```powershell
-m C:\path\to\your-model.gguf
```

LM Studio models are commonly stored under:

```text
C:\Users\<you>\.lmstudio\models
```

### ROCm cleanup fails on Windows

Some ROCm SDK packages contain deeply nested sample paths. If Windows refuses to
delete an SDK extraction directory, use an Administrator PowerShell and shorten
the path with `subst`:

```powershell
$target = "C:\path\to\cleanup-folder"

takeown /F $target /R /D Y
icacls $target /grant "$env:USERNAME:(OI)(CI)F" /T /C

subst Z: $target
cmd /c "rmdir /s /q Z:\rocm-sdk-7.2.1"
subst Z: /D

Remove-Item -LiteralPath $target -Force
```

## Credits

This guide builds on work from:

- [`TheTom/llama-cpp-turboquant`](https://github.com/TheTom/llama-cpp-turboquant)
- [`TheTom/turboquant_plus`](https://github.com/TheTom/turboquant_plus)
- [`ggml-org/llama.cpp`](https://github.com/ggml-org/llama.cpp)
