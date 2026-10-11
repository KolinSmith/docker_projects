#!/usr/bin/env python3
"""One-time migration of dotfiles/.claude/memory/*.md into self-hosted Mem0.

Strips YAML frontmatter and stores each file's body verbatim (infer=False,
no LLM rewriting) via Mem0's POST /memories endpoint, tagged by filename
and metadata.type so retrieval can still filter by category.

Files whose body exceeds OpenAI's ~8192-token-per-embedding-call limit are
split into multiple paragraph-aligned chunks (see chunk_text) and sent as
separate /memories calls, tagged with chunk_index/chunk_total so they can
be identified as pieces of the same original file.
"""
import os
import re
import sys
import requests

MEM0_URL = "http://localhost:8888/memories"
MEM0_API_KEY = os.environ["MEM0_ADMIN_API_KEY"]
MEMORY_DIR = "/home/dax/code_base/dotfiles/.claude/memory"

# Conservative character-based ceiling well under OpenAI's 8192-token
# embedding input limit (~4 chars/token, with headroom for markdown
# overhead). Character counting avoids pulling in a tokenizer dependency
# just for this one-time script.
MAX_CHUNK_CHARS = 20000

FRONTMATTER_RE = re.compile(r"^---\n(.*?)\n---\n(.*)$", re.DOTALL)


def chunk_text(body, max_chars=MAX_CHUNK_CHARS):
    """Split body into chunks <= max_chars, preferring paragraph (blank-line)
    boundaries so sentences aren't cut mid-way. Falls back to a hard split
    for any single paragraph that itself exceeds max_chars."""
    if len(body) <= max_chars:
        return [body]

    paragraphs = body.split("\n\n")
    chunks = []
    current = ""
    for para in paragraphs:
        if len(para) > max_chars:
            # Paragraph itself is too big: flush what we have, then
            # hard-split this paragraph on its own.
            if current:
                chunks.append(current)
                current = ""
            for i in range(0, len(para), max_chars):
                chunks.append(para[i : i + max_chars])
            continue

        candidate = f"{current}\n\n{para}" if current else para
        if len(candidate) <= max_chars:
            current = candidate
        else:
            chunks.append(current)
            current = para

    if current:
        chunks.append(current)

    return chunks


def parse_file(path):
    with open(path, "r") as f:
        content = f.read()
    match = FRONTMATTER_RE.match(content)
    if not match:
        raise ValueError(f"{path}: no YAML frontmatter found")
    frontmatter, body = match.groups()
    type_match = re.search(r"type:\s*(\w+)", frontmatter)
    memory_type = type_match.group(1) if type_match else "unknown"
    return body.strip(), memory_type


def migrate_file(filename, body, memory_type):
    chunks = chunk_text(body)
    total = len(chunks)
    results = []
    for index, chunk in enumerate(chunks):
        response = requests.post(
            MEM0_URL,
            headers={"X-API-Key": MEM0_API_KEY},
            json={
                "messages": [{"role": "user", "content": chunk}],
                "user_id": "kolin",
                "infer": False,
                "metadata": {
                    "source_file": filename,
                    "memory_type": memory_type,
                    "chunk_index": index,
                    "chunk_total": total,
                },
            },
            timeout=30,
        )
        response.raise_for_status()
        results.append(response.json())
    return results


def main():
    files = sorted(f for f in os.listdir(MEMORY_DIR) if f.endswith(".md"))
    print(f"Found {len(files)} memory files to migrate.")
    failures = []
    for filename in files:
        path = os.path.join(MEMORY_DIR, filename)
        try:
            body, memory_type = parse_file(path)
            results = migrate_file(filename, body, memory_type)
            chunk_note = f", {len(results)} chunks" if len(results) > 1 else ""
            print(f"  OK   {filename} (type={memory_type}{chunk_note})")
        except Exception as e:
            print(f"  FAIL {filename}: {e}")
            failures.append(filename)

    print(f"\n{len(files) - len(failures)}/{len(files)} migrated successfully.")
    if failures:
        print("Failed files:", ", ".join(failures))
        sys.exit(1)


if __name__ == "__main__":
    main()
