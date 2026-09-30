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

    function countMissing(footage) {
        var n = 0, i;
        if (!footage || !(footage instanceof Array)) return 0;
        for (i = 0; i < footage.length; i++) {
            if (footage[i] && footage[i].missing === true) n++;
        }
        return n;
    }

    function summarizeLint(lintData) {
        if (!lintData) return "No lint data.";
        var findings = lintData.findings || lintData.issues || lintData.problems || [];
        if (!findings || findings.length === 0) return "No expression issues found.";
        var lines = [], i, f, max = Math.min(findings.length, 12);
        for (i = 0; i < max; i++) {
            f = findings[i];
            if (!f) continue;
            lines.push("• " + (f.message || f.rule || f.code || String(f).substring(0, 80)));
        }
        if (findings.length > max) {
            lines.push("… +" + (findings.length - max) + " more");
        }
        return lines.join("\n");
    }

    function numOr(val, fallback) {
        return (typeof val === "number") ? val : fallback;
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

        // 4) Report
        var d = ingest.data || {};
        var missing = 0;
        if (d.footage) {
            missing = countMissing(d.footage);
        } else if (typeof d.missingFootageCount === "number") {
            missing = d.missingFootageCount;
        }

        var lintFindings = [];
        if (lint && lint.ok && lint.data) {
            lintFindings = lint.data.findings || lint.data.issues || lint.data.problems || [];
        }

        var status = "PASS";
        if (missing > 0) {
            status = "BLOCKERS";
        } else if (lintFindings.length > 0) {
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
        lines.push("Receipt: " + receipt.name);
        lines.push("");
        lines.push("Comps:        " + numOr(d.compCount, d.comps ? d.comps.length : "?"));
        lines.push("Layers:       " + numOr(d.layerCount, "?"));
        lines.push("Expressions:  " + numOr(d.expressionCount, "?"));
        lines.push("Fonts:        " + numOr(d.fontCount, d.fonts ? d.fonts.length : "?"));
        lines.push("Footage:      " + numOr(d.footageCount, d.footage ? d.footage.length : "?"));
        lines.push("Missing:      " + missing);

        if (d.compsTruncated || d.footageTruncated) {
            lines.push("");
            lines.push("Note: scrape was truncated (very large project). Summary is partial.");
        }

        lines.push("");
        lines.push("--- Expression lint ---");
        if (lint && lint.ok) {
            lines.push(summarizeLint(lint.data));
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
