#!/usr/bin/env python3
"""打印/*.md -> 打印/pdf/*.pdf（带页号），并合并为 打印/pdf/ACM模板合集.pdf

- 合集最前面加「扉页 + 目录」，目录列出各分类与模板及其页码
- 每个模板(## 小节)从新的一页开始
- 双面打印：自动插入空页，使 目录 与每个分类的首张都落在奇数页（正面）
- 单文件页脚: "N / 本文件总页数"; 合集页脚: 连续绝对 "N / 总页数"（扉页不编号，其余含空页都编号）
- 合集带书签: 一级=分类(6个md), 二级=各模板(## 标题)，另有「封面」「目录」

依赖: pandoc, chromium, pdftotext(poppler), python: pypdf
用法: python3 md2pdf.py
"""
import html
import io
import re
import subprocess
import sys
import tempfile
from pathlib import Path

from pypdf import PdfReader, PdfWriter
from reportlab.lib.colors import Color
from reportlab.pdfgen import canvas

SRC = Path(__file__).resolve().parent
DST = SRC / "pdf"
DST.mkdir(exist_ok=True)
MERGED = DST / "ACM模板合集.pdf"

FONT = "'Noto Sans CJK SC', 'Source Han Sans CN', sans-serif"

CSS = """
@page { size: A4; margin: 13mm 11mm 16mm; }
* { box-sizing: border-box; }
body {
  font-family: FONT;
  font-size: 9.5pt; line-height: 1.55; color: #1a1a1a; margin: 0;
}
h1 { font-size: 19pt; margin: 0 0 0.4em; border-bottom: 2.5px solid #2b2b2b; padding-bottom: 6px; }
h2 {
  break-before: page; page-break-before: always;
  font-size: 14.5pt; margin: 0 0 0.5em;
  border-bottom: 1.5px solid #888; padding-bottom: 4px;
}
h3 { font-size: 11.5pt; margin: 1em 0 0.35em; }
h1, h2, h3, h4 { break-after: avoid; page-break-after: avoid; }
p { margin: 0.4em 0; }
pre {
  font-family: 'JetBrains Maple Mono', 'Noto Sans Mono CJK SC', monospace;
  font-size: 8.3pt; line-height: 1.42;
  background: #f6f8fa; border: 1px solid #d8dde3; border-radius: 4px;
  padding: 7px 9px; margin: 0.45em 0;
  white-space: pre-wrap; word-break: break-all;
}
code { font-family: inherit; }
:not(pre) > code {
  background: #eef0f2; border-radius: 3px; padding: 0 3px; font-size: 0.92em;
}
blockquote {
  margin: 0.5em 0; padding: 4px 10px;
  border-left: 3px solid #7a7a7a; background: #f7f7f7; color: #333;
}
blockquote p { margin: 0.25em 0; }
table { border-collapse: collapse; width: 100%; margin: 0.5em 0; font-size: 8.8pt; }
th, td { border: 1px solid #bbb; padding: 3px 7px; text-align: left; }
th { background: #ececec; }
ul, ol { margin: 0.35em 0; padding-left: 1.6em; }
li { margin: 0.18em 0; }
a { color: #0645ad; text-decoration: none; }
hr { border: none; border-top: 1px solid #ccc; }
""".replace("FONT", FONT)

COVER_CSS = """
@page { size: A4; margin: 0; }
html, body { margin: 0; padding: 0; }
body { font-family: FONT; color: #1a1a1a; }
.cover { position: relative; width: 210mm; height: 297mm; overflow: hidden; }
.band { position: absolute; left: 0; right: 0; height: 16mm; background: #2b2b2b; }
.band.top { top: 0; } .band.bottom { bottom: 0; }
.inner {
  position: absolute; top: 0; left: 0; right: 0; bottom: 0;
  display: flex; flex-direction: column;
  align-items: center; justify-content: center;
  text-align: center; padding: 26mm;
}
.kicker { font-size: 13pt; letter-spacing: 8px; color: #6a6a6a; margin-bottom: 12mm; }
.title { font-size: 43pt; font-weight: 700; letter-spacing: 3px; line-height: 1.25; }
.rule { width: 64mm; height: 3px; background: #2b2b2b; margin: 9mm 0; }
.sub { font-size: 14pt; color: #444; letter-spacing: 1px; }
.tags { margin-top: 7mm; font-size: 10.5pt; color: #666; letter-spacing: 1px; }
.meta { margin-top: 36mm; font-size: 11pt; color: #888; letter-spacing: 2px; }
""".replace("FONT", FONT)

TOC_CSS = """
@page { size: A4; margin: 12mm 14mm 12mm; }
body { font-family: FONT; font-size: 9.4pt; color: #1a1a1a; margin: 0; }
h1 {
  font-size: 16pt; margin: 0 0 3.5mm; letter-spacing: 6px;
  border-bottom: 2px solid #2b2b2b; padding-bottom: 2mm;
}
.cat, .item { display: flex; align-items: baseline; }
.cat {
  font-weight: 700; font-size: 10.5pt;
  margin: 2.4mm 0 0.7mm; break-after: avoid; page-break-after: avoid;
}
.item { margin: 0.4mm 0 0.4mm 6mm; font-size: 9pt; }
.cat .t, .item .t { white-space: nowrap; }
.dots {
  flex: 1 1 auto; min-width: 6mm; margin: 0 4px;
  border-bottom: 1px dotted #b5b5b5; position: relative; top: -3px;
}
.pg { font-variant-numeric: tabular-nums; }
""".replace("FONT", FONT)


def chromium_print(page_html: str, out: Path, stem: str):
    tmp = Path(tempfile.mkdtemp()) / f"{stem}.html"
    tmp.write_text(page_html, encoding="utf-8")
    subprocess.run(
        ["chromium", "--headless", "--no-sandbox", "--disable-gpu",
         "--no-pdf-header-footer", f"--print-to-pdf={out}", str(tmp)],
        check=True, capture_output=True)


def md_to_pdf(md: Path, out: Path):
    """md -> chromium 打印为 pdf（h2 分页由 CSS 保证）"""
    html_body = subprocess.run(
        ["pandoc", str(md), "-f", "gfm", "-t", "html5", "--highlight-style", "kate"],
        capture_output=True, text=True, check=True).stdout
    page_html = (f'<!DOCTYPE html><html lang="zh-CN"><head><meta charset="utf-8">'
                 f'<title>{md.stem}</title><style>{CSS}</style></head>'
                 f'<body>{html_body}</body></html>')
    chromium_print(page_html, out, md.stem)


def make_cover(out: Path):
    """生成扉页"""
    page_html = (f'<!DOCTYPE html><html lang="zh-CN"><head><meta charset="utf-8">'
                 f'<style>{COVER_CSS}</style></head><body>'
                 f'<div class="cover">'
                 f'<div class="band top"></div><div class="band bottom"></div>'
                 f'<div class="inner">'
                 f'<div class="kicker">ACM-XCPC</div>'
                 f'<div class="title">算法模板合集</div>'
                 f'<div class="rule"></div>'
                 f'<div class="sub">竞赛代码模板 · header-only</div>'
                 f'<div class="tags">数据结构 · 图论 · 数学 · 字符串 · 对拍</div>'
                 f'<div class="meta">ihxnan</div>'
                 f'</div></div></body></html>')
    chromium_print(page_html, out, "_cover")


def make_toc(out: Path, entries):
    """entries: [(level, title, page)]，level 0=分类, 1=模板"""
    rows = []
    for level, title, pg in entries:
        cls = "cat" if level == 0 else "item"
        rows.append(f'<div class="{cls}"><span class="t">{html.escape(title)}</span>'
                    f'<span class="dots"></span><span class="pg">{pg}</span></div>')
    page_html = (f'<!DOCTYPE html><html lang="zh-CN"><head><meta charset="utf-8">'
                 f'<style>{TOC_CSS}</style></head><body>'
                 f'<h1>目录</h1>{"".join(rows)}</body></html>')
    chromium_print(page_html, out, "_toc")


def md_titles(md: Path):
    """提取 ## 模板标题（去掉 markdown 记号）"""
    text = md.read_text(encoding="utf-8")
    return [re.sub(r"[`*]", "", m.group(1)).strip()
            for m in re.finditer(r"^## (.+)$", text, re.M)]


def md_h1(md: Path):
    """提取 # 分类标题（去掉代码片段，仅留中文名）"""
    for line in md.read_text(encoding="utf-8").splitlines():
        if line.startswith("# "):
            name = re.sub(r"`[^`]*`", "", line[2:])
            return re.sub(r"[`*]", "", name).strip() or md.stem
    return md.stem


def template_pages(pdf: Path, titles):
    """pdftotext 扫描各模板标题所在本地页码(0-based)；找不到为 None"""
    txt = subprocess.run(["pdftotext", str(pdf), "-"],
                         capture_output=True, text=True).stdout
    starts = []
    for p in txt.split("\f")[:-1]:
        first = next((l.strip() for l in p.splitlines() if l.strip()), "")
        starts.append(re.sub(r"\s", "", first))
    locs = []
    for t in titles:
        key = re.sub(r"\s", "", t)
        # 用完整标题匹配：短前缀(如前 4 字)会误配 (如 "FHQ Treap(数组版)" / "FHQ Treap(指针版)")
        locs.append(next((i for i, s in enumerate(starts) if s.startswith(key)), None))
    return locs


def make_overlay(n_pages, w, h, start=1, total=None):
    """页号 overlay PDF (内存对象)：页脚居中 'N / total'"""
    if total is None:
        total = start + n_pages - 1
    buf = io.BytesIO()
    c = canvas.Canvas(buf, pagesize=(float(w), float(h)))
    c.setFont("Helvetica", 9)
    c.setFillColor(Color(0.35, 0.35, 0.35))
    for i in range(n_pages):
        c.drawCentredString(float(w) / 2, 16, f"{start + i} / {total}")
        c.showPage()
    c.save()
    buf.seek(0)
    return PdfReader(buf)


files = sorted(SRC.glob("*.md"))
if not files:
    sys.exit("未找到 md 文件")

dst = Path(tempfile.mkdtemp())

# ---- 1) 每个 md -> 单文件 pdf（页脚 "N / 本文件总页数"），并记录各模板所在页 ----
raws = []             # [{md, raw, n, w, h, locs:[(标题, 文件内 0-based 页)]}]
for md in files:
    raw = Path(tempfile.mkdtemp()) / f"{md.stem}.pdf"
    md_to_pdf(md, raw)
    reader = PdfReader(raw)
    n = len(reader.pages)
    w, h = reader.pages[0].mediabox.width, reader.pages[0].mediabox.height

    ov = make_overlay(n, w, h)                 # 单文件页号 "N / n"
    for i, page in enumerate(reader.pages):
        page.merge_page(ov.pages[i])
    w1 = PdfWriter()
    w1.append(reader)
    out = DST / f"{md.stem}.pdf"
    with out.open("wb") as f:
        w1.write(f)

    titles = md_titles(md)
    locs = template_pages(raw, titles)         # 用未盖章的原文扫描标题页
    raws.append({"md": md, "raw": raw, "n": n, "w": w, "h": h,
                 "locs": [(t, p) for t, p in zip(titles, locs) if p is not None]})
    print(f"{out.name}: {n} 页, {out.stat().st_size // 1024} KB, "
          f"书签 {len(raws[-1]['locs'])}")

w, h = raws[0]["w"], raws[0]["h"]

# ---- 2) 先量目录页数（行数固定，与页码数值无关），据此刻画插空页后的绝对页号 ----
cover_pdf = dst / "cover.pdf"
toc_pdf = dst / "toc.pdf"
make_cover(cover_pdf)

rows_dummy = []
for r in raws:
    rows_dummy.append((0, md_h1(r["md"]), 1))
    rows_dummy += [(1, t, 1) for t, _ in r["locs"]]
make_toc(toc_pdf, rows_dummy)
T = len(PdfReader(toc_pdf).pages)

# 双面装订：让目录与每个分类的首张都落在奇数页（正面）
pc = 1                                      # 扉页占第 1 页
n_blank_cover = 1 if (pc + 1) % 2 == 0 else 0
pc += n_blank_cover
toc_start = pc + 1                          # 目录首页绝对页号
pc += T
abs_starts = []                             # 各分类首页绝对页号
for r in raws:
    nb = 1 if (pc + 1) % 2 == 0 else 0      # 首张会落在偶数页则先补一张空页
    pc += nb
    abs_starts.append(pc + 1)
    pc += r["n"]
total = pc

# ---- 3) 用真实绝对页号重建目录 ----
entries = []
for r, a in zip(raws, abs_starts):
    entries.append((0, md_h1(r["md"]), a))
    entries += [(1, t, a + p) for t, p in r["locs"]]
make_toc(toc_pdf, entries)
assert len(PdfReader(toc_pdf).pages) == T, "目录页数因页码变化而改变"

# ---- 4) 合并: 扉页 + [空页] + 目录 + 各分类（分类前按需插空页使首页为奇数）----
merged = PdfWriter()
for p in PdfReader(cover_pdf).pages:
    merged.add_page(p)
for _ in range(n_blank_cover):
    merged.add_blank_page(w, h)
toc_index = len(merged.pages)               # 目录首页的 0-based 索引（书签用）
for p in PdfReader(toc_pdf).pages:
    merged.add_page(p)
for r, a in zip(raws, abs_starts):
    for _ in range(a - (len(merged.pages) + 1)):   # 0 或 1 张空页
        merged.add_blank_page(w, h)
    for p in PdfReader(r["raw"]).pages:
        merged.add_page(p)
assert len(merged.pages) == total, "页数计算不一致"

# ---- 5) 连续绝对页号（扉页不编号，其余页脚 "N / 总数"，空页同样编号）----
ov = make_overlay(total - 1, w, h, start=2, total=total)
for i in range(1, total):
    merged.pages[i].merge_page(ov.pages[i - 1])

# ---- 6) 书签 ----
merged.add_outline_item("封面", 0)
merged.add_outline_item("目录", toc_index)
cat_item = None
for level, title, bp in entries:
    idx = bp - 1
    if level == 0:
        cat_item = merged.add_outline_item(title, idx)
    else:
        merged.add_outline_item(title, idx, parent=cat_item)
merged.add_metadata({"/Title": "ACM-XCPC 模板合集", "/Creator": "打印/md2pdf.py"})
with MERGED.open("wb") as f:
    merged.write(f)
n_blank = total - (1 + T + sum(r["n"] for r in raws))
print(f"{MERGED.name}: {total} 页（扉页 1 + 目录 {T} + 正文 {sum(r['n'] for r in raws)}，"
      f"插空页 {n_blank}）, {MERGED.stat().st_size // 1024} KB")
print("完成 ->", DST)
