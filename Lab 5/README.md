# Lab 5 · SOLIDWORKS 2026 中英教学网站

网址 / Website: https://yhq52045-hub.github.io/Lab%205/

目录名称为 `Lab 5`（包含一个空格）。网站包括 **95 个中英教学步骤、23 个实体建模阶段**，覆盖 Lab 5 Q1—Q4。提供原始图页、按钮位置、尺寸核对、设计树教学模拟、可旋转的阶段模型，以及新增/切除材料的前后对照。

The directory is named `Lab 5`, including one space. The website contains **95 bilingual steps and 23 solid-modelling stages** for Lab 5 Q1–Q4, with original drawings, command locations, dimension checks, a reference feature tree, rotatable stage views and before/change/after comparisons.

## 文件 / Files

- `index.html`：在线教学网页；保留同目录的 `assets/`、`files/`。 / Online tutorial; keep its assets and downloads folders.
- `assets/`：原题图页及草图关系示意。 / Source pages and sketch-relation illustrations.
- `files/Lab5_Bilingual.docx`、`files/Lab5_Bilingual.pdf`：中英对照文档，保留全部四页原题及图片。 / Bilingual documents retaining all four original assignment pages and figures.
- `files/Q1.step`—`files/Q4.step`：经几何内核核对的参考实体。 / Reference solids checked with a CAD geometry kernel.
- `files/Native_Builders.zip`、`files/Native_README.md`：原生特征构建辅助源码及运行说明。 / Native-feature helper source and instructions.
- `source/page.html`、`source/style.css`、`source/runtime.js`：网页结构模板、样式和交互代码，供后续修改。 / Page template, styling and interaction source for later edits.
- `SHA256SUMS.json`：本目录各文件的 SHA-256，校验文件自身除外。 / File SHA-256 checksums, excluding the checksum manifest itself.

## CAD 文件状态 / CAD file status

STEP 可在 SOLIDWORKS 中打开并保留精确实体几何，但**不包含 SOLIDWORKS 原生草图与特征历史**。网页的设计树和阶段切换用于教学，不能直接修改下载的 CAD 文件。

STEP files can be opened in SOLIDWORKS and preserve exact solid geometry, but **do not contain native SOLIDWORKS sketches or feature history**. The website feature tree and stage navigation are teaching controls; they do not modify downloaded CAD files.

原生 VBA 构建器是**尚未在 SOLIDWORKS 2026 编译、执行或验证的辅助源码**，当前没有提供已经验证的 `.SLDPRT`。Q1—Q3 需要在本机检查草图尺寸关系与设计意图；Q4 有意保留待补充的草图关系，须手工完成并确认完全定义。完整限制及检查步骤见 `files/Native_README.md`。

The native VBA builders are **helper source that has not been compiled, executed or verified in SOLIDWORKS 2026**. No verified `.SLDPRT` is supplied. Q1–Q3 need local dimension/relation and design-intent checks. Q4 deliberately leaves sketch relations to complete manually before confirming Fully Defined. Read `files/Native_README.md` for the full limitations and validation procedure.

## 修改与验证 / Editing and verification

`index.html` 内嵌课程、模型与核对 JSON，以及发布时的 CSS 和 JavaScript；`source/page.html` 是模板，不能直接替代完整的 `index.html`。修改后需同步完整网页中的对应代码与教学数据，并检查下载文件和图片相对路径。课程数据另见 `files/course.json`，体积及来源核对见 `files/validation.json`。

`index.html` embeds the course, model and validation JSON, plus the publication CSS and JavaScript. `source/page.html` is a template rather than a complete replacement for index.html. Synchronize corresponding embedded code/data after edits, then check relative asset and download paths. The course is also available in `files/course.json`; geometry and source checks are in `files/validation.json`.

本次验证包括 DOM 交互、95步导航、图片与下载引用、有限画布绘制参数以及几何内核检查；这些检查不等于真实浏览器视觉/WebGL实测，也不等于 SOLIDWORKS 原生重建验证。

Validation includes DOM interactions, all 95 steps, local asset/download references, finite canvas-drawing parameters and CAD-kernel checks. These do not substitute for real-browser visual/WebGL tests or native SOLIDWORKS rebuild verification.
