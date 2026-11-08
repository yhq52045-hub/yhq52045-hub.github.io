# 固定器底板：SOLIDWORKS 建模辅助源码 / Binding Base Plate: SOLIDWORKS build helper

**交付状态 / Delivery status**

此文件包提供可审查的 `Build_Binding_Base.bas` 文本源码，**没有提供已经生成或验证的 `.SLDPRT`**。当前环境没有 Windows SOLIDWORKS，源码尚未在 SOLIDWORKS 2026 中编译、执行或重建验证。源码不等于用户要求的完整可编辑原生零件。

The package contains reviewable `Build_Binding_Base.bas` text source. **It does not contain a generated or verified `.SLDPRT`.** Windows SOLIDWORKS is unavailable in the authoring environment. The source has not been compiled, executed or rebuilt in SOLIDWORKS 2026. It is auxiliary source, not a substitute for the requested completed native part.

适用范围是当前附件教材第74–95页的任务1–8；旧要求中的第24–54页只作为交付方式参考。

The scope is Tasks 1–8 on the CURRENT attachment's workbook pages 74–95. Pages 24–54 in the quoted earlier request are a delivery-format reference only.

## 自动化范围 / Automation scope

`main()` 尝试在**同一个新建零件**中创建任务1–5，然后明确停下来，等待任务6–8的本机续建。它不自动保存阶段文件或最终文件。

`main()` attempts Tasks 1–5 in **one new part**, then explicitly hands over the remaining local work for Tasks 6–8. It saves neither intermediate stage parts nor a final part.

|入口 / Entry point|范围 / Scope|
|---|---|
|`main()`|任务1：带尺寸的225、80、40、R75轮廓，拉伸25；任务2：3厚弯曲带、径向封口、完全贯穿反侧切除；任务3–5：两个4偏置台、25宽32高3厚侧耳、每耳两个原生草图镜向的弧形槽。 / T1 outline225/80/40/R75 and extrusion25; T2 curved3-thick strip, radial caps and flipped Through All cut; T3–5 two offset4 supports,25-wide32-high3-thick ears, two native sketch-mirrored curved slots per ear.|
|`InsertBendsFromSelectedFace()`|可选任务6辅助。必须先选中央平坦固定面，并明确接受补充K=0.5假设；尝试插入内R3折弯。 / Optional T6 helper: select the central fixed planar face, explicitly accept supplemental K=0.5, then attempt innerR3 Insert Bends.|
|`RollbackBeforeSelectedFeature()`|选中设计树中的加工折弯/Process-Bends特征后，回退到它之前。 / Roll back before the selected Process-Bends tree feature.|
|`RollToEnd()`|将回退控制棒移到末端。 / Move the rollback bar to the end.|
|`SaveReviewedFinal()`|只在本机真正完成任务6–8、通过命名门槛、核查钣金实体并明确确认实测结果后，保存一个新的最终原生零件。 / Save one NEW final native part only after actual local completion of T6–8, named-feature gates, a sheet-metal-body check and explicit confirmation of the reviewed result.|

**任务7的展开态圆角、任务8的中心孔均需按网站手动完成。** 本源码没有假装自动识别这些未经原生软件验证的圆角边线，也没有将构建任务1–5称为完成整个任务。

**T7 flat-state fillets and T8 center hole must be completed manually using the website.** The helper does not pretend to identify those unverified native fillet edges automatically, or present Tasks1–5 as the entire assignment.

## 在 SOLIDWORKS 2026 中使用 / Use in SOLIDWORKS 2026

1. 在 Windows 中打开已授权的 SOLIDWORKS 2026。确认“文件/File → 新建/New → 零件/Part”可以正常建立零件。
   Open licensed SOLIDWORKS 2026 on Windows. Verify that **File → New → Part** works with your ordinary part template.
2. 点击“工具/Tools → 宏/Macro → 新建/New”，把宏保存为 `Binding_Base_Builder.swp`，进入 VBA 编辑器。
   Choose **Tools → Macro → New**, save `Binding_Base_Builder.swp`, and enter the VBA editor.
3. 点击 VBA 编辑器中的“文件/File → 导入文件/Import File”，选择 `Build_Binding_Base.bas`。文本`.bas`不能直接当作`.swp`运行。
   In the VBA editor choose **File → Import File** and select `Build_Binding_Base.bas`. A text `.bas` is not directly runnable as a `.swp` macro.
4. 打开 `Build_Binding_Base` 模块，把光标放在 `Public Sub main()` 内，按 F5/运行子过程/Run Sub。模块采用后期绑定，不要求新增 SOLIDWORKS 类型库引用。
   Open module `Build_Binding_Base`, place the cursor inside `Public Sub main()`, and press **F5 / Run Sub**. The module uses late binding and does not require adding a SOLIDWORKS type-library reference.
5. 若找不到默认模板，输入本机零件模板`.prtdot`的完整路径。文档显示单位设为毫米；API内部长度始终使用米。
   If no default template is found, enter the full local `.prtdot` path. Display units are millimeters; API lengths are meters.
6. 正常到达任务5交接点后，继续按网站完成任务6–8。不要把当前未完成模型当作最终作业。
   If the helper reaches its Task5 handoff, follow the website for Tasks6–8. The current incomplete model is not the final assignment.

源码只给一个新零件增加草图和特征，不覆盖当前已有零件。日志位于“文档/Documents”中的 `Binding_Base_Plate_Helper_日期时间/native_helper_log.txt`。如果出错，宏停止，保留当前未保存零件供检查，并显示阶段与错误信息。

The source adds sketches and features to one new part and does not overwrite an existing part. The log is in Documents/`Binding_Base_Plate_Helper_timestamp/native_helper_log.txt`. On an error it stops, leaves the current unsaved part for inspection and reports the stage and error.

## 必须核查的几何与参数 / Geometry and parameter review

所有尺寸常量位于模块顶部，单位为mm。几何数据依据随附 `geometry_parameters.json` 和 `dimension_audit.md`。先改常量再运行，会重建一个新零件。运行之后也可通过“编辑草图/Edit Sketch”“编辑特征/Edit Feature”和回退控制棒/Rollback Bar 逐步检查、修改。

Millimeter constants are at the top of the module and follow `geometry_parameters.json` and `dimension_audit.md`. Edit them before running to build a new part. After a local run, inspect and modify individual native sketches/features using **Edit Sketch**, **Edit Feature**, and the **Rollback Bar**.

- **草图不是整张固定/Fix。** 仅一个草图参考点和镜向用的构造中心线固定；生产轮廓使用驱动尺寸与几何关系。部分定位尺寸由“完全定义草图/Fully Define Sketch”自动补齐，名称和布置可能因本机版本不同而变化。
  **Production contours are not globally Fixed.** Only a reference datum point and the construction mirror axis are fixed. Production geometry uses driving dimensions and relations. Some positioning dimensions are added by **Fully Define Sketch**; their names/layout can vary locally.
- **此辅助源码没有完整复刻教材的所有设计意图关系。** 任务2用四条已推导半径构造弯曲带；内外圆弧具有同心关系，但没有创建“等距实体/Offset Entities”的原生等距关联。若在成品草图中改板厚，需同时调整对应内外半径并核查等厚性，不能只改一个半径。
  **The helper does not reproduce every workbook design-intent relation.** T2 constructs the band using four derived radii with concentric relations, rather than a native Offset Entities relation. If editing thickness afterward, adjust the corresponding inner/outer radii together and check uniform thickness.
- 弧形槽以R14、R11、端R1.5以及端圆弧圆心弦长6的几何计算初始化；再由驱动尺寸完全定义种子槽，并用原生草图镜向/Sketch Mirror生成第二槽。自动补齐的定位尺寸不一定显示为教材中同样排列的“6”与“6”。
  Curved slots are initialized from outerR14, innerR11, endR1.5 and cap-center chord6, then dimensioned and mirrored natively. Automatically added positioning dimensions may not show the same arrangement of the workbook's “6” dimensions.
- 两个侧耳的32是从底部量起的总高；在中央顶面上方为29。第二侧耳的70沿斜直边局部方向量取。
  Ear32 is total height from the bottom, leaving29 above the central top face. The second ear's70 position is along the sloped straight side.
- 模板必须是通常的零件模板，前/上/右三个默认基准面保持正常结构。若基准面、草图朝向、完全定义或凸台体积增量检查不匹配，程序停止，不会把猜测结果保存为最终文件。
  Use an ordinary part template with the standard Front/Top/Right reference-plane structure. A failed plane, sketch direction, full-definition or boss-volume-increment check stops the procedure without saving a guessed final result.

## 任务6：可选折弯辅助 / Task6 optional bend helper

推荐先按网站“插入/Insert → 钣金/Sheet Metal → 折弯/Bends”完成，这样可以直接查看属性管理器/PropertyManager。

The recommended path is the website's manual **Insert → Sheet Metal → Bends** workflow so you can inspect the PropertyManager directly.

若使用 `InsertBendsFromSelectedFace()`，先选中央平坦顶面，再在VBA编辑器中运行该过程。程序将明确询问是否采用K=0.5。附件没有给出可确定的K因子；截图中的0.5属于自动释放槽/Auto Relief，不能当作K的证据。若教师指定折弯扣除或折弯表，选择“否/No”并手动使用课程参数。

For `InsertBendsFromSelectedFace()`, first select the central flat top face, then run that procedure in VBA. It explicitly asks whether to use K=0.5. The attachment does not establish a K factor; the visible0.5 belongs to Auto Relief. Choose **No** and set the instructor's allowance/table manually when required.

辅助源码中的调用为：
The helper call is:

```vb
model.InsertBends2 0.003, "", 0.5, -1, True, 0.5, True
```

最后一个`True`表示创建钣金/Sheet-Metal、展开折弯/Flatten-Bends和加工折弯/Process-Bends特征；不是“保持最终展开”开关。`UseBendAllowance=-1`表示不使用该替代参数。自动释放槽细节与“Ignore beveled faces/忽略倒斜面”选项仍需在本机属性管理器中检查。

The final`True` creates Sheet-Metal, Flatten-Bends and Process-Bends features; it is not a “leave the final part flattened” switch. `UseBendAllowance=-1` disables that alternative. Inspect the actual auto-relief details and **Ignore beveled faces** option locally.

## 任务7–8与最终保存 / Tasks7–8 and final save

按网站操作，在展开折弯/Flatten-Bends与加工折弯/Process-Bends之间回退。
Follow the website and roll back between Flatten-Bends and Process-Bends.

1. 在平展状态给三个外尖角加R15；两个侧耳顶端共四角加R6；侧耳根部共四个凹角加R2。
   In the flat state apply R15 to the three outer sharp corners, R6 to the four distal ear corners, and R2 to the four reentrant ear roots.
2. 将这三项圆角特征分别重命名为 `F_T7_R15`、`F_T7_R6`、`F_T7_R2`。
   Rename those three fillet features `F_T7_R15`, `F_T7_R6`, and `F_T7_R2`.
3. 在展开平板的中央上表面画Ø76圆；圆心距右侧直边50、距**展开后的下端横边**110。110不能直接套用到原始折弯坐标。
   Sketch a D76 circle on the central top face of the flattened blank. Its center is50 from the right straight edge and110 from the **flattened bottom transverse edge**. Do not apply110 directly in the original bent coordinates.
4. 用“拉伸切除/Extruded Cut”，勾选“关联到厚度/Link To Thickness”。将该切除特征重命名为 `F_T8_HoleD76`。
   Use **Extruded Cut**, enable **Link To Thickness**, and rename the cut feature `F_T8_HoleD76`.
5. 右键加工折弯/Process-Bends，选择“滚动到末尾/Roll To End”，再检查能否正确展开/Flatten和重新折弯。
   Right-click Process-Bends and select **Roll To End**, then verify that the part flattens and refolds correctly.
6. 在VBA编辑器内运行 `SaveReviewedFinal()`。该过程检查四个命名特征及一个原生钣金实体，并要求你确认实际核查结果，随后提示一个新的`.SLDPRT`路径。默认名为 `Binding_Base_Plate_FINAL.SLDPRT`。
   Run `SaveReviewedFinal()` in VBA. It checks the four named features and one native sheet-metal body, asks you to confirm the actual reviewed result, and requests a NEW`.SLDPRT`path, defaulting to `Binding_Base_Plate_FINAL.SLDPRT`.

**名称门槛只能防止误把明显未完成模型保存为最终文件，不是对圆角选边、孔位、厚度或完整性的数学证明。** 需要在真实SOLIDWORKS中检查设计树、草图、重建状态和展开结果。现有文件不会被覆盖；新保存失败时程序会尝试清理本次新产生的失败输出，不生成其他格式冒充原生零件。

**Named-feature gates prevent an obviously incomplete save; they do not prove correct edge selection, hole placement, thickness or completeness.** Inspect the actual SOLIDWORKS tree, sketches, rebuild state and flattening result. Existing files are not overwritten. A failed new save attempts to remove its own new failed output; no alternate-format file is renamed as a native part.

## 已做与未做的验证 / Verification performed and remaining

已做：关键参数与已核对的尺寸数据对照；VBA过程开闭配对；FeatureExtrusion2的23个参数、FeatureCut3的26个参数、InsertBends2的7个参数、FullyDefineSketch的10个参数静态计数；确认仅一处SaveAs且不在main或失败自动保存路径中。

Performed: comparison with the audited parameters, procedure pairing, static argument counts for FeatureExtrusion2(23), FeatureCut3(26), InsertBends2(7) and FullyDefineSketch(10), and confirmation of one isolated SaveAs call outside main and automatic failure paths.

未做：VBA编译、SOLIDWORKS2026运行、草图求解器实测、原生钣金转换及特征树实测。**静态检查通过不代表宏已在SOLIDWORKS运行成功。**

Not performed: VBA compilation, SOLIDWORKS2026 execution, native sketch-solver testing, or native sheet-metal/tree testing. **Passing static checks is not evidence of a successful SOLIDWORKS run.**

## 官方API参考 / Official API references

- [InsertBends2 — IPartDoc](https://help.solidworks.com/2020/english/api/sldworksapi/SolidWorks.Interop.sldworks~SolidWorks.Interop.sldworks.IPartDoc~InsertBends2.html)：7参数及DoFlatten语义。 / Seven arguments and DoFlatten meaning.
- [FeatureCut3 — IFeatureManager](https://help.solidworks.com/2020/English/api/sldworksapi/SolidWorks.Interop.sldworks~SolidWorks.Interop.sldworks.IFeatureManager~FeatureCut3.html)：26参数。 /26arguments.
- [FlipSideToCut — IExtrudeFeatureData2](https://help.solidworks.com/2026/english/api/sldworksapi/SOLIDWORKS.Interop.sldworks~SOLIDWORKS.Interop.sldworks.IExtrudeFeatureData2~FlipSideToCut.html)：外侧切除属性。 /Outside-cut property.
- [FullyDefineSketch — ISketchManager](https://help.solidworks.com/2015/english/api/sldworksapi/SOLIDWORKS.Interop.sldworks~SOLIDWORKS.Interop.sldworks.ISketchManager~FullyDefineSketch.html)：驱动尺寸与基准参数。 /Dimensions and datum arguments.
- [Move rollback bar using a feature — VBA](https://help.solidworks.com/2026/english/api/sldworksapi/Move_Rollback_Bar_Using_Feature_Example_VB.htm)：回退接口示例。 /Rollback API example.
- [swMoveRollbackBarTo_e](https://help.solidworks.com/2026/English/api/swconst/SolidWorks.Interop.swconst~SolidWorks.Interop.swconst.swMoveRollbackBarTo_e.html)：BeforeFeature=3，End=1。 /BeforeFeature=3,End=1.
- [IFace2.GetClosestPointOn](https://help.solidworks.com/2025/English/api/sldworksapi/SolidWorks.Interop.sldworks~SolidWorks.Interop.sldworks.IFace2~GetClosestPointOn.html)：几何位置选面。 /Geometric face location.

以上部分接口链接使用可检索的旧版官方API说明核对长期存在的签名；这不构成SOLIDWORKS2026运行兼容性声明。

Some signature references use accessible older official API versions for long-standing methods. This does not establish tested SOLIDWORKS2026 runtime compatibility.
