# AI Memory Tools for Agent Systems - Comprehensive Research Report

**Date**: December 2025
**Scope**: Memory solutions for 5 teams × 5 engineers (25 engineers total)
**Target Tools**: Claude Code, Open WebUI
**Requirements**: Self-hosted, Open Source, Free, Data Ownership

---

## Decision Summary

> **Recommended Tool: Basic Memory (Single Tool)**
>
> | Aspect | Decision |
> |--------|----------|
> | **Primary Tool** | Basic Memory |
> | **License** | AGPL-3.0 (safe for internal use) |
> | **Maturity** | 🟡 Medium - Trustworthy (6+ months, 15+ releases) |
> | **Architecture** | Single tool for both team + personal memory |
>
> **Why Basic Memory?**
> - ✅ Simplest stack - One tool, one MCP config for 25 engineers
> - ✅ Aligns with existing markdown workflow
> - ✅ Human-curable - All context is reviewable/editable
> - ✅ Native MCP - Works out-of-box with Claude Code
> - ✅ Meets all requirements - Self-hosted, open source, free, data ownership
>
> **If automatic learning needed later:** Add mcp-memory-service (Apache 2.0) as Layer 2
>
> **Why NOT others?**
> - Mem0: Most mature but no native MCP, complex setup
> - MemoryOS: Too new (only 3 releases, Jul 2025) - pilot only

---

## Executive Summary

This report analyzes memory tools for AI agents that meet your requirements: **fully self-hosted, open source, free, with data ownership**. The three tools you specifically requested (Basic Memory, Mem0, MemoryOS) are covered in depth, along with additional relevant options for completeness.

---

## 1. Tool Deep Dives

### 1.1 Basic Memory

| Attribute | Details |
|-----------|---------|
| **Repository** | github.com/basicmachines-co/basic-memory |
| **License** | AGPL-3.0 (copyleft) |
| **Architecture** | Knowledge Graph + Markdown Files + SQLite/PostgreSQL |
| **MCP Support** | ✅ Native |
| **Self-Hosted** | ✅ Full local deployment |
| **Storage** | Plain Markdown files (human-readable, portable) |

**How It Works:**
- Uses Entity-Observation-Relation model extracted from Markdown patterns
- Bidirectional sync between files and knowledge graph index
- Both humans AND AI can read/write the same knowledge base
- Semantic tagging with WikiLink-style connections (`[[Related Topic]]`)
- Full-text search across all notes

**Key Capabilities:**
- `write_note`, `read_note`, `edit_note`, `delete_note` - Content management
- `search` - Full-text queries across knowledge base
- `build_context` - Traverse knowledge graph for related information
- `canvas` - Generate visual knowledge maps
- Works with Obsidian, VS Code, Claude Desktop, Claude Code

**Strengths:**
- Human-readable Markdown = easy curation and backup
- No vendor lock-in (just files)
- Strong knowledge graph relationships
- Already works with your existing markdown workflow
- Native bidirectional AI-human collaboration

**Limitations:**
- No vector embeddings for similarity search (relies on graph traversal)
- AGPL license may require open-sourcing modifications
- Cloud sync is paid feature (but not required)

---

### 1.2 Mem0

| Attribute | Details |
|-----------|---------|
| **Repository** | github.com/mem0ai/mem0 |
| **License** | Apache 2.0 (permissive) |
| **Architecture** | Multi-level Memory (User/Session/Agent) + Vector DB |
| **MCP Support** | ❌ Not native (requires wrapper like mcp-mem0) |
| **Self-Hosted** | ✅ Full self-hosted option |
| **Storage** | 24+ vector database backends |

**How It Works:**
- Three-tier memory hierarchy: User (preferences), Session (context), Agent (state)
- LLM extracts facts from conversations automatically
- Semantic search via vector embeddings retrieves relevant memories
- Adaptive learning - memories evolve based on interaction patterns

**Key Capabilities:**
- `memory.add()` - Store memories from conversations
- `memory.search()` - Semantic similarity search
- `memory.get_all()` - Retrieve all memories for a user
- Multi-user isolation built-in
- Graph memory option for relationship tracking

**Supported Vector Databases (Self-Hosted Options):**
| Database | Self-Hosted | Notes |
|----------|-------------|-------|
| Qdrant | ✅ | Recommended for production |
| ChromaDB | ✅ | Lightweight, embedded |
| PostgreSQL (pgvector) | ✅ | If you already use Postgres |
| Milvus | ✅ | Kubernetes-native |
| Faiss | ✅ | Facebook's local vector search |
| Redis | ✅ | In-memory speed |

**Supported LLMs:**
- OpenAI, Anthropic, Ollama, vLLM, LM Studio (all self-hostable with open models)

**Performance Benchmarks:**
- 26% accuracy improvement over OpenAI Memory (LOCOMO benchmark)
- 91% faster responses than full-context approach
- 90% lower token usage

**Strengths:**
- Most mature ecosystem (Apache 2.0, production-proven)
- Massive backend flexibility (24+ vector DBs)
- Multi-level memory architecture mimics human memory
- Published research paper with benchmarks
- Framework integrations (LangChain, CrewAI, Vercel AI)

**Limitations:**
- No native MCP support (need mcp-mem0 wrapper)
- Requires LLM for fact extraction (cost/latency consideration)
- More complex setup than file-based solutions

---

### 1.3 MemoryOS (BAI-LAB)

| Attribute | Details |
|-----------|---------|
| **Repository** | github.com/BAI-LAB/MemoryOS |
| **License** | Apache 2.0 |
| **Architecture** | Hierarchical Memory with Heat Scoring |
| **MCP Support** | ✅ Native (MemoryOS-MCP) |
| **Self-Hosted** | ✅ Full local deployment |
| **Storage** | JSON files + ChromaDB option |

**How It Works:**
- Four-module system: Storage → Updating → Retrieval → Generation
- **Short-term memory**: Recent interactions (7-item default)
- **Mid-term memory**: Consolidated patterns with "heat scoring"
- **Long-term memory**: User profiles and knowledge base (100-item default)
- Heat scoring tracks interaction frequency to promote relevant info between layers

**Key MCP Tools:**
- `add_memory` - Persist conversation exchanges
- `retrieve_memory` - Query historical context, preferences, knowledge
- `get_user_profile` - Synthesized personality traits and interests

**Performance Benchmarks (vs baseline):**
- +49.11% F1 score improvement (LoCoMo benchmark)
- +46.18% BLEU-1 improvement
- 5x faster latency through parallelization (July 2025 update)

**Supported Backends:**
- File-based JSON (default)
- ChromaDB for vector search
- Embedding models: BAAI/bge-m3, Qwen3-Embedding, MiniLM

**Supported LLMs:**
- OpenAI, Anthropic Claude, Deepseek-R1, Qwen3, vLLM, Llama

**Strengths:**
- Academic pedigree (EMNLP 2025 oral presentation)
- Heat-based memory promotion is unique and effective
- Native MCP support with Claude Desktop, Cline, Cursor
- Hierarchical structure mimics human memory well
- Self-hosted with minimal dependencies

**Limitations:**
- Newer project (less production mileage)
- Playground requires invitation code
- Smaller community than Mem0

---

## 2. Additional Notable Tools

### 2.1 mcp-memory-service (doobidoo)

| Attribute | Details |
|-----------|---------|
| **Stars** | 894 |
| **License** | Apache 2.0 |
| **MCP Support** | ✅ Native |
| **Storage** | SQLite-vec (local) + Cloudflare (optional cloud) |

**Why Consider:**
- Most production-ready MCP memory server
- 5ms local reads via SQLite-vec
- Dream-inspired consolidation algorithms
- OAuth 2.1 for team collaboration
- 13+ AI application integrations
- Natural language time queries ("yesterday", "last week")

**Best For:** Teams wanting turnkey MCP memory with team features

---

### 2.2 Official MCP Memory Server

| Attribute | Details |
|-----------|---------|
| **Source** | modelcontextprotocol/servers |
| **License** | MIT |
| **Storage** | JSONL files |

**Architecture:** Simple Entity-Relation-Observation knowledge graph

**Why Consider:**
- Official reference implementation
- Minimal dependencies
- Good starting point for customization

**Limitations:** No vector search, basic feature set

---

### 2.3 MemOS (MemTensor) - Different from MemoryOS

| Attribute | Details |
|-----------|---------|
| **License** | Apache 2.0 |
| **MCP Support** | ✅ Native |

**Unique Features:**
- Multiple memory types: Textual, Activation (KV-cache), Parametric (LoRA weights)
- Claims superior benchmarks vs Mem0, Zep
- NebulaGraph integration

**Best For:** Advanced users wanting cutting-edge memory architectures

---

## 3. Comparison Tables

### 3.1 Core Requirements Compliance

| Tool | Self-Hosted | Open Source | Free | Data Ownership | License |
|------|-------------|-------------|------|----------------|---------|
| **Basic Memory** | ✅ | ✅ | ✅ | ✅ (Markdown files) | AGPL-3.0 |
| **Mem0** | ✅ | ✅ | ✅ | ✅ (Your vector DB) | Apache 2.0 |
| **MemoryOS** | ✅ | ✅ | ✅ | ✅ (JSON/ChromaDB) | Apache 2.0 |
| mcp-memory-service | ✅ | ✅ | ✅ | ✅ (SQLite) | Apache 2.0 |
| Official MCP Memory | ✅ | ✅ | ✅ | ✅ (JSONL) | MIT |

**All tools meet your core requirements.**

---

### 3.2 Technical Capabilities

| Feature | Basic Memory | Mem0 | MemoryOS |
|---------|--------------|------|----------|
| **MCP Native** | ✅ | ❌ (wrapper needed) | ✅ |
| **Vector/Semantic Search** | ❌ (graph-based) | ✅ | ✅ |
| **Knowledge Graph** | ✅ | ✅ (optional) | ❌ |
| **Human-Readable Storage** | ✅ (Markdown) | ❌ | ❌ |
| **Multi-Level Memory** | ❌ | ✅ | ✅ |
| **Heat/Decay Scoring** | ❌ | ❌ | ✅ |
| **User Isolation** | Via folders | ✅ Built-in | ✅ Built-in |
| **Team/Multi-User** | Via git | Via config | Via config |

---

### 3.3 Integration Support

| Tool | Claude Code | Claude Desktop | Open WebUI | VS Code | Cursor |
|------|-------------|----------------|------------|---------|--------|
| **Basic Memory** | ✅ | ✅ | ❓ (via MCP) | ✅ | ✅ |
| **Mem0** | Via wrapper | Via wrapper | ✅ (RAG) | Via wrapper | Via wrapper |
| **MemoryOS** | ✅ | ✅ | ❓ (via MCP) | ✅ (Cline) | ✅ |

**Open WebUI Integration Note:**
Open WebUI has built-in RAG support with 9 vector database backends. Mem0 could integrate via its API. Basic Memory and MemoryOS would need MCP integration which Open WebUI is developing.

---

### 3.4 Architecture Comparison

| Aspect | Basic Memory | Mem0 | MemoryOS |
|--------|--------------|------|----------|
| **Storage Model** | Files + SQLite index | Vector DB | JSON + ChromaDB |
| **Memory Structure** | Flat knowledge graph | User/Session/Agent tiers | Short/Mid/Long-term hierarchy |
| **Retrieval Method** | Graph traversal + full-text | Semantic similarity | Heat scoring + similarity |
| **Update Strategy** | Manual + AI writes | LLM extraction | FIFO + intelligent promotion |
| **Data Format** | Markdown | Embeddings | Structured JSON |

---

### 3.5 Maturity & Trustworthiness Assessment

| Metric | Basic Memory | Mem0 | MemoryOS |
|--------|--------------|------|----------|
| **GitHub Stars** | 2,200 | 25,000+ | 905 |
| **Forks** | 133 | 2,500+ | 82 |
| **Open Issues** | 44 | ~200 | 11 |
| **First Release** | Jul 2024 | Early 2024 | Jul 2025 |
| **Latest Version** | v0.16.2 (Nov 2024) | v1.0.0 (Oct 2024) | v1.2 (Jul 2025) |
| **Release Cadence** | Every 2-3 weeks | Every 7-10 days | Rapid (new project) |
| **Total Releases** | 15+ | 120+ | 3 |
| **Research Backing** | No | Yes (arXiv paper) | Yes (EMNLP 2025 oral) |
| **Corporate Backing** | Basic Machines Co | Mem0 AI (funded) | BAI-LAB (academic) |

### 3.6 Maturity Risk Assessment

| Tool | Maturity Level | Risk | Trust Recommendation |
|------|---------------|------|---------------------|
| **Basic Memory** | 🟡 **Medium** | Medium | ✅ **Trustworthy** - Active development, consistent releases, stable architecture |
| **Mem0** | 🟢 **High** | Low | ✅ **Highly Trustworthy** - Largest community, v1.0 stable, funded company |
| **MemoryOS** | 🔴 **Early** | Higher | ⚠️ **Emerging** - Very new (Jul 2025), but academic backing adds credibility |

#### Detailed Analysis:

**Basic Memory** 🟡
- **Strengths**: 6+ months of consistent releases, clear versioning, responsive to issues
- **Concerns**: Smaller team, AGPL license may limit enterprise adoption
- **Verdict**: Safe for production use in teams that value markdown workflow

**Mem0** 🟢
- **Strengths**: 120+ releases, 25K+ stars, funded company, v1.0 stability milestone
- **Concerns**: Complex ecosystem, requires vector DB infrastructure
- **Verdict**: Most battle-tested option, safe for enterprise

**MemoryOS** 🔴
- **Strengths**: Academic research backing (EMNLP 2025), GPG-signed commits, rapid fixes
- **Concerns**: Only 3 releases (all in July 2025), very new project
- **Verdict**: Promising but wait 3-6 months for stability OR pilot with small group

### 3.7 Maintenance & Longevity Signals

| Signal | Basic Memory | Mem0 | MemoryOS |
|--------|--------------|------|----------|
| **Bus Factor** | Low (small team) | High (funded company) | Medium (academic lab) |
| **Funding/Sustainability** | Commercial cloud offering | VC-backed | Academic grants |
| **Community Contributors** | Growing | 100+ contributors | Small team |
| **Breaking Changes Risk** | Low (file-based) | Medium (API evolution) | Higher (v1.x) |
| **Long-term Viability** | Good | Excellent | Uncertain |

---

## 4. Industry Trends (2025)

Based on research, the AI memory space is converging on several patterns:

### 4.1 Key Trends

1. **Hierarchical Memory is Standard**
   - Short-term (session), Mid-term (patterns), Long-term (profiles)
   - Mimics human cognitive architecture
   - Both Mem0 and MemoryOS implement this

2. **Vector Search is Table Stakes**
   - Semantic similarity ("find related") beats keyword search
   - ChromaDB, Qdrant, pgvector dominating self-hosted options

3. **MCP Adoption Accelerating**
   - Model Context Protocol becoming standard for tool integration
   - Native MCP support increasingly important

4. **Heat/Decay Scoring Emerging**
   - MemoryOS pioneering frequency-based memory promotion
   - Prevents stale memories from polluting context

5. **Memory as Competitive Advantage**
   - "Memory has become the new competitive layer in AI architecture"
   - 73% of AI projects use OpenAI, but memory differs

6. **Multi-Agent Memory Sharing**
   - JSON-based memory exchange between agents
   - Knowledge transfer across agent teams

---

## 5. Analysis Against Your Requirements

### Team Profile
- 5 teams × 5 engineers = 25 engineers
- Tools: Claude Code, Open WebUI
- Current: Markdown files
- Requirements: Self-hosted, Open Source, Free, Data Ownership

### Use Case Assessment

| Use Case | Best Fit | Rationale |
|----------|----------|-----------|
| **Curated knowledge bases** | Basic Memory | Markdown = human curation-friendly |
| **Automatic context learning** | Mem0 or MemoryOS | LLM-powered extraction |
| **Coding assistant memory** | Basic Memory or MemoryOS | Native MCP + Claude Code |
| **Cross-session personalization** | MemoryOS | Heat scoring for relevance |
| **Team knowledge sharing** | Basic Memory (git) | Version control + merge |
| **RAG with Open WebUI** | Mem0 | Vector DB integration |

---

## 6. Recommendation

### Option A: Single Tool (Simplified Stack) - **RECOMMENDED**

**Use Basic Memory for BOTH use cases**

| Use Case | How Basic Memory Handles It |
|----------|---------------------------|
| **Team Knowledge** | Shared git repo, markdown files, PR-reviewed updates |
| **Personal Memory** | Per-user folder/project within Basic Memory, same MCP interface |

**Why This Works:**
1. **One tool to learn** - Simpler onboarding for 25 engineers
2. **One MCP config** - Less complexity in Claude Code setup
3. **Unified workflow** - Same markdown format everywhere
4. **Git handles both** - Team repo + personal branches/forks
5. **Mature enough** - 6+ months of releases, stable architecture
6. **Human-curable** - Engineers can review ALL their context (team + personal)

**Trade-off:** Personal memory isn't "automatic" - engineers must consciously save notes. But this may be a feature, not a bug (no AI hallucinations polluting memory).

**Setup:**
```
~/basic-memory/
├── team/                 # Shared git repo (read-only for most)
│   ├── standards/
│   ├── architecture/
│   └── patterns/
└── personal/             # Per-engineer (their own repo/folder)
    ├── projects/
    ├── preferences/
    └── notes/
```

---

### Option B: Dual-Layer Architecture (If Automatic Learning Required)

If you **must have** automatic memory extraction for personal use:

| Layer | Scope | Update Pattern | Storage | Recommended Tool |
|-------|-------|----------------|---------|------------------|
| **Team Knowledge** | Shared across teams | Git-versioned, manual/LLM-assisted | Static markdown | **Basic Memory** |
| **Personal Memory** | Per-user | Automatic, learns from usage | Dynamic, per-user DB | **mcp-memory-service** ⭐ |

**Why mcp-memory-service over MemoryOS for Layer 2:**
- More mature (894 stars vs 905, but much longer release history)
- Production-tested with OAuth 2.1 for teams
- Native MCP (no wrapper needed)
- Apache 2.0 license (vs MemoryOS which is also Apache 2.0 but newer)

---

### Detailed Analysis: Option A (Single Tool)

#### Layer 1: Team Knowledge → **Basic Memory**

**Rationale:**
1. **Aligns with your existing workflow** - You already use markdown files
2. **Human-curable** - Engineers can review, edit, organize knowledge directly
3. **Native MCP support** - Works out-of-box with Claude Code
4. **Git-based collaboration** - Version control, PRs for knowledge updates
5. **LLM-assisted writing** - Engineers use AI to draft, then commit
6. **Data ownership** - Plain files you control completely

**Use For:**
- Team coding standards and conventions
- Architecture documentation
- Common patterns and solutions
- Onboarding knowledge
- Project-specific context

---

### Layer 2: Personal Memory → **MemoryOS** (Optional Enhancement)

**Rationale:**
1. **Per-user isolation** - Each engineer has their own memory
2. **Automatic learning** - Extracts facts from conversations without manual effort
3. **Heat-based prioritization** - Surfaces frequently-used context
4. **Native MCP support** - Works alongside Basic Memory in Claude Code
5. **Academic backing** - EMNLP 2025 research with strong benchmarks

**Use For:**
- Individual preferences and patterns
- Personal project history
- Conversation continuity across sessions
- Personalized AI assistant behavior

**Note:** This layer is optional but addresses the "personal AI assistant" use case you mentioned.

**⚠️ Maturity Warning for MemoryOS:**
MemoryOS is very new (first release July 2025, only 3 releases total). While it has academic backing, consider:
- **Option A**: Pilot with 2-3 engineers first, evaluate for 3-6 months before wider rollout
- **Option B**: Use **mcp-memory-service** as a more mature alternative (Apache 2.0, 894 stars, production-ready)
- **Option C**: Use **Mem0** with mcp-mem0 wrapper if maturity is critical

---

### Alternative Personal Memory Options

If MemoryOS doesn't fit, consider these open-source alternatives:

| Tool | License | Notes |
|------|---------|-------|
| **mcp-memory-service** | Apache 2.0 | Most production-ready, OAuth for teams |
| **Mem0** (self-hosted) | Apache 2.0 | Requires mcp-mem0 wrapper, excellent docs |
| **MemOS (MemTensor)** | Apache 2.0 | Cutting-edge, claims better benchmarks |
| **OpenMemory** | Open Source | Zero-config MCP endpoint, semantic storage |

---

### Why This Architecture Works

```
┌─────────────────────────────────────────────────────────┐
│                    Claude Code / Open WebUI             │
├─────────────────────────────────────────────────────────┤
│                         MCP Layer                       │
├───────────────────────┬─────────────────────────────────┤
│   Basic Memory (Team) │    MemoryOS (Personal)          │
│   - Git-versioned     │    - Per-user DB                │
│   - Markdown files    │    - Auto-learning              │
│   - Manual curation   │    - Heat scoring               │
│   - Shared knowledge  │    - User profiling             │
└───────────────────────┴─────────────────────────────────┘
```

**Benefits:**
- Clear separation of concerns
- Team knowledge stays authoritative and reviewed
- Personal memory adapts without polluting team data
- Both use MCP = unified interface for Claude Code
- Can roll out Layer 2 later without changing Layer 1

---

## 7. Implementation Roadmap

### Phase 1: Team Knowledge Layer (Week 1-2)
**Goal:** Deploy Basic Memory for shared team knowledge

1. Install Basic Memory on shared server
2. Configure MCP integration for Claude Code across teams
3. Set up git repository for knowledge base
4. Migrate existing markdown files to Basic Memory format
5. Train engineers on observation/relation syntax (`[category] fact #tag`)
6. Establish naming conventions and folder structure

### Phase 2: Team Workflow Refinement (Week 3-4)
**Goal:** Establish sustainable knowledge curation practices

1. Create team-specific knowledge projects
2. Document best practices for AI-assisted note creation
3. Set up PR review process for knowledge updates
4. Create templates for common knowledge types
5. Gather initial feedback and adjust

### Phase 3: Personal Memory Pilot (Month 2) - Optional
**Goal:** Evaluate per-user memory for interested engineers

1. Deploy MemoryOS for volunteer pilot group (5-10 engineers)
2. Configure per-user isolation
3. Document personal memory best practices
4. Gather feedback on automatic learning quality
5. Assess if heat-based prioritization adds value

### Phase 4: Full Rollout (Month 3+)
**Goal:** Based on pilot results, expand personal memory

1. If positive: Roll out MemoryOS to remaining engineers
2. Create unified MCP configuration supporting both layers
3. Document guidelines for what goes where (team vs personal)
4. Monitor and optimize memory retrieval quality

---

## 8. Summary

### Tool Comparison by Criterion

| Criterion | Winner | Notes |
|-----------|--------|-------|
| **Team knowledge (static, curated)** | Basic Memory | Git-versioned markdown |
| **Personal memory (dynamic, auto)** | mcp-memory-service | Most mature auto-learning MCP server |
| **Best semantic search** | Mem0 | 24+ vector DB backends |
| **Best team collaboration** | Basic Memory | Git-native workflow |
| **Best research backing** | MemoryOS | EMNLP 2025 oral |
| **Best production maturity** | Mem0 | 25k+ stars, widely used |
| **Best MCP integration** | Basic Memory | Native, simple config |
| **Easiest self-hosting** | Basic Memory | Just files + SQLite |
| **Simplest overall stack** | Basic Memory | One tool for both use cases |

### License Summary

| Tool | License | Implications |
|------|---------|--------------|
| **Basic Memory** | **AGPL-3.0** | Copyleft - modifications must be open-sourced if distributed |
| **Mem0** | **Apache 2.0** | Permissive - commercial use OK, no copyleft |
| **MemoryOS** | **Apache 2.0** | Permissive - commercial use OK, no copyleft |
| **mcp-memory-service** | **Apache 2.0** | Permissive - commercial use OK, no copyleft |
| **Official MCP Memory** | **MIT** | Most permissive - minimal restrictions |

**License Note for Basic Memory (AGPL-3.0):**
- ✅ Safe for internal team use (no distribution)
- ✅ Safe as MCP server (network use typically doesn't trigger copyleft)
- ⚠️ If you modify and distribute the tool itself, modifications must be open-sourced
- For most enterprise internal use, AGPL is not a blocker

### Final Recommendation: **Basic Memory (Single Tool)**

| Use Case | Implementation |
|----------|---------------|
| **Team Knowledge** | Shared git repo with PR review process |
| **Personal Memory** | Per-user folders within same Basic Memory instance |

**Why Single Tool is Best:**
1. **Simpler stack** - One tool, one MCP config, one workflow
2. **Lower training burden** - 25 engineers learn one system
3. **Human-curable everywhere** - All context is reviewable markdown
4. **Meets all requirements** - Self-hosted, open source, free, data ownership
5. **Mature enough** - 6+ months of consistent releases

**If automatic learning becomes critical later:**
- Add **mcp-memory-service** as Layer 2 (Apache 2.0, most production-ready)
- Both work via MCP, can coexist without conflicts

---

## Appendix: Quick Reference

### Installation Commands

**Basic Memory:**
```bash
uv tool install basic-memory
basic-memory sync --watch
```

**MemoryOS:**
```bash
pip install memoryos-pro
# Configure via JSON config file
```

**Mem0:**
```bash
pip install mem0ai
# Requires vector DB setup (ChromaDB, Qdrant, etc.)
```

### MCP Configuration (Claude Code)

**Basic Memory:**
```json
{
  "mcpServers": {
    "basic-memory": {
      "command": "basic-memory",
      "args": ["mcp"]
    }
  }
}
```

**MemoryOS:**
```json
{
  "mcpServers": {
    "memoryos": {
      "command": "python",
      "args": ["-m", "memoryos.mcp"]
    }
  }
}
```
