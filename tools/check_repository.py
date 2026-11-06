#!/usr/bin/env python3
"""Validate published artifacts without MATLAB. Run from any directory."""
from pathlib import Path
import csv
import hashlib
import json
import math
import re
import subprocess
import sys
import urllib.parse
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[1]
GENERATED_PARTS = {'work', 'codegen', 'slprj', '__pycache__', '.git', '.venv'}
GENERATED_SUFFIXES = {'.aux', '.bbl', '.bcf', '.blg', '.fls', '.log', '.out', '.toc', '.xdv', '.fdb_latexmk'}
TEXT_SUFFIXES = {'.md', '.m', '.py', '.json', '.csv', '.tex', '.bib', '.yml', '.yaml', '.svg', '.ssc'}
PRIVATE_PATH = re.compile(r'/Users/[^/\s]+|[A-Za-z]:[\\/]Users[\\/][^\\/\s]+|wxid_[A-Za-z0-9_]+')
PRIVATE_EMAIL = re.compile(r'[\w.+-]+@(?!users\.noreply\.github\.com\b)(?:[\w-]+\.)*(?:edu\.cn|gmail\.com|qq\.com|outlook\.com)\b', re.I)
errors = []

def fail(path, message):
    errors.append(f'{path.relative_to(ROOT)}: {message}')

def files():
    if (ROOT / '.git').exists():
        result = subprocess.run(['git', 'ls-files', '-z', '--cached', '--others', '--exclude-standard'], cwd=ROOT, check=True, capture_output=True)
        return sorted({ROOT / p.decode() for p in result.stdout.split(b'\0') if p})
    return sorted(p for p in ROOT.rglob('*') if p.is_file() and not (set(p.relative_to(ROOT).parts) & GENERATED_PARTS) and '/Results/raw/' not in str(p) and p.suffix not in GENERATED_SUFFIXES and p.name not in {'main.pdf', 'main.run.xml'})

paths = files()
for path in paths:
    relative = path.relative_to(ROOT)
    if not path.is_file():
        fail(path, 'tracked file is missing')
        continue
    if path.stat().st_size > 50 * 1024 * 1024:
        fail(path, 'artifact exceeds 50 MiB; use a documented data delivery method')
    if path.suffix in {'.mat', '.fig', '.docx', '.slxc'}:
        fail(path, 'raw session, editable session, original handout or generated cache is not a release artifact')
    if path.suffix in TEXT_SUFFIXES and relative.as_posix() != 'tools/check_repository.py':
        content = path.read_text(encoding='utf-8-sig')
        if PRIVATE_PATH.search(content) or PRIVATE_EMAIL.search(content):
            fail(path, 'personal path or private email pattern detected')
        if path.suffix == '.md':
            links = re.findall(r'\]\(([^\s)]+)(?:\s+[^)]*)?\)', content)
            links += re.findall(r'<img\b[^>]*\bsrc="([^"]+)"', content)
            for link in links:
                target = urllib.parse.unquote(link.strip('<>').split('#')[0].split('?')[0])
                if not target or re.match(r'^[a-zA-Z][a-zA-Z0-9+.-]*:', target):
                    continue
                if not (path.parent / target).exists():
                    fail(path, f'broken local link: {target}')
    if path.suffix == '.slx':
        with zipfile.ZipFile(path) as archive:
            for member in archive.namelist():
                if not member.endswith('.xml'):
                    continue
                content = archive.read(member).decode('utf-8', errors='replace')
                if PRIVATE_PATH.search(content) or PRIVATE_EMAIL.search(content):
                    fail(path, f'private identity pattern in {member}')
                if member == 'metadata/coreProperties.xml':
                    root = ET.fromstring(content)
                    for entry in root:
                        if entry.tag.split('}')[-1] in {'creator', 'lastModifiedBy'} and entry.text not in {None, '', 'GKC3-Simulink contributors'}:
                            fail(path, 'model author metadata is not the public project identity')
    if path.suffix == '.pdf':
        try:
            import pymupdf as fitz
        except ImportError:
            continue
        with fitz.open(path) as document:
            metadata = document.metadata
            if metadata.get('author') not in {None, '', 'GKC3-Simulink contributors'}:
                fail(path, 'PDF author metadata is not the public project identity')
            content = '\n'.join(page.get_text() for page in document)
            if PRIVATE_PATH.search(content) or PRIVATE_EMAIL.search(content):
                fail(path, 'private path or email in PDF text')
            if document.embfile_count():
                fail(path, 'PDF contains embedded files')

metrics_path = ROOT / 'Project/Materials/Integrated/full/metrics.json'
metrics = json.loads(metrics_path.read_text())
if not metrics['finite'] or not math.isclose(metrics['stop_s'], 30, abs_tol=1e-9):
    fail(metrics_path, 'recorded full run is incomplete or non-finite')
if metrics['net_ac_energy_after_12p3_s_J'] >= 0:
    fail(metrics_path, 'reported return-energy sign is inconsistent')
for side in ('A', 'B'):
    if metrics['gate_measurements'][f'overlap_{side}_samples']:
        fail(metrics_path, 'overlapping bridge gates in the recorded window')

# Cross-check exported numerical evidence independently of the simulation code.
overview_path = ROOT / 'Project/Materials/Integrated/full/overview_1ms.csv'
with overview_path.open(newline='', encoding='utf-8-sig') as stream:
    overview = [{key: float(value) for key, value in row.items()} for row in csv.DictReader(stream)]
if not overview or not math.isclose(overview[-1]['time_s'], 30, abs_tol=1e-9):
    fail(overview_path, 'CSV does not reach the recorded full-run end time')
if any(not math.isfinite(value) for row in overview for value in row.values()):
    fail(overview_path, 'CSV contains non-finite values')
if any(a['time_s'] >= b['time_s'] for a, b in zip(overview, overview[1:])):
    fail(overview_path, 'CSV timestamps are not strictly increasing')
start = min(overview, key=lambda row: abs(row['time_s'] - 12.3))
exported_return = overview[-1]['Eac_J'] - start['Eac_J']
if not math.isclose(exported_return, metrics['net_ac_energy_after_12p3_s_J'], rel_tol=1e-9, abs_tol=1e-5):
    fail(overview_path, 'CSV energy difference disagrees with recorded return-energy metric')
for relative in ['Project/Materials/Integrated/full/gates_native_1us.csv', 'Project/Materials/VerifiedHBridge/gates_native_1us.csv']:
    gate_path = ROOT / relative
    with gate_path.open(newline='', encoding='utf-8-sig') as stream:
        for row in csv.DictReader(stream):
            if (float(row['g1']) > 0 and float(row['g2']) > 0) or (float(row['g3']) > 0 and float(row['g4']) > 0):
                fail(gate_path, 'overlapping gates in published samples')
                break

manifest = ROOT / 'docs/validation/artifact-manifest.json'
if manifest.exists():
    for record in json.loads(manifest.read_text())['files']:
        path = ROOT / record['path']
        if not path.exists() or hashlib.sha256(path.read_bytes()).hexdigest() != record['sha256']:
            fail(path, 'artifact differs from the validated manifest')

if errors:
    print('\n'.join(errors))
    sys.exit(1)
print(f'PASS: {len(paths)} published files; local links, model metadata, data consistency and artifact manifest.')
try:
    import pymupdf as fitz
    print('PDF metadata and extracted text checks enabled.')
except ImportError:
    print('PDF deep checks skipped: install PyMuPDF to enable them.')
