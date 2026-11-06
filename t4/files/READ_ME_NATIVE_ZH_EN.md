# T4 单个最终原生零件的建模源代码 / One final native part: build source

**交付状态 / Delivery status**：用户要求的是一个最终、可逐项编辑的 `Binding_Anchor_FINAL.SLDPRT`。当前 Linux 环境没有 Windows SOLIDWORKS 2026，**尚未生成或验证这个原生文件**。以下 VBA/VBScript 是辅助建模源代码，不能作为该 `.SLDPRT` 文件的替代交付；也没有把其他格式改名为 `.SLDPRT`。

The requested deliverable is one final editable `Binding_Anchor_FINAL.SLDPRT`. **That native file has not been generated or verified here** because this Linux environment has no Windows SOLIDWORKS runtime. These auxiliary source files are not a substitute for the requested native part. Genuine native creation requires running SOLIDWORKS on Windows.

## 本源代码包的内容 / Contents of this source package

- `T4_Binding_Anchor.bas`：导入 SOLIDWORKS VBA 的文本模块 / text module to import into SOLIDWORKS VBA.
- `Build_T4_Binding_Anchor.vbs`：可选 Windows Script Host 启动程序 / optional Windows Script Host entry point.
- `T4_Aluminum_2800.sldmat`：仅定义教材密度的材料库 / workbook density-only material library.
- `native_static_checks.json`：已执行的静态检查及尚未运行 SOLIDWORKS 的声明 / static checks and explicit runtime-pending status.
- 本说明 / this guide.

## 在真实 SOLIDWORKS 中生成 / Build in genuine SOLIDWORKS

### 方式 A：VBA / Option A: VBA

1. 启动有合法许可证的 **SOLIDWORKS 2026**。确认 **文件/File → 新建/New → 零件/Part** 可用，并配置标准、空白零件模板。
   Start licensed SOLIDWORKS 2026. Confirm that **File → New → Part** creates an empty standard part using the configured default template.
2. 点击 **工具/Tools → 宏/Macro → 新建/New**，保存为 `T4_Build.swp`，进入 VBA 编辑器。
   Choose **Tools → Macro → New**, save as `T4_Build.swp`, and open the VBA editor.
3. 点击 VBA 编辑器的 **文件/File → 导入文件/Import File**，导入 `T4_Binding_Anchor.bas`。`.bas` 不能直接当作 `.swp` 运行。
   In the VBA editor, choose **File → Import File** and import `T4_Binding_Anchor.bas`. A `.bas` file must be imported before it can run as part of a macro.
4. 双击模块 **T4_Binding_Anchor**，把光标放在 `Sub main()` 内，按 **F5 / 运行子过程/Run Sub/UserForm**。采用后期绑定，无需新增 SOLIDWORKS 类型库引用。
   Open module **T4_Binding_Anchor**, place the cursor inside `Sub main()`, and press **F5**. The source uses late binding.
5. 程序自动建立一个新的零件，在内存中逐阶段核对几何；不会为每个阶段另存文件，也没有逐特征暂停提示。仅在全部几何检查通过后保存最终零件。
   The builder creates one new part and validates each stage in memory. It creates no intermediate part files and has no per-feature pause dialogs. It saves the final part after all geometry checks pass.

### 方式 B：Windows 脚本 / Option B: Windows script

先打开 SOLIDWORKS 2026，再双击 `Build_T4_Binding_Anchor.vbs`。若系统未安装或禁用 VBScript/Windows Script Host，使用 VBA 方式。

Open SOLIDWORKS 2026 first, then double-click `Build_T4_Binding_Anchor.vbs`. If Windows Script Host/VBScript is unavailable, use VBA instead.

## 唯一的最终零件 / The single final part

成功运行后的预期输出位置为：

Expected output after a successful genuine SOLIDWORKS run:

```text
Windows 文档 / Documents
└─ T4_Binding_Anchor_日期时间 / timestamp
   ├─ Binding_Anchor_FINAL.SLDPRT   ← 唯一的零件文件 / the only part file
   ├─ T4_Aluminum_2800.sldmat
   └─ build_log.txt
```

重复运行会使用新的时间戳目录，避免覆盖已有结果。**本下载包并不包含上图中的 `.SLDPRT`；它仍需在真实 SOLIDWORKS 中生成、重建和检查。**

Each run creates a new timestamped folder. **The `.SLDPRT` shown above is not included in this download; it still requires genuine SOLIDWORKS generation, rebuilding, and verification.**

## 在一个零件中修改每一步 / Edit each step within one part

最终设计树预期包含下列原生特征及其草图；没有用导入实体冒充建模历史。

The intended final native feature tree contains the following editable features and sketches:

| 特征 / Feature | 尺寸和操作 / Dimensions and operation |
|---|---|
| `F01_Base_D82_T3p5` / `S01_Base_D82` | Ø82，凸台拉伸3.5 mm / Ø82 boss, 3.5 mm |
| `F02_Bottom_D75_T3` / `S02_Bottom_D75` | 底部Ø75，向外凸台拉伸3 mm / bottom Ø75 boss, 3 mm outward |
| `F03_Recess_D63_Depth3` / `S03_Recess_D63` | 顶部Ø63，切除3 mm / top Ø63 recess, cut 3 mm |
| `F04_Rounded_Slots_ThroughAll` / `S04_Symmetric_Slots` | 四槽，宽8、弧心距16，完全贯穿 / four slots: width8, center spacing16, through all |
| `F05_Outer_R1p5` | 外圆上缘R1.5 / outer top edge R1.5 |
| `F06_Inner_Edges_R1` | 同一圆角特征包含凹槽下缘及上口，两边R1 / one R1 fillet feature, both lower and upper recess edges |

1. 展开凸台或切除特征，右键草图 → **编辑草图/Edit Sketch**。双击驱动尺寸可修改；制造轮廓没有被全部设为“固定/Fix”。
   Expand a boss/cut and right-click its sketch → **Edit Sketch**. Change the driving dimensions; production contours are not all fixed.
2. 圆直径的驱动尺寸分别命名为 `BaseDiameter`、`BottomDiameter`、`RecessDiameter`。四槽的种子尺寸为 `SlotRadius=4`、`SlotCenterSpacing=16`、`SlotOffsetX=12`、`SlotOffsetY=6`，单位mm。其余三槽由两次原生草图镜像关联；固定的是参考原点/构造中心线。
   Named circle diameters are `BaseDiameter`, `BottomDiameter`, and `RecessDiameter`. The seed slot has `SlotRadius=4`, `SlotCenterSpacing=16`, `SlotOffsetX=12`, and `SlotOffsetY=6` mm. Two native sketch mirrors relate the other three slots. Fixed geometry is limited to the reference point/construction axes.
3. 右键特征 → **编辑特征/Edit Feature**，可改凸台深度、切除终止条件或圆角半径。
   Right-click a feature → **Edit Feature** to change boss depth, cut end condition, or fillet radius.
4. 拖动设计树底部的 **退回控制棒/Rollback Bar** 到某个特征之前，查看早期形状；再拖到底部恢复完整零件。所有阶段都在这一个零件中查看。
   Drag the **Rollback Bar** above a feature to inspect an earlier stage, then return it to the bottom. Inspect all stages within this one part.
5. 按 **Ctrl+B / 重建/Rebuild**；需要时按 **Ctrl+Q / 强制重建/Force Rebuild**，再保存。
   Use **Ctrl+B / Rebuild**, or **Ctrl+Q / Force Rebuild**, then save.

教材先动态镜像第一对槽，源代码先完成种子槽再执行两次“镜像实体/Mirror Entities”；对称设计关系等效。源代码采用 **上视基准面/Top Plane**，厚度沿 SOLIDWORKS 全局Y方向；网站几何预览用Z作厚度轴，只是坐标约定不同。

The workbook uses dynamic mirroring for its first slot pair. This source finishes the seed before two sketch mirrors, producing equivalent symmetry. Native construction uses **Top Plane** with global-Y thickness; the website preview uses Z thickness.

## 材料与质量 / Material and mass

用户已确认首圆柱采用Ø82。教材部分正文写2015铝合金、截图写2014；质量按教材密度 **2800 kg/m³ = 0.0028 g/mm³** 核对。

The first cylinder uses the confirmed Ø82. The workbook's material prose and screenshots differ, so expected mass is checked at the stated density **2800 kg/m³**.

程序写入专用材料库并尝试赋材，读取实际密度核验。该材料只定义密度，不提供强度/有限元分析属性。自动赋材失败时仍保存最终原生几何，并明确提示手动选择材料。

The builder attempts to apply and verify the supplied density-only material. It has no verified strength/FEA properties. If automatic assignment fails, the final native geometry is saved with an explicit manual-material warning.

1. 点击 **工具/Tools → 选项/Options → 系统选项/System Options → 文件位置/File Locations**，在 **显示下列文件夹/Show folders for** 中选 **材料数据库/Material Databases**，点击 **添加/Add**，选中 `.sldmat` 所在文件夹，点击 **确定/OK**。
   Add the `.sldmat` folder under **Tools → Options → System Options → File Locations → Material Databases**.
2. 右键设计树 **材质/Material → 编辑材料/Edit Material**。展开库 **T4_Aluminum_2800 → T4 Workbook**，选 **T4 Aluminum 2800 (density only)**；核对 **质量密度/Mass Density = 2800 kg/m³**，点击 **应用/Apply → 关闭/Close**。
   In **Material → Edit Material**, select **T4_Aluminum_2800 → T4 Workbook → T4 Aluminum 2800 (density only)**, verify density, and **Apply → Close**.
3. 点击 **评估/Evaluate → 质量属性/Mass Properties**；应见体积约 **19,765.727 mm³**、质量约 **55.344 g**。确认没有用户覆盖质量，然后保存同一个最终文件。
   Check **Evaluate → Mass Properties**: volume about **19,765.727 mm³**, mass about **55.344 g**, without a user mass override. Save the same final file.

## 检查范围与故障定位 / Verification and troubleshooting

已完成静态源代码/API参数检查、材料XML解析及独立CAD几何核验；**未执行SOLIDWORKS运行测试**。运行时会检查草图完全定义、一个实体、16条槽边界，以及每阶段体积是否在参考值±0.1mm³内；底部拉伸方向也作检查。上述检查描述的是程序逻辑，不代表已经在SOLIDWORKS通过。

Static source/API checks, material XML parsing, and independent geometry validation are complete. **No SOLIDWORKS runtime test has been performed.** The intended runtime checks enforce fully defined sketches, one solid, 16 slot segments, each stage volume within ±0.1mm³, and outward bottom extrusion. These are checks implemented in the source, not a claim of successful SOLIDWORKS execution.

若运行中止，保留阶段名、错误编号及 `build_log.txt`。失败时当前未保存模型可在SOLIDWORKS内检查；不得把中间状态当作最终交付。模板需为空白标准零件模板；源代码按第二个默认参考平面选Top，不依赖中英文名称。

If construction stops, retain the stage/error and `build_log.txt`. Inspect the unsaved active model in SOLIDWORKS; it is not the final deliverable. Use a standard empty part template: Top is selected as the second default reference plane, independently of its localized name.

官方API参考 / Official API references:

- [SketchMirror](https://help.solidworks.com/2024/english/api/sldworksapi/SolidWorks.Interop.sldworks~SolidWorks.Interop.sldworks.IModelDoc2~SketchMirror.html)
- [FeatureExtrusion2](https://help.solidworks.com/2024/English/api/sldworksapi/SOLIDWORKS.Interop.sldworks~SOLIDWORKS.Interop.sldworks.IFeatureManager~FeatureExtrusion2.html)
- [FeatureCut4](https://help.solidworks.com/2024/english/api/sldworksapi/solidworks.interop.sldworks~solidworks.interop.sldworks.ifeaturemanager~featurecut4.html)
- [FeatureFillet3](https://help.solidworks.com/2025/English/api/sldworksapi/SolidWorks.Interop.sldworks~SolidWorks.Interop.sldworks.IFeatureManager~FeatureFillet3.html)
- [Editing fillet edges](https://help.solidworks.com/2024/english/api/sldworksapi/SolidWorks.Interop.sldworks~SolidWorks.Interop.sldworks.ISimpleFilletFeatureData2~Edges.html)
- [Material assignment](https://help.solidworks.com/2023/english/api/sldworksapi/SolidWorks.Interop.sldworks~SolidWorks.Interop.sldworks.IPartDoc~SetMaterialPropertyName2.html)
