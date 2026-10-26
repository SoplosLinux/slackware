#!/usr/bin/env python3
"""Build the package dependency map used by scripts/setup.debloat.

It streams every package of a Slackware tree from a mirror (nothing is written
to disk except the result), reads the shared libraries each program and library
needs, and the interpreter of each script, and maps them to the package that
provides them. The result is data/deps.tsv with one line per dependency:

    package <TAB> needs <TAB> hard|soft

hard: a program, a top-level library or a script of "package" needs "needs".
soft: only a plugin or module in a subdirectory needs it (Qt or GStreamer
      plugins, Perl or Ruby modules), so the package keeps working without it.

What this cannot see: libraries loaded with dlopen by name, Python modules
imported by scripts, QML modules and data files. Treat the map as a safety
net, not as a proof.

Usage: python3 tools/gen-deps.py [--out data/deps.tsv] [--workers 8]
Needs Python 3 and a network connection; it downloads about 5 GB.
"""
import argparse, datetime, lzma, re, struct, sys, tarfile, urllib.request
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor

BASE = "https://mirrors.slackware.com/slackware/slackware64-current"
# Packages with no programs or libraries worth reading (firmware, sources, fonts)
SKIP = {"kernel-firmware", "kernel-source", "kernel-generic", "noto-cjk-fonts-ttf",
        "noto-fonts-ttf", "sof-firmware", "intel-microcode",
        "plasma-workspace-wallpapers", "kernel-headers"}

ELFDIR = re.compile(r"^(usr/)?(bin|sbin|lib|lib64|libexec)/|^opt/")
PROGRAM = re.compile(r"^(usr/)?(s?bin|libexec)/")
TOPLIB = re.compile(r"^(usr/)?lib(64)?/[^/]+$")
SOFILE = re.compile(r"\.so(\.[0-9A-Za-z_]+)*$")


def elf_needs(data):
    """Return (needed, soname) for a 64-bit ELF file, or None."""
    if len(data) < 64 or data[:4] != b"\x7fELF" or data[4] != 2:
        return None
    e = "<" if data[5] == 1 else ">"
    phoff = struct.unpack_from(e + "Q", data, 32)[0]
    phentsize, phnum = struct.unpack_from(e + "HH", data, 54)
    loads, dyn = [], None
    for i in range(phnum):
        o = phoff + i * phentsize
        if o + 56 > len(data):
            return None
        p_type, _f, p_off, p_vaddr, _pa, p_filesz, _ms, _al = struct.unpack_from(e + "IIQQQQQQ", data, o)
        if p_type == 1:
            loads.append((p_vaddr, p_off, p_filesz))
        elif p_type == 2:
            dyn = (p_off, p_filesz)
    if not dyn:
        return [], None

    def v2o(v):
        for va, off, sz in loads:
            if va <= v < va + sz:
                return off + (v - va)
        return None

    ents, strtab, o = [], None, dyn[0]
    end = min(dyn[0] + dyn[1], len(data))
    while o + 16 <= end:
        tag, val = struct.unpack_from(e + "qQ", data, o)
        if tag == 0:
            break
        ents.append((tag, val))
        if tag == 5:
            strtab = v2o(val)
        o += 16
    if strtab is None:
        return [], None

    def cstr(off):
        j = data.find(b"\0", off)
        return data[off:j].decode("utf8", "replace")

    needed, soname = [], None
    for tag, val in ents:
        if tag == 1:
            needed.append(cstr(strtab + val))
        elif tag == 14:
            soname = cstr(strtab + val)
    return needed, soname


def scan(job):
    base, name, series, fname = job
    out = {"so": set(), "bins": set(), "hard": set(), "soft": set(),
           "interp": set(), "failed": None}
    if name in SKIP:
        return name, out
    try:
        with urllib.request.urlopen(f"{base}/slackware64/{series}/{fname}", timeout=120) as r:
            tf = tarfile.open(fileobj=r, mode="r|xz")
            for m in tf:
                p = m.name.lstrip("./")
                leaf = p.rsplit("/", 1)[-1]
                if m.isdir():
                    continue
                if SOFILE.search(leaf):
                    out["so"].add(leaf)
                if PROGRAM.match(p) and (m.isfile() or m.issym()):
                    out["bins"].add("/" + p)
                if not (m.isfile() and m.size > 4 and ELFDIR.match(p)):
                    continue
                f = tf.extractfile(m)
                head = f.read(256)
                if head[:4] == b"\x7fELF":
                    res = elf_needs(head + f.read())
                    if res:
                        kind = "hard" if (PROGRAM.match(p) or TOPLIB.match(p)) else "soft"
                        out[kind].update(res[0])
                        if res[1]:
                            out["so"].add(res[1])
                elif head[:2] == b"#!":
                    words = head.split(b"\n", 1)[0].decode("utf8", "replace")[2:].split()
                    if words:
                        interp = words[0]
                        if interp.endswith("/env") and len(words) > 1:
                            interp = "env:" + words[1].lstrip("-S")
                        out["interp"].add(interp)
    except Exception as ex:  # keep going, report at the end
        out["failed"] = str(ex)
    return name, out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="data/deps.tsv")
    ap.add_argument("--base", default=BASE)
    ap.add_argument("--workers", type=int, default=8)
    args = ap.parse_args()

    with urllib.request.urlopen(f"{args.base}/slackware64/PACKAGES.TXT", timeout=120) as r:
        txt = r.read().decode("utf8", "replace")
    jobs = []
    for block in txt.split("\n\n"):
        n = re.search(r"^PACKAGE NAME:\s+(\S+)", block, re.M)
        loc = re.search(r"^PACKAGE LOCATION:\s+\./slackware64/(\S+)", block, re.M)
        if n and loc:
            fname = n.group(1)
            name = re.sub(r"-[^-]*-[^-]*-[^-]*$", "", re.sub(r"\.t[gx]z$", "", fname))
            jobs.append((args.base, name, loc.group(1), fname))

    info, done = {}, 0
    with ThreadPoolExecutor(max_workers=args.workers) as ex:
        for name, out in ex.map(scan, jobs):
            info[name] = out
            done += 1
            if done % 100 == 0:
                print(f"{done}/{len(jobs)}", file=sys.stderr, flush=True)
    failed = {n: o["failed"] for n, o in info.items() if o["failed"]}

    prov_so, prov_path, prov_leaf = defaultdict(set), defaultdict(set), defaultdict(set)
    for p, o in info.items():
        for s in o["so"]:
            prov_so[s].add(p)
        for b in o["bins"]:
            prov_path[b].add(p)
            prov_leaf[b.rsplit("/", 1)[-1]].add(p)

    edges = defaultdict(dict)  # package -> dependency -> "hard" | "soft"
    def add(p, q, kind):
        if q != p and edges[p].get(q) != "hard":
            edges[p][q] = kind
    for p, o in info.items():
        for kind in ("soft", "hard"):  # hard last so it wins
            for s in o[kind]:
                for q in prov_so.get(s, ()):
                    add(p, q, kind)
        for i in o["interp"]:
            if i.startswith("env:"):
                cands = prov_leaf.get(i[4:], ())
            else:
                cands = prov_path.get(i) or prov_leaf.get(i.rsplit("/", 1)[-1], ())
            for q in cands:
                add(p, q, "hard")

    with open(args.out, "w") as f:
        f.write(f"# Generated by tools/gen-deps.py from {args.base} on {datetime.date.today()}\n")
        f.write("# columns: package<TAB>needs<TAB>hard|soft\n")
        for p in sorted(edges):
            for q in sorted(edges[p]):
                f.write(f"{p}\t{q}\t{edges[p][q]}\n")
    n = sum(len(v) for v in edges.values())
    print(f"{len(info)} packages, {n} dependencies, {len(failed)} failed -> {args.out}", file=sys.stderr)
    for name, why in failed.items():
        print(f"FAILED {name}: {why}", file=sys.stderr)


if __name__ == "__main__":
    main()
