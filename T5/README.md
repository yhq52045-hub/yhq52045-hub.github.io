# 固定器底板 / Binding Base Plate

本次内容为用户上传PDF的原书第74–95页，共22页、任务1–8。引用要求中的旧页码24–54只用于参考交付方式。公开教学网址：https://yhq52045-hub.github.io/T5/

This edition covers the current upload: workbook pages 74–95, 22 pages, Tasks 1–8. The earlier 24–54 page range is a delivery-format reference. Public teaching website: https://yhq52045-hub.github.io/T5/

## 打开教学网页 / Open the teaching website

解压完整ZIP，双击 `index.html`，建议用Chrome或Edge。网页沿用用户T4页面的配色和布局：左侧目录、中间中英双语步骤、右侧三维阶段。61步教学、12阶段、22页原图、术语表和进度保存均不依赖网络。保留同级 `files` 文件夹以使用下载链接。官方帮助链接需要联网。

Extract the complete ZIP and open `index.html`, preferably in Chrome or Edge. The design follows the user's T4 page: contents on the left, bilingual instructions in the middle, and construction stages on the right. All 61 steps, 12 stage views, 22 original pages, glossary, and progress storage work offline. Keep the sibling `files` folder for downloads. Official help links require an internet connection.

支持拖动旋转、滚轮缩放、视图切换、阶段跳转、关键词搜索、完成标记、原页放大和左右方向键翻步。不能使用WebGL时显示当前阶段的静态CAD参考投影。这些预览是几何渲染，不是SOLIDWORKS界面截图。

Controls include drag rotation, wheel zoom, view presets, stage navigation, search, completion marks, enlarged source pages, and left/right arrow step navigation. A static CAD projection is supplied for each stage when WebGL is unavailable. Previews are geometric renders, not SOLIDWORKS screenshots.

## 文件与实际交付状态 / Files and actual status

|文件 / File|内容 / Content|状态 / Status|
|---|---|---|
|`files/Binding_Base_Bilingual_74-95.docx`|完整中文译文＋22张完整英文原页；中文可编辑 / Full translation and 22 original page images|23页，已用Word兼容渲染检查 / 23 pages, compatible rendering checked|
|`files/Binding_Base_Bilingual_74-95.pdf`|A3横向对照版；右侧嵌入原PDF矢量内容 / A3 landscape spreads with original PDF vector content|23页，原图和说明均保留 / All originals retained|
|`files/Binding_Base_SW2026_Manual.pdf`|网站全部61个双语操作步骤 / All 61 bilingual website steps|17页，可搜索与打印 / Searchable and printable|
|`files/Binding_Base_Plate_FINAL.step`|成形参考实体 / Bent reference solid|有效单实体，已重新导入检查 / Valid single solid, re-import checked|
|`files/Binding_Base_Plate_FLAT_K0p5.step`|K=0.5展开参考实体 / K=0.5 flat reference|有效单实体，已重新导入检查 / Valid single solid, re-import checked|
|`files/model_engine.py` + `parameters.json`|逐阶段构建的CadQuery源码与参数 / Stage-by-stage CadQuery source and parameters|源码可改、可重建；不含原生SW特征 / Rebuildable source, no native SW features|
|`files/Build_Binding_Base.bas`|SOLIDWORKS VBA辅助源码 / VBA helper|尝试任务1–5及可选任务6辅助；未经SW编译或运行 / Attempts Tasks1–5 plus optional T6 helper; untested in SW|
|`Binding_Base_Plate_FINAL.SLDPRT`|用户要求的完整可编辑原生零件 / Requested native editable part|**尚未生成，也不在本包中 / Not generated or included**|

**STEP不能代替可逐项编辑的原生SLDPRT。** 当前环境不能运行Windows SOLIDWORKS 2026。完整的原生文件需要在SOLIDWORKS内按教程完成任务1–8，重建、展开和折回检查通过后保存；辅助宏不等于已完成的原生文件。

**STEP does not replace an editable native SLDPRT.** Windows SOLIDWORKS 2026 is unavailable in the authoring environment. Complete Tasks1–8 in SOLIDWORKS and verify rebuild, flattening, and reforming before saving the native part. Helper source is not a completed native-file deliverable.

## 参考几何的限制 / Reference geometry limits

- 教材没有指定K因子。参考模型使用可修改的K=0.5；截图中的0.5属于自动释放槽参数，不是教材给出的K值。孔心50/110应在展开态定义。
  The workbook does not specify K. References use configurable K=0.5. The screenshot's 0.5 is an auto-relief parameter. Locate the hole by 50/110 in the flat state.
- 最终参考模型的R15在原平面外廓上修圆后与弯曲板求交；展开参考模型在平展轮廓上修R15。耳根R2跨弯使用21截面放样近似。这两份模型没有通过原生SOLIDWORKS钣金展开/折回验证。
  Bent-reference R15 is generated in plan before intersection with the curved sheet; flat-reference R15 is applied on the developed outline. R2 roots use a 21-section loft approximation over the bend. The pair has not been verified by native SOLIDWORKS unfolding/reforming.
- 成形与展开参考体积相差约50.85 mm³（约0.088%）。模型用于学习和几何参考，不能作为已核定的制造展开数据。详细检查见 `files/validation.json`。
  Bent and flat reference volumes differ by about 50.85 mm³ (0.088%). They are teaching references, not approved manufacturing-development data. See `files/validation.json`.

## 查看和修改建模过程 / Inspect and modify the build

在真正的原生零件里，使用“编辑草图/Edit Sketch”“编辑特征/Edit Feature”和“退回控制棒/Rollback Bar”。最终只保存一个零件，内部保留完整历史。网页阶段展示帮助理解变化，STEP只用于交换形状。

Use Edit Sketch, Edit Feature, and the Rollback Bar in the native part. Save one final part with its entire construction history. Website stages explain changes; STEP exchanges geometry.

重建参考几何需Python、CadQuery 2.7和其Open CASCADE依赖；渲染预览另需Matplotlib。复制并修改参数后运行：

Reference reconstruction requires Python, CadQuery 2.7 and its Open CASCADE dependencies; preview rendering additionally uses Matplotlib. Edit a parameter copy, then run:

```sh
python model_engine.py --params parameters.json --out rebuilt_models
```

VBA操作方式和自动化范围见 `files/native_builder_README.md`。宏只尝试任务1–5，T7展开态圆角和T8孔仍需手动完成；其约束组织与教材也有差异，见说明。

See `files/native_builder_README.md` for VBA setup and scope. The helper attempts Tasks1–5. T7 flat-state fillets and T8 center hole remain manual, and some sketch relations differ from the workbook.

## 检查范围 / Verification coverage

已完成：Word兼容渲染页数、PDF原页及译文、22张Word原页图、网页JavaScript语法、元素ID与下载文件完整性、61步与12阶段关联、12阶段有效单实体、两份STEP重新导入检查。另按逐页图片摘要核对，原PDF的97个图片/图标实例在双语PDF中全部一致，原英文文字也全部保留。

Completed: compatible Word rendering and page counts; PDF originals and translations; all22 Word page images; JavaScript syntax; element IDs and local downloads; 61-step/12-stage mapping; valid single-solid checks for all12 stages; both STEP re-import checks. Per-page image-digest comparisons also confirm that all97 original image/icon instances match in the bilingual PDF, with all original English text retained.

未完成：当前会话没有可调用的托管浏览器控制工具，未进行实际浏览器交互/GPU实测；未在SOLIDWORKS中运行VBA或生成原生SLDPRT。原生交付仍不完整。

Unverified: browser interaction/GPU testing was unavailable because this session has no callable managed browser-control tool. VBA has not run in SOLIDWORKS and no native SLDPRT was generated. Native delivery remains incomplete.
