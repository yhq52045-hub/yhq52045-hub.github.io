# Lab 5：SolidWorks 原生特征构建源 / Native-feature builder source

**交付状态 / Delivery status**

本目录交付的是四份 VBA 模块源文件，不是已经生成、打开或验证过的 `.SLDPRT`。制作环境没有运行 SolidWorks。配套 STEP 是几何交换文件，不保留 SolidWorks 草图与特征历史。VBA 在你的 Windows / SolidWorks 2026 本机运行，才会尝试创建真实的草图、凸台和切除特征。

These are four VBA source modules, **not delivered or tested SLDPRT files**. SolidWorks was unavailable in the authoring environment. STEP preserves shape rather than native sketch/feature history. Running a module locally in licensed Windows SolidWorks 2026 attempts to create native sketches, bosses and cuts.

| 文件 / File | 创建内容 / Scope | 当前限制 / Current limitation |
|---|---|---|
| `Lab5_Q1_Native.bas` | 6 个实体特征：底板、斜块、下台阶、上台阶、槽、双销 / Six solid features | 草图自动补尺寸；应按教学核查驱动尺寸与设计意图 / Automatically dimensions remaining freedoms; review driving dimensions and intent |
| `Lab5_Q2_Native.bas` | 5 个实体特征，Lab 4 Q2 / Five solid features | 切线轮廓含真实相切关系；凸台与孔引用圆边同心；已添加壁厚方程，但需本机检查 / Tangencies, concentric edge references and wall-thickness equations require a local rebuild check |
| `Lab5_Q3_Native.bas` | 6 个实体特征，含沿坡面法向的 R65 切除 / Six solid features, including the R65 cut normal to the incline | 自动补尺寸；不能替代孔阵列、坡度和等厚设计意图检查 / Automatic dimensions do not certify the intended hole, incline or thickness behavior |
| `Lab5_Q4_Native.bas` | 6 个实体特征；关于前视基准面中面拉伸；两侧肩部深度由宽度方程控制 / Six solid features with a centered main extrusion and linked shoulder depths | **草图有意保留未完全定义状态，必须手工补关系**。禁止自动加坐标尺寸，以免违反“只用图示尺寸”的要求 / **Sketches deliberately remain underdefined**; complete references and relations manually. Automatic coordinate dimensioning is disabled |

Q4 的 16 表示槽中心线至右端下表面的距离。它不是侧槽宽度。侧槽宽度由 `2 × (36 − 16 − 14) = 12 mm` 推得。原生草稿把此宽度作为方程计算值。两肩的每侧深度为 `(48 − 26) / 2 = 11 mm`。

For Q4, 16 is the distance from the slot centerline to the lower end surface. The derived side-slot width is `2 × (36 − 16 − 14) = 12 mm`; this draft links that width through an equation. Each shoulder depth is `(48 − 26) / 2 = 11 mm`.

## 第一次如何运行 / First run

1. 先打开 **SolidWorks 2026**，关闭正在编辑的草图。顶部菜单若隐藏，单击左上角 SolidWorks 标志旁的小箭头，展开菜单栏。
   Open **SolidWorks 2026** and exit any active sketch. If the menu bar is hidden, expand it using the arrow next to the SolidWorks logo at the upper left.
2. 点击 **工具 / Tools → 宏 / Macro → 新建 / New**，在自己选择的文件夹保存一个 `.swp` 宏文件，例如 `Lab5_Q1_Local.swp`。这会打开 **Microsoft Visual Basic for Applications** 编辑器。若编辑器不可用，需要通过 SolidWorks 安装程序安装 VBA 支持。
   Choose **Tools → Macro → New**, save a `.swp` file in a folder of your choice, and allow the VBA editor to open. If unavailable, install the VBA component through the SolidWorks installer.
3. 在 VBA 编辑器的菜单选择 **文件 / File → 导入文件 / Import File**，选中本目录对应的 `.bas` 文件。一次只导入一道题，避免多个 `main` 过程混淆。
   In the VBA editor choose **File → Import File** and select the relevant `.bas` module. Import one question per `.swp` macro.
4. 在左侧 **工程资源管理器 / Project Explorer** 双击导入模块，例如 `Lab5_Q1_Native`。若左侧面板没显示，点击 **视图 / View → 工程资源管理器 / Project Explorer**，快捷键 `Ctrl+R`。
   Open the imported module in **Project Explorer**. Use **View → Project Explorer**, or `Ctrl+R`, if the panel is hidden.
5. 将光标放在 `Public Sub main()` 与对应的 `End Sub` 之间，按 `F5`，或者点击 **运行 / Run → 运行子过程/用户窗体 / Run Sub/UserForm**。
   Place the cursor inside `Public Sub main()` and press `F5`, or choose **Run → Run Sub/UserForm**.
6. 程序使用你的默认 **零件 / Part** 模板新建文档；如果没有默认模板，会询问 `.prtdot` 模板完整路径。可在 **工具 / Tools → 选项 / Options → 系统选项 / System Options → 默认模板 / Default Templates** 查看默认零件模板。程序记录日志到“文档”目录中新建的 `Lab5_Q…_时间` 文件夹。
   A new document is created from the default **Part** template. If no default is configured, provide its `.prtdot` path. Locate it under **Tools → Options → System Options → Default Templates**. Logs are written to a new timestamped `Lab5_Q…` folder in Documents.
7. `main` **只生成新的未保存零件**。出现停止消息时，按消息和日志定位对应草图或特征；不要把中途生成的零件当成完成版。
   `main` leaves a **new unsaved part**. If it stops, inspect the named sketch/feature and log. A partially built model is not a final solution.

## 查看和修改每一步 / Inspect and edit every step

在图形区左侧 **FeatureManager 设计树 / FeatureManager design tree**，展开 `F01…`、`F02…` 等特征旁的箭头。右键其中的 `S01…` 草图，选择 **编辑草图 / Edit Sketch**；双击尺寸修改数值。按右上角 **退出草图 / Exit Sketch** 后，按 `Ctrl+B` **重建 / Rebuild**。右键实体特征，选择 **编辑特征 / Edit Feature**，可修改给定深度、中面、方向或终止条件。

In the left **FeatureManager design tree**, expand each named `F01…`, `F02…` feature. Right-click its `S01…` sketch and choose **Edit Sketch**; double-click a dimension to change it. Use **Exit Sketch**, then `Ctrl+B` **Rebuild**. Right-click a solid feature and choose **Edit Feature** to change its depth, Mid Plane option, direction or end condition.

要看某一步之前的形体，将设计树底部的 **退回控制棒 / rollback bar** 向上拖到相应特征之前；看完后拖回最底部。恢复完整模型后按 `Ctrl+Q` 强制重建。

Drag the **rollback bar** at the bottom of the tree above a feature to inspect earlier geometry; return it to the end afterwards. Use `Ctrl+Q` for a force rebuild.

Q4 的后肩使用第二次对向切除，而网页可采用 **镜像 / Mirror** 同一前肩。两者生成相同几何；本宏的两个深度都通过 `(FullWidth − NeckWidth) / 2` 方程联系。Q4 仍须手工补充：R21 同心孔中心与原点重合；上孔中心距 55 并向左偏离竖直 15°；R20、R21、R105 的相切关系；水平肩低于上孔心 11；两 R25 与上孔同心；两孔同径；侧槽对孔心水平线对称；顶视叉槽关于前视基准面对称。肩部切除草图的外围辅助边须引用/转换实体边并添加关系，不能用“固定”掩盖未定义。

Q4 uses two opposite shoulder cuts rather than mirroring the first, whereas the website may teach **Mirror**. Both depths are linked by `(FullWidth − NeckWidth) / 2`. Complete Q4's origin, 55/15° hole-center layout, arc tangencies, 11 mm shoulder drop, concentric R25 arcs, equal holes, centered side slot and centered top fork. Replace the shoulder draft's outer support edges with converted/linked model references and relations; do not fix the production contour.

## 检查后保存 / Save after local checks

所有草图完全定义后，核对原图尺寸、方向、原点、特征错误和设计意图。在 **评估 / Evaluate → 质量属性 / Mass Properties** 查看体积。Q4 把 48 改成另一个值时，必须仍关于前视基准面对称，再恢复 48。

After fully defining every sketch, check the source dimensions, orientation, origin, feature rebuild errors and intent. Inspect volume under **Evaluate → Mass Properties**. For Q4, change 48 temporarily, verify continued symmetry about Front Plane, then restore 48.

然后返回 VBA 编辑器，将光标放入 `Public Sub SaveCheckedPart()`，按 `F5`。此过程递归检查可见和吸收的草图是否完全定义、实体是否只有一个、体积是否在参考值 ±1% 内。未通过时不会执行保存。通过后，输入一个**尚不存在**的完整输出路径，文件名必须是 `Q1.sldprt`、`Q2.sldprt`、`Q3.sldprt` 或 `Q4.sldprt`。已有文件不会被覆盖。

Then place the cursor inside `Public Sub SaveCheckedPart()` and press `F5`. It recursively checks sketches, requires one solid and verifies the ±1% volume tolerance before attempting a save. Provide a **new** full path with the required question filename. Existing files are not overwritten.

这个自动检查只能检查列出的条件；体积合格并不证明全部尺寸和设计意图正确。保存后应关闭并用 SolidWorks 2026 重新打开，确认正常重建。

The save checks cover only the stated conditions. Volume agreement does not prove every dimension or design relationship. Close and reopen the saved part in SolidWorks 2026 and confirm a clean rebuild.

## 验证边界 / Validation boundary

已做：源代码结构、API 调用参数个数、无导入体替代原生特征、生产几何无固定关系、Q4 禁用自动补坐标尺寸、Q4 槽宽订正及宽度/肩部方程的静态检查。

Checked: source structure, API argument counts, no imported-body shortcut, no fixed production geometry, disabled automatic coordinate dimensioning for Q4, corrected Q4 slot width, and static width/shoulder equation checks.

未做：SolidWorks VBA 编译、宏运行、SolidWorks 求解器是否接受每条尺寸/关系、各版本/本地化模板表现、真实重建与原生文件打开验证。相关结果不能由 STEP 几何验证或静态源代码检查替代。

Not checked: VBA compilation, macro execution, solver acceptance of every dimension/relation, localized template behavior, native rebuilds or reopening saved SLDPRT files. STEP checks and static source checks do not substitute for these tests.

API 参考 / API references:

- [SOLIDWORKS API — FeatureExtrusion2](https://help.solidworks.com/2026/english/api/sldworksapi/SolidWorks.Interop.sldworks~SolidWorks.Interop.sldworks.IFeatureManager~FeatureExtrusion2.html)
- [SOLIDWORKS API — FeatureCut3](https://help.solidworks.com/2026/english/api/sldworksapi/SolidWorks.Interop.sldworks~SolidWorks.Interop.sldworks.IFeatureManager~FeatureCut3.html)
- [SOLIDWORKS API — FullyDefineSketch](https://help.solidworks.com/2026/english/api/sldworksapi/SolidWorks.Interop.sldworks~SolidWorks.Interop.sldworks.ISketchManager~FullyDefineSketch.html)

这些 API 在 2026 文档中属于兼容接口；没有在本环境验证其运行。/ These are compatibility API interfaces; runtime behavior was not verified here.
