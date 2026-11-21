"""Generate the documentation charts as inline-able SVGs.

Run from the repo root:  python docs/charts/make_charts.py
Writes docs/_static/charts/*.svg. Data comes from the repo:
task checkboxes in specs/*/tasks.md, test counts in test/*.dart, and the same
sample-data formula as MockData.sampleUsage (lib/data/mock_data.dart).
"""
import math
import re
from html import escape
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "_static" / "charts"

# Reference palette, light mode (validated: blue/orange adjacent pair passes all checks).
SURFACE = "#fcfcfb"
TEXT = "#0b0b0b"
TEXT_2 = "#52514e"
GRID = "#e6e5e1"
BLUE = "#2a78d6"
ORANGE = "#eb6834"
BLUE_LIGHT = "#86b6ef"  # sequential step 250, for forecast ranges
FONT = "system-ui, -apple-system, 'Segoe UI', sans-serif"


def nice_step(max_value, ticks=4):
    raw = max_value / ticks
    mag = 10 ** math.floor(math.log10(raw))
    return next(m * mag for m in (1, 2, 2.5, 5, 10) if m * mag >= raw)


def svg(width, height, title, body):
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" '
        f'width="100%" style="max-width:{width}px;font-family:{FONT};background:{SURFACE}" '
        f'role="img" aria-label="{escape(title)}">'
        f"<title>{escape(title)}</title>{body}</svg>\n"
    )


def top_rounded_bar(x, y, w, h, r=4):
    """Bar with rounded data-end (top), square at the baseline."""
    r = min(r, w / 2, h)
    return (
        f"M{x:.1f},{y + h:.1f} V{y + r:.1f} Q{x:.1f},{y:.1f} {x + r:.1f},{y:.1f} "
        f"H{x + w - r:.1f} Q{x + w:.1f},{y:.1f} {x + w:.1f},{y + r:.1f} V{y + h:.1f} Z"
    )


def right_rounded_bar(x, y, w, h, r=4):
    r = min(r, h / 2, w)
    return (
        f"M{x:.1f},{y:.1f} H{x + w - r:.1f} Q{x + w:.1f},{y:.1f} {x + w:.1f},{y + r:.1f} "
        f"V{y + h - r:.1f} Q{x + w:.1f},{y + h:.1f} {x + w - r:.1f},{y + h:.1f} H{x:.1f} Z"
    )


def legend(items, x, y):
    out, cx = [], x
    for label, color in items:
        out.append(f'<rect x="{cx}" y="{y - 9}" width="10" height="10" rx="2" fill="{color}"/>')
        out.append(f'<text x="{cx + 15}" y="{y}" font-size="12" fill="{TEXT_2}">{escape(label)}</text>')
        cx += 15 + 7 * len(label) + 18
    return "".join(out)


def vbars(title, cats, series, unit_fmt, width=640, height=270):
    """Vertical bars; several series stack with a 2px surface gap between segments."""
    left, right, top, bottom = 44, 12, 40, 40
    pw, ph = width - left - right, height - top - bottom
    totals = [sum(s[2][i] for s in series) for i in range(len(cats))]
    step = nice_step(max(totals))
    ymax = step * math.ceil(max(totals) * 1.08 / step)  # headroom for the value labels
    band = pw / len(cats)
    bw = min(36, band * 0.5)
    y = lambda v: top + ph - v / ymax * ph
    parts = []
    t = 0
    while t <= ymax + 1e-9:
        parts.append(f'<line x1="{left}" x2="{width - right}" y1="{y(t):.1f}" y2="{y(t):.1f}" stroke="{GRID}" stroke-width="1"/>')
        parts.append(f'<text x="{left - 8}" y="{y(t) + 4:.1f}" font-size="11" fill="{TEXT_2}" text-anchor="end">{unit_fmt(t, axis=True)}</text>')
        t += step
    for i, cat in enumerate(cats):
        x = left + band * i + (band - bw) / 2
        base = 0
        visible = [s for s in series if s[2][i] > 0]
        for s in series:
            v = s[2][i]
            if v <= 0:
                continue
            y0, y1 = y(base + v), y(base)
            is_top = s is visible[-1]
            gap = 0 if base == 0 else 2  # surface gap above the segment below
            h = y1 - y0 - gap
            d = top_rounded_bar(x, y0, bw, h) if is_top else f"M{x:.1f},{y0:.1f} h{bw:.1f} v{h:.1f} h{-bw:.1f} Z"
            parts.append(f'<g><title>{escape(cat)}: {unit_fmt(v)} {escape(s[0].lower())}</title><path d="{d}" fill="{s[1]}"/></g>')
            base += v
        parts.append(f'<text x="{x + bw / 2:.1f}" y="{y(totals[i]) - 6:.1f}" font-size="11" fill="{TEXT}" text-anchor="middle">{unit_fmt(totals[i])}</text>')
        parts.append(f'<text x="{x + bw / 2:.1f}" y="{height - bottom + 18}" font-size="12" fill="{TEXT_2}" text-anchor="middle">{escape(cat)}</text>')
    shown = [s for s in series if any(v > 0 for v in s[2])]  # no legend entry for an empty series
    if len(series) > 1:
        parts.append(legend([(s[0], s[1]) for s in shown], left, 20))
    return svg(width, height, title, "".join(parts))


def hbars(title, cats, values, color, unit_fmt, width=640):
    left, right, row = 190, 56, 30
    height = row * len(cats) + 16
    pw = width - left - right
    vmax = max(values)
    parts = []
    for i, (cat, v) in enumerate(zip(cats, values)):
        yy = 8 + i * row
        w = v / vmax * pw
        parts.append(f'<text x="{left - 10}" y="{yy + 15}" font-size="12" fill="{TEXT_2}" text-anchor="end">{escape(cat)}</text>')
        parts.append(f'<g><title>{escape(cat)}: {unit_fmt(v)}</title><path d="{right_rounded_bar(left, yy + 4, w, 14)}" fill="{color}"/></g>')
        parts.append(f'<text x="{left + w + 8:.1f}" y="{yy + 15}" font-size="12" fill="{TEXT}">{unit_fmt(v)}</text>')
    return svg(width, height, title, "".join(parts))


def ranges(title, rows, width=640):
    """Forecast: a dot for the expected value on a light bar for the range."""
    left, right, row = 110, 150, 34
    height = row * len(rows) + 40
    pw = width - left - right
    hi = max(r[3] for r in rows)
    step = nice_step(hi)
    xmax = step * math.ceil(hi / step)
    x = lambda v: left + v / xmax * pw
    parts = []
    t = 0
    while t <= xmax + 1e-9:
        parts.append(f'<line x1="{x(t):.1f}" x2="{x(t):.1f}" y1="6" y2="{height - 26}" stroke="{GRID}"/>')
        parts.append(f'<text x="{x(t):.1f}" y="{height - 10}" font-size="11" fill="{TEXT_2}" text-anchor="middle">{t:g}h</text>')
        t += step
    for i, (label, mean, low, high) in enumerate(rows):
        yy = 14 + i * row
        tip = f"{label}: ~{mean:.1f}h next week (range {low:.1f}–{high:.1f}h)"
        parts.append(f'<text x="{left - 10}" y="{yy + 4}" font-size="12" fill="{TEXT_2}" text-anchor="end">{escape(label)}</text>')
        parts.append(
            f'<g><title>{escape(tip)}</title>'
            f'<line x1="{x(low):.1f}" x2="{x(high):.1f}" y1="{yy}" y2="{yy}" stroke="{BLUE_LIGHT}" stroke-width="6" stroke-linecap="round"/>'
            f'<circle cx="{x(mean):.1f}" cy="{yy}" r="5" fill="{BLUE}" stroke="{SURFACE}" stroke-width="2"/></g>'
        )
        parts.append(f'<text x="{width - right + 10}" y="{yy + 4}" font-size="12" fill="{TEXT}">~{mean:.1f}h ({low:.1f}–{high:.1f}h)</text>')
    return svg(width, height, title, "".join(parts))


# ---------- data from the repo ----------

PHASES = [("Setup", "Setup"), ("Foundational", "Foundation"), ("User Story 1", "US1"),
          ("User Story 2", "US2"), ("User Story 3", "US3"), ("Polish", "Polish")]


def task_counts(path):
    done = {short: 0 for _, short in PHASES}
    open_ = dict(done)
    phase = None
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("## Phase"):
            phase = next((short for key, short in PHASES if key in line), None)
        m = re.match(r"- \[( |x|X)\] T\d+", line)
        if m and phase:
            (open_ if m.group(1) == " " else done)[phase] += 1
    cats = [short for _, short in PHASES]
    return cats, [done[c] for c in cats], [open_[c] for c in cats]


def test_counts():
    rows = []
    for f in sorted((ROOT / "test").glob("*_test.dart")):
        n = len(re.findall(r"^\s*(?:test|testWidgets)\(", f.read_text(encoding="utf-8"), re.M))
        rows.append((f.name, n))
    return sorted(rows, key=lambda r: -r[1])


# Mirrors MockData.sampleUsage: appBreakdown hours × weekday factor, split by hour share.
APPS = {"Instagram": 0.55, "TikTok": 0.4, "YouTube": 0.9, "X": 0.25}
DAY_FACTOR = [1.2, 1.1, 0.9, 1.0, 0.8, 1.4, 1.3]  # Mon..Sun
HOUR_SHARE = {8: 0.1, 13: 0.2, 18: 0.25, 21: 0.45}
DAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]


def forecast(daily_minutes):
    """Same as forecastWeek in lib/services/usage_insights.dart, in hours."""
    mean = sum(daily_minutes) / len(daily_minutes)
    sd = math.sqrt(sum((v - mean) ** 2 for v in daily_minutes) / len(daily_minutes))
    week, spread = mean * 7, sd * math.sqrt(7)
    return week / 60, max(0, week - spread) / 60, (week + spread) / 60


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    h = lambda v, axis=False: f"{v:g}h" if axis else f"{v:.1f}h"
    count = lambda v, axis=False: f"{v:g}"

    for feature, name in [("001-otp-auth", "tasks_001"), ("002-behaviour-insights", "tasks_002")]:
        cats, done, open_ = task_counts(ROOT / "specs" / feature / "tasks.md")
        (OUT / f"{name}.svg").write_text(
            vbars(f"Feature {feature[:3]} tasks per phase, done vs open", cats,
                  [("Done", BLUE, done), ("Open", ORANGE, open_)], count),
            encoding="utf-8")

    tests = test_counts()
    (OUT / "tests.svg").write_text(
        hbars("Automated tests per file", [t[0] for t in tests], [t[1] for t in tests], BLUE,
              lambda v: f"{v:g}"),
        encoding="utf-8")

    per_day = 60 * sum(APPS.values())
    daily = [per_day * f for f in DAY_FACTOR]
    (OUT / "sample_daily.svg").write_text(
        vbars("Sample report: screen time per day", DAYS, [("Screen time", BLUE, [m / 60 for m in daily])], h),
        encoding="utf-8")

    avg_factor = sum(DAY_FACTOR) / 7
    blocks = [0.0] * 6
    for hour, share in HOUR_SHARE.items():
        blocks[hour // 4] += per_day * avg_factor * share
    (OUT / "sample_blocks.svg").write_text(
        vbars("Sample report: average minutes per day by time of day",
              ["0-4", "4-8", "8-12", "12-16", "16-20", "20-24"],
              [("Minutes", BLUE, blocks)], lambda v, axis=False: f"{v:.0f}m"),
        encoding="utf-8")

    rows = [("Total", *forecast(daily))]
    for app in sorted(APPS, key=lambda a: -APPS[a])[:3]:
        rows.append((app, *forecast([60 * APPS[app] * f for f in DAY_FACTOR])))
    (OUT / "sample_forecast.svg").write_text(
        ranges("Sample report: next week's forecast with ranges", rows), encoding="utf-8")

    print("wrote", ", ".join(sorted(p.name for p in OUT.glob("*.svg"))))
    for r in rows:
        print(f"  {r[0]}: {r[1]:.1f}h ({r[2]:.1f}-{r[3]:.1f}h)")
    print("  blocks:", [round(b) for b in blocks], " tests:", tests)


if __name__ == "__main__":
    main()
