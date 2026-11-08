# 固定器底板参考模型 / Binding Base Plate reference models

## 文件 / Files

- `Binding_Base_Plate_FINAL.step`：最终弯曲状态的参考实体，可导入支持STEP的CAD软件。 / Final bent reference solid, importable into STEP-capable CAD software.
- `Binding_Base_Plate_FLAT_K0p5.step`：K=0.5假设下的平展参考实体。 / Flat reference solid under the supplemental K=0.5 assumption.
- `index.html`内嵌12阶段教学网格；单位毫米，显示坐标减去(-50,110,0)。运行源码也会导出`meshes.json`。 / The website embeds all twelve teaching meshes; mm, translated by subtracting (-50,110,0). Reconstruction also exports `meshes.json`.
- `parameters.json`：重建尺寸。 / Reconstruction parameters.
- `validation.json`：各阶段有效性、体积、单实体检查、STEP回读结果和模型限制。 / Stage validity, volume, single-solid checks, STEP round-trip checks, and modeling limitations.
- 运行源码会生成`01_…12_….brep`各阶段Open CASCADE实体缓存，本包未另附这些缓存。 / Reconstruction creates Open CASCADE BREP caches for every stage; those caches are not separately included in this package.

## 重建 / Rebuild

主源码为同目录的`model_engine.py`。使用Python及CadQuery 2.7或兼容版本，修改`parameters.json`中的值，然后运行：

The source is `model_engine.py` in the same folder. With Python and CadQuery 2.7 or a compatible version, edit `parameters.json` and run:

```text
python model_engine.py --params parameters.json --out rebuilt_models
```

源码分别保留坯料、弯曲底板、偏置、侧耳、槽、折弯、展开、圆角和孔等函数，便于查看与重建步骤。

The source separates the block, curved plate, offsets, tabs, slots, bends, flat state, corner rounding, and center hole into inspectable reconstruction functions.

## 交付性质 / Delivery status

这些是参考BREP实体和建模源码，**不是带SOLIDWORKS特征树的原生SLDPRT**。STEP导入后不会自动获得原来的草图、凸台、切除、钣金和回退历史。没有运行SOLIDWORKS进行验证。

These are reference BREP solids and reconstruction source, **not native SLDPRT files with a SOLIDWORKS feature tree**. STEP import does not restore original sketches, bosses, cuts, sheet-metal features, or rollback history. No SOLIDWORKS runtime verification was performed.

12个预览阶段均通过Open CASCADE的有效性检查，并且每阶段为一个实体。两个STEP均成功导出、重新导入，并确认是有效单实体。这证明参考文件结构可读取，不等于SOLIDWORKS运行测试。

All twelve preview stages passed Open CASCADE validity checks and contain one solid each. Both STEP files were exported, reimported, and checked as valid single solids. This establishes file-level readability, not a SOLIDWORKS runtime test.

教材未给出可读的K因子，因此平展模型显式采用K=0.5。原生钣金展开对斜切端面、自动释放槽和圆角的处理可能不同。本参考模型最终R15使用平面轮廓圆角后与曲板相交；平展模型R15为平面圆角。R2耳根跨弯部分使用细分放样重构。两个状态不是原生钣金严格互逆的展开/折回，其最终体积相差约50.85mm³（约0.088%）。完整限制见`validation.json`。

The workbook does not state a readable K factor, so the flat model explicitly assumes K=0.5. Native sheet-metal treatment of beveled end faces, automatic reliefs, and corner rounding may differ. Final bent R15 corners use a rounded plan mask intersected with the curved plate; flat R15 corners are planar fillets. The short bent portion of each R2 root blend is reconstructed with a fine sectional loft. The flat and bent reference states are not exact inverse native sheet-metal operations; their final volumes differ by about 50.85mm³ (about 0.088%). See `validation.json` for full limits.
