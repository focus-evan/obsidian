#!/usr/bin/env python3
"""Build, search, and evaluate a local traceable lexical RAG index.

This is the first-stage retrieval layer for AI-KnowledgeHub. It deliberately
does not claim to be a vector embedding service. Only approved knowledge
objects are indexed, and every result keeps its vault-relative source path.
"""

from __future__ import annotations

import argparse
import collections
import datetime as dt
import hashlib
import json
import math
import re
import sys
from pathlib import Path


APPROVED_TYPES = {
    "knowledge-note",
    "process",
    "runbook",
    "architecture",
    "investment-framework",
}
INDEX_METHOD = "local-bm25-char-ngram"

if sys.platform == "win32" and hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")


def parse_frontmatter(text: str) -> tuple[dict[str, str], str]:
    match = re.match(r"\A---\r?\n([\s\S]*?)\r?\n---\r?\n([\s\S]*)\Z", text)
    if not match:
        return {}, text
    props: dict[str, str] = {}
    for line in match.group(1).splitlines():
        item = re.match(r"^([A-Za-z0-9_-]+):\s*(.*?)\s*$", line)
        if item:
            props[item.group(1)] = item.group(2).strip(" '\"")
    return props, match.group(2)


def update_frontmatter(path: Path, updates: dict[str, str]) -> None:
    text = path.read_text(encoding="utf-8-sig")
    match = re.match(r"\A---\r?\n([\s\S]*?)\r?\n---\r?\n([\s\S]*)\Z", text)
    if not match:
        return
    frontmatter = match.group(1)
    for key, value in updates.items():
        pattern = re.compile(rf"(?m)^{re.escape(key)}:\s*.*$")
        line = f"{key}: {value}"
        if pattern.search(frontmatter):
            frontmatter = pattern.sub(line, frontmatter, count=1)
        else:
            frontmatter = frontmatter.rstrip() + "\n" + line
    path.write_text(f"---\n{frontmatter.strip()}\n---\n{match.group(2)}", encoding="utf-8")


def tokenize(text: str) -> list[str]:
    text = text.lower()
    tokens = re.findall(r"[a-z0-9][a-z0-9_.+-]*", text)
    chinese_runs = re.findall(r"[\u4e00-\u9fff]+", text)
    for run in chinese_runs:
        tokens.extend(run)
        tokens.extend(run[index : index + 2] for index in range(max(0, len(run) - 1)))
        if len(run) >= 3:
            tokens.extend(run[index : index + 3] for index in range(len(run) - 2))
    return tokens


def strip_markdown(text: str) -> str:
    # Keep code-block content because workflow states and field names often live
    # inside fenced examples; remove only the fence markers/language label.
    text = re.sub(r"(?m)^```[^\r\n]*\r?\n?", " ", text)
    text = re.sub(r"!?(\[\[)(.*?)(\]\])", r"\2", text)
    text = re.sub(r"`([^`]+)`", r"\1", text)
    text = re.sub(r"https?://\S+", " ", text)
    return re.sub(r"\s+", " ", text).strip()


def chunk_note(relative_path: str, body: str, max_chars: int = 1200) -> list[dict[str, str]]:
    title_match = re.search(r"(?m)^#\s+(.+)$", body)
    title = title_match.group(1).strip() if title_match else Path(relative_path).stem
    sections = re.split(r"(?m)^(?=#{2,3}\s+)", body)
    chunks: list[dict[str, str]] = []
    for section in sections:
        heading_match = re.match(r"^#{2,3}\s+(.+)$", section.splitlines()[0]) if section.splitlines() else None
        heading = heading_match.group(1).strip() if heading_match else title
        cleaned = strip_markdown(section)
        if not cleaned:
            continue
        for start in range(0, len(cleaned), max_chars):
            piece = cleaned[start : start + max_chars]
            if len(piece) < 40 and chunks:
                chunks[-1]["text"] += " " + piece
                continue
            chunks.append(
                {
                    "source": relative_path.replace("\\", "/"),
                    "title": title,
                    "heading": heading,
                    "text": piece,
                }
            )
    for index, chunk in enumerate(chunks):
        raw_id = f"{relative_path}|{index}|{chunk['text']}".encode("utf-8")
        chunk["chunk_id"] = hashlib.sha256(raw_id).hexdigest()[:20]
    return chunks


def approved_sources(vault: Path) -> list[Path]:
    result: list[Path] = []
    for path in vault.rglob("*.md"):
        if any(part in {".obsidian", "01_个人空间", "_templates"} for part in path.relative_to(vault).parts):
            continue
        text = path.read_text(encoding="utf-8-sig", errors="replace")
        props, _ = parse_frontmatter(text)
        if props.get("type") not in APPROVED_TYPES:
            continue
        if props.get("review_status") != "approved":
            continue
        if props.get("confidential_level") in {"private", "secret", "restricted"}:
            continue
        result.append(path)
    return sorted(result)


def build(vault: Path) -> dict[str, object]:
    index_dir = vault / "_rag" / "index"
    index_dir.mkdir(parents=True, exist_ok=True)
    chunks: list[dict[str, str]] = []
    sources = approved_sources(vault)
    indexed_at = dt.datetime.now().astimezone().isoformat(timespec="seconds")
    for path in sources:
        relative = str(path.relative_to(vault))
        _, body = parse_frontmatter(path.read_text(encoding="utf-8-sig"))
        chunks.extend(chunk_note(relative, body))

    chunks_path = index_dir / "knowledge_chunks.jsonl"
    with chunks_path.open("w", encoding="utf-8", newline="\n") as handle:
        for chunk in chunks:
            handle.write(json.dumps(chunk, ensure_ascii=False) + "\n")

    meta = {
        "index_method": INDEX_METHOD,
        "semantic_embeddings": False,
        "built_at": indexed_at,
        "source_count": len(sources),
        "chunk_count": len(chunks),
        "chunks_sha256": hashlib.sha256(chunks_path.read_bytes()).hexdigest(),
    }
    (index_dir / "index_meta.json").write_text(
        json.dumps(meta, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    for path in sources:
        update_frontmatter(
            path,
            {
                "rag_status": "indexed",
                "index_method": INDEX_METHOD,
                "indexed_at": indexed_at,
            },
        )
    return meta


def load_chunks(vault: Path) -> list[dict[str, str]]:
    chunks_path = vault / "_rag" / "index" / "knowledge_chunks.jsonl"
    if not chunks_path.exists():
        raise SystemExit("Index missing. Run: local_rag.py build")
    return [json.loads(line) for line in chunks_path.read_text(encoding="utf-8").splitlines() if line.strip()]


def rank(query: str, chunks: list[dict[str, str]], top_k: int = 5) -> list[dict[str, object]]:
    documents: list[tuple[dict[str, str], collections.Counter[str]]] = []
    document_frequency: collections.Counter[str] = collections.Counter()
    for chunk in chunks:
        weighted_text = f"{chunk['title']} {chunk['title']} {chunk['heading']} {chunk['text']}"
        counts = collections.Counter(tokenize(weighted_text))
        documents.append((chunk, counts))
        document_frequency.update(counts.keys())
    if not documents:
        return []
    query_tokens = tokenize(query)
    average_length = sum(sum(counts.values()) for _, counts in documents) / len(documents)
    scored: list[dict[str, object]] = []
    for chunk, counts in documents:
        doc_length = sum(counts.values())
        score = 0.0
        for token in query_tokens:
            frequency = counts.get(token, 0)
            if not frequency:
                continue
            df = document_frequency[token]
            inverse = math.log(1 + (len(documents) - df + 0.5) / (df + 0.5))
            score += inverse * (frequency * 2.2) / (
                frequency + 1.2 * (1 - 0.75 + 0.75 * doc_length / average_length)
            )
        if score > 0:
            scored.append({**chunk, "score": round(score, 6)})
    scored.sort(key=lambda item: item["score"], reverse=True)
    return scored[:top_k]


def search(vault: Path, query: str, top_k: int) -> list[dict[str, object]]:
    return rank(query, load_chunks(vault), top_k)


def evaluate(vault: Path, cases_path: Path, top_k: int = 5) -> dict[str, object]:
    chunks = load_chunks(vault)
    cases = [json.loads(line) for line in cases_path.read_text(encoding="utf-8").splitlines() if line.strip()]
    results = []
    hit_sources: set[str] = set()
    for case in cases:
        ranked = rank(case["question"], chunks, top_k)
        sources = [item["source"] for item in ranked]
        hit = case["expected_source"].replace("\\", "/") in sources
        if hit:
            hit_sources.add(case["expected_source"].replace("\\", "/"))
        results.append({**case, "hit": hit, "retrieved_sources": sources})
    hit_count = sum(1 for item in results if item["hit"])
    hit_rate = hit_count / len(results) if results else 0.0
    evaluated_at = dt.datetime.now().astimezone().isoformat(timespec="seconds")
    report = {
        "evaluated_at": evaluated_at,
        "index_method": INDEX_METHOD,
        "semantic_embeddings": False,
        "top_k": top_k,
        "case_count": len(results),
        "hit_count": hit_count,
        "hit_rate": round(hit_rate, 4),
        "results": results,
    }
    eval_dir = vault / "_rag" / "evals"
    eval_dir.mkdir(parents=True, exist_ok=True)
    (eval_dir / "latest_retrieval_eval.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    misses = [item for item in results if not item["hit"]]
    markdown = [
        "---",
        "type: eval",
        "domain: rag",
        "status: active",
        f"updated: {evaluated_at[:10]}",
        "tags:",
        "  - system/eval",
        "  - system/rag",
        "---",
        "# 本地RAG检索评测",
        "",
        f"- 检索方法：`{INDEX_METHOD}`",
        "- 语义向量：未启用",
        f"- 问题数：{len(results)}",
        f"- Hit@{top_k}：{hit_count}/{len(results)}（{hit_rate:.1%}）",
        "",
        "## 未命中",
        "",
    ]
    if misses:
        markdown.extend(f"- {item['question']} → `{item['expected_source']}`" for item in misses)
    else:
        markdown.append("- 无")
    markdown.extend(
        [
            "",
            "## 解释边界",
            "",
            "本评测只验证本地字符 n-gram/BM25 检索能否找到预期来源，不等价于答案事实正确率，也不代表已经完成向量嵌入评测。",
            "",
        ]
    )
    (eval_dir / "latest_retrieval_eval.md").write_text("\n".join(markdown), encoding="utf-8")

    if hit_rate >= 0.95:
        for source in sorted(hit_sources):
            path = vault / Path(source)
            if path.exists():
                update_frontmatter(
                    path,
                    {
                        "rag_status": "evaluated",
                        "evaluated_at": evaluated_at,
                        "retrieval_hit_rate": f"{hit_rate:.4f}",
                    },
                )
    return report


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--vault", default=r"D:\Evan\AI-KnowledgeHub")
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("build")
    search_parser = sub.add_parser("search")
    search_parser.add_argument("query")
    search_parser.add_argument("--top-k", type=int, default=5)
    eval_parser = sub.add_parser("evaluate")
    eval_parser.add_argument("--cases", default="_rag/evals/retrieval_cases.jsonl")
    eval_parser.add_argument("--top-k", type=int, default=5)
    args = parser.parse_args()
    vault = Path(args.vault)
    if args.command == "build":
        print(json.dumps(build(vault), ensure_ascii=False, indent=2))
    elif args.command == "search":
        print(json.dumps(search(vault, args.query, args.top_k), ensure_ascii=False, indent=2))
    else:
        cases = Path(args.cases)
        if not cases.is_absolute():
            cases = vault / cases
        print(json.dumps({key: value for key, value in evaluate(vault, cases, args.top_k).items() if key != "results"}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
