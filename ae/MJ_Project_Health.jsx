#target aftereffects
/*
 * MJ Project Health — Tier 0 Observer (simple script)
 * After Effects 2024+. Read-only. Optimized for ~100–400 MB .aep.
 *
 * Flow:
 *   1. Runs official MographJailed_ProjectScraper.jsx (user picks receipts folder).
 *   2. User selects the written .scrape.json receipt.
 *   3. Calls project.ingest + expression.lint via MographJailed Protocol v1.
 *   4. Shows a plain-text health report (PASS / WARNINGS / BLOCKERS).
 *
 * Response fields pinned to upstream MJ_PROJECT_SUMMARY_1 / MJ_EXPRESSION_LINT_1
 * (see docs/RESPONSE_SHAPES.md). Do not invent alternate key names.
 *
 * Requirements:
 *   - MographJailed installed (designer one-liner or clone)
 *   - MographJailed_ProjectScraper.jsx and MographJailed_Client.jsxinc
 *     in the same folder as this script
 *
 * Safety:
 *   - Never modifies the open project or any source media
 *   - Only allowlisted commands: project.ingest, expression.lint
 *   - Temporary request files are deleted immediately after the call
 */

#include "MographJailed_Client.jsxinc"

(function () {
    // --- CONFIG ----------------------------------------------------------
    // Default designer-install location. Edit if your path differs.
    var CLI_PATH = Folder.myDocuments.fsName + "/MographJailed/dist/mograph-jailed.zsh";
    // ---------------------------------------------------------------------

    function alertBlock(title, body) {
        alert(title + "\n\n" + body);
    }

    function numOr(val, fallback) {
        return (typeof val === "number") ? val : fallback;
    }

    function arrLen(a) {
        return (a && a instanceof Array) ? a.length : 0;
    }

    /** Rank findings: error → warning → info; format top N lines. */
    function summarizeLint(lintData) {
        if (!lintData) return "No lint data.";
        var findings = lintData.findings;
        if (!findings || !(findings instanceof Array) || findings.length === 0) {
            return "No expression issues found.";
        }
        var errors = numOr(lintData.errors, 0);
        var warnings = numOr(lintData.warnings, 0);
        var info = numOr(lintData.info, 0);
        var head = "Findings: " + numOr(lintData.numFindings, findings.length) +
            "  (" + errors + " errors, " + warnings + " warnings, " + info + " info)";
        if (lintData.findingsTruncated) {
            head += "  [truncated]";
        }

        var order = { error: 0, warning: 1, info: 2 };
        var sorted = findings.slice(0);
        sorted.sort(function (a, b) {
            var sa = order[String(a && a.severity || "").toLowerCase()];
            var sb = order[String(b && b.severity || "").toLowerCase()];
            if (sa === undefined) sa = 9;
            if (sb === undefined) sb = 9;
            if (sa !== sb) return sa - sb;
            var ca = String(a && a.code || "");
            var cb = String(b && b.code || "");
            return ca < cb ? -1 : (ca > cb ? 1 : 0);
        });

        var lines = [head], i, f, max = Math.min(sorted.length, 12);
        for (i = 0; i < max; i++) {
            f = sorted[i];
            if (!f) continue;
            var sev = String(f.severity || "").toUpperCase();
            var code = f.code ? String(f.code) : "";
            var where = "";
            if (f.comp || f.layer) {
                where = " [" + (f.comp || "?") + " / " + (f.layer || "?") + "]";
            }
            lines.push("• " + sev + (code ? " " + code : "") + where + " — " +
                (f.message || String(f).substring(0, 80)));
        }
        if (sorted.length > max) {
            lines.push("… +" + (sorted.length - max) + " more");
        }
        return lines.join("\n");
    }

    try {
        if (!app.project) {
            alertBlock("Project Health", "No project is open.");
            return;
        }

        // 1) Official read-only scraper (prompts for receipts folder, writes .scrape.json)
        var scraperFile = new File($.fileName.replace(/[^\/\\]+$/, "MographJailed_ProjectScraper.jsx"));
        if (!scraperFile.exists) {
            alertBlock(
                "Project Health",
                "Scraper not found next to this script:\n" + scraperFile.fsName +
                "\n\nPlace MographJailed_ProjectScraper.jsx in the same folder."
            );
            return;
        }
        $.evalFile(scraperFile);

        // 2) User selects the receipt just written
        var receipt = File.openDialog("Select the .scrape.json that was just written", "*.json");
        if (!receipt) return;

        // 3) MographJailed runtime
        var cliFile = new File(CLI_PATH);
        if (!cliFile.exists) {
            alertBlock(
                "Project Health",
                "MographJailed runtime not found:\n" + CLI_PATH +
                "\n\nRe-run the designer install or edit CLI_PATH at the top of this script."
            );
            return;
        }

        var client = new MJNativeClient(cliFile);

        var probe = client.probe();
        if (!probe.ok) {
            var probeMsg = (probe.error)
                ? (probe.error.code + " — " + probe.error.message)
                : "unknown";
            alertBlock("Project Health", "Native probe failed:\n" + probeMsg);
            return;
        }

        var ingest = client.call("project.ingest", { path: receipt.fsName });
        if (!ingest.ok) {
            var ingestMsg = (ingest.error)
                ? (ingest.error.code + "\n" + ingest.error.message)
                : "unknown error";
            alertBlock("Project Health — ingest failed", ingestMsg);
            return;
        }

        var lint = null;
        try {
            lint = client.call("expression.lint", { path: receipt.fsName });
        } catch (lintErr) {
            // best-effort; continue with ingest summary
        }

        // 4) Report — fields from MJ_PROJECT_SUMMARY_1 / MJ_EXPRESSION_LINT_1 only
        var d = ingest.data || {};
        var missingArr = d.footageMissing;
        var unlinkedArr = d.footageUnlinked;
        var missing = arrLen(missingArr);
        var unlinked = arrLen(unlinkedArr);

        var lintData = (lint && lint.ok && lint.data) ? lint.data : null;
        var lintErrors = lintData ? numOr(lintData.errors, 0) : 0;
        var lintWarnings = lintData ? numOr(lintData.warnings, 0) : 0;

        // Status: BLOCKERS if missing footage or lint errors; WARNINGS if lint warnings or unlinked
        var status = "PASS";
        if (missing > 0 || lintErrors > 0) {
            status = "BLOCKERS";
        } else if (lintWarnings > 0 || unlinked > 0) {
            status = "WARNINGS";
        }

        var projectLabel = d.projectName;
        if (!projectLabel && app.project.file) {
            projectLabel = app.project.file.name;
        }
        if (!projectLabel) projectLabel = "(unsaved)";

        var lines = [];
        lines.push("Status: " + status);
        lines.push("Project: " + projectLabel);
        if (d.aeVersion) lines.push("AE (scrape): " + d.aeVersion);
        lines.push("Receipt: " + receipt.name);
        lines.push("");
        lines.push("Comps:        " + numOr(d.numComps, "?"));
        lines.push("Layers:       " + numOr(d.numLayers, "?"));
        lines.push("Expressions:  " + numOr(d.numExpressions, "?"));
        lines.push("Effects:      " + numOr(d.numEffects, "?"));
        lines.push("Fonts:        " + numOr(d.numFonts, arrLen(d.fonts) || "?"));
        lines.push("Footage:      " + numOr(d.numFootage, "?"));
        lines.push("Missing:      " + missing);
        lines.push("Unlinked:     " + unlinked);

        if (missing > 0 && missingArr) {
            lines.push("");
            lines.push("--- Missing footage ---");
            var mi, maxM = Math.min(missingArr.length, 15);
            for (mi = 0; mi < maxM; mi++) {
                lines.push("• " + missingArr[mi]);
            }
            if (missingArr.length > maxM) {
                lines.push("… +" + (missingArr.length - maxM) + " more");
            }
        }

        if (d.compsTruncated || d.footageTruncated) {
            lines.push("");
            lines.push("Note: scrape was truncated (very large project). Summary is partial.");
        }

        lines.push("");
        lines.push("--- Expression lint ---");
        if (lintData) {
            lines.push(summarizeLint(lintData));
        } else if (lint && lint.error) {
            lines.push("Lint error: " + lint.error.message);
        } else {
            lines.push("Lint skipped or unavailable.");
        }

        alertBlock("MJ Project Health", lines.join("\n"));

    } catch (e) {
        alertBlock("Project Health error", e.toString());
    }
}());
