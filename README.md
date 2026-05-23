# the-mighty-m10

Using e-waste to run large AI models locally with 2 Linux scripts.

![The Mighty M10 Workbench Rig](M10Rig.jpg)

## 1. MY RIG  
- **Project Directory**: [mightym10](https://webpagearea.com)  
- **GitHub Repository**: [the-mighty-m10](https://github.com)  
- **Motherboard**: Supermicro X9SCM‑F (LGA1155, Intel C204 Chipset, circa 2012)  
- **CPU**: Intel® Xeon® CPU E3‑1230 V2 @ 3.30 GHz  
- **Memory**: 32GB (Runs fine with 16GB) Server‑grade DDR3 ECC RAM (Ultra cost‑effective)
- **Graphics**: 3 × NVIDIA Tesla M10 (Maxwell architecture)  
  - Each card hosts 4 independent GM107 cores with 8 GB GDDR5 VRAM → 12 individual 8 GB GPU nodes (Total: 96 GB VRAM / \$225 GPU cost).
- **PSU**: [MSI MAG A750GL 750-Watt Power Supply](https://ebay.us)
- **Cooling**: [3D Printed Tesla M10 Fan Shrouds](https://ebay.com) running dedicated small cooling fans (One for each M10 card), powered by [OPSFALCON SATA to Dual 2-Pin Fan Adapter Splitter Cables](https://ebay.us).
- **Riser Topology**:  
  - [Mechanical PCI-E 8x to 16x Hard Riser Card Adapters](https://ebay.us) (For slot clearance stability)
  - [PCIe x16 Flexible Shielded Riser Cable 3.0](https://ebay.us) (For layout extension mapping)  
  - Slots 1 & 2: PCIe 3.0 ×8 | Bottom slot: PCIe 2.0 ×4 (System communication latency floor).  
- **Chassis**: [ATX Open Frame PC Test Bench Case](https://ebay.us) (DIY Component Rack)
- **OS & Drivers**: Linux Mint 21.3 (Virginia) | Kernel 5.15.0‑173‑generic | NVIDIA Driver 535.288.01 | CUDA 12.2

---

## 🛸 THE EXPERIMENT

The general consensus among hardware enthusiasts is that running massive large language models on twelve separate 8 GB legacy GPUs over a decade‑old motherboard is highly impractical, if not impossible. They are right on paper… but are they right? The mere fact that a 120 B model can successfully load and execute on this e‑waste was worth a serious investigation.  

The strategy is to turn the M10’s 4‑chip fragmentation into a strength by leveraging parallel processing across a 12‑core layout.

---

## 2. CORE WORKFLOW SCRIPTS  

### `startMyServer.sh`  
- Applies 30 W thermal clamps per core to control passive server card thermals.  
- Flushes conflicting background daemons and runtimes.  
- Arms `OLLAMA_SCHED_SPREAD=1` to force uniform layer distribution across all visible nodes.  
- Locks parameters into memory via `OLLAMA_KEEP_ALIVE=-1` to prevent mid-inference allocation crashes.

### `modelMaker.sh`  
- Evaluates registered model footprints.  
- Maps remaining system VRAM headroom.  
- Automatically compiles standalone configurations with customized token context and batch limits.

#### Standalone Execution Note  
To run a model standalone manually outside of the core automation loop, execute this direct acceleration string:  
```bash
OLLAMA_FLASH_ATTENTION=1 ollama run your-model-name-here
```

---

## 3. AUTOMATED BENCHMARKING & LOGGING  

### `benchy.sh`  
A bonus automation script for testing selected target models back‑to‑back.

```bash
./benchy.sh | tee benchmark.log
```

### Grep Extraction  
Filter results to view evaluation performance data from the log file:

```bash
grep -E "STARTING TEST FOR|eval rate:|Error" benchmark.log
```

---

## 4. BENCHMARK LOG DATA MATRIX  


| Modelfile Name | Model Name | Size (GB) | Prompt Rate (t/s) | Eval Rate (t/s) |
|:---|:---|:---|:---|:---|
| `siz008g-ctx32768-bat0512-tmp0.80-deepseek-coder-v2-16b:latest` | deepseek-coder-v2-16b | 8 | 21.06 | **12.38** |
| `siz007g-ctx32768-bat0512-tmp0.80-mistral-nemo-latest:latest` | mistral-nemo-latest | 7 | 4.13 | **9.93** |
| `siz013g-ctx32768-bat0512-tmp0.80-gpt-oss-20b:latest` | gpt-oss-20b | 13 | 18.71 | **8.14** |
| `siz023g-ctx32768-bat0512-tmp0.80-qwen3.5-35b:latest` | qwen3.5-35b | 23 | 15.52 | **6.47** |
| `siz065g-ctx16384-bat0512-tmp0.80-gpt-oss-120b:latest` | **gpt-oss-120b** | **65** | 10.00 | **5.83 🚀** |
| `siz026g-ctx32768-bat0512-tmp0.80-mixtral-8x7b:latest` | mixtral-8x7b | 26 | 3.43 | 4.32 |
| `siz014g-ctx32768-bat0512-tmp0.80-mistral-small-24b:latest` | mistral-small-24b | 14 | 5.45 | 3.92 |
| `siz019g-ctx32768-bat0512-tmp0.80-qwen2.5-coder-32b:latest` | qwen2.5-coder-32b | 19 | 1.49 | 2.77 |
| `siz081g-ctx04096-bat0512-tmp0.80-qwen3.5-122b-a10b:latest` | **qwen3.5-122b-a10b** | **81** | 4.64 | 2.71 |
| `siz017g-ctx32768-bat0512-tmp0.80-gemma3-27b:latest` | gemma3-27b | 17 | 2.67 | 2.36 |
| `siz019g-ctx32768-bat0512-tmp0.80-deepseek-r1-32b:latest` | deepseek-r1-32b | 19 | 0.87 | 1.38 |
| `siz020g-ctx32768-bat0512-tmp0.80-qwen3-32b:latest` | qwen3-32b | 20 | 2.30 | 1.36 |
| `siz067g-ctx08192-bat0512-tmp0.80-mixtral-8x22b-instruct-v0.1-q3_K_M:latest` | **mixtral-8x22b-instruct-v0.1-q3_K_M** | **67** | 0.83 | 1.26 |
| `siz042g-ctx32768-bat0512-tmp0.80-llama3.3-70b:latest` | **llama3.3-70b** | **42** | 0.89 | 1.18 |
| `siz042g-ctx32768-bat0512-tmp0.80-deepseek-r1-70b:latest` | **deepseek-r1-70b** | **42** | 0.76 | 0.58 |

---

## 🌌 Self-Documenting Proof of Concept

Look at the text you are reading right now. This README.md document was compiled, formatted, and written completely locally using the `gpt-oss:120b` model running directly on this exact 12‑core, e‑waste M10 server cluster. 

Demonstrating a 120B model documenting its own orchestration matrix serves as a clear proof of concept for this parallel layout.

### 📊 Live Generation Performance Logs

The raw verbose terminal output statistics dumped directly by Ollama upon completing this document generation run are tracked below:

```text
total duration:       11m41.238860622s
load duration:        309.069262ms
prompt eval count:    3545 token(s)
prompt eval duration: 1m42.193972426s
prompt eval rate:     34.69 tokens/s
eval count:           4593 token(s)
eval duration:        9m56.301730982s
eval rate:            7.70 tokens/s
```

---

## ⚖️ License & Disclosures
This project is open-source and licensed under the MIT License. 

*Disclaimer: As an eBay Partner, I earn from qualifying purchases made via the component overview links above at no additional cost to you. These tracking links directly fund components and cooling materials on the Transistor Corner testing workbench.*
cost to you. These tracking links directly fund components and cooling materials on the Transistor Corner testing workbench.*
