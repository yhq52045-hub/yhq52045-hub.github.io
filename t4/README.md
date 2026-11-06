# T4 固定器锚盘 / Binding Anchor

公开教学网址 / Teaching website: https://yhq52045-hub.github.io/t4/

下载完整资料后解压，双击 index.html。中文和英文教学、原页图像及七阶段教学预览均内嵌，可以离线学习。Word、PDF在files文件夹。
Extract the complete materials and open index.html. Chinese/English instructions, source-page images and seven visual teaching stages are embedded for offline use. Word/PDF files are in files/.

## 原生文件交付状态 / Native part status

目标是一个 Binding_Anchor_FINAL.SLDPRT，所有草图、凸台、切除、圆角均位于同一可编辑特征树。当前执行环境不能运行SOLIDWORKS，实际原生文件尚未生成或验证，资料包不包含该文件。建模源代码只能作为辅助，不能代替用户要求的原生文件交付。
The target is one Binding_Anchor_FINAL.SLDPRT with editable sketches, bosses, cuts and fillets in a single tree. SOLIDWORKS is unavailable here, so this native file has not been generated or verified and is not in this package. The build source is auxiliary and is not a substitute native-file deliverable.

files/Binding_Anchor_Final_Geometry.step 是已校核的最终精确实体，可以在SOLIDWORKS中读取，但没有草图/特征历史。files/READ_ME_NATIVE_ZH_EN.md说明单一最终零件生成及修改方法。脚本仅保存一个最终零件，在内存中验证七个阶段，不另存阶段文件。
files/Binding_Anchor_Final_Geometry.step is the validated final exact solid, readable by SOLIDWORKS without original feature history. files/READ_ME_NATIVE_ZH_EN.md describes native construction and editing. The source saves only one final part, validating seven stages in memory without separate stage files.

## 尺寸 / Dimensions

首圆盘按用户确认Ø82×3.5mm；底凸台Ø75×3；凹槽Ø63切深3；四槽R4、圆心距16、总长24，位置x=±12、y=±6/±22，完全贯穿；外上缘R1.5，凹槽底缘和上口R1。最终体积19765.727487mm³，密度0.0028g/mm³时质量55.34403696g。
Confirmed baseØ82×3.5mm; bottom bossØ75×3; recessØ63 depth3; four through slotsR4, center separation16, overall24 atx=±12,y=±6/±22; outer topR1.5 and recessfloor/upperrimR1. Final volume19765.727487mm³, mass55.34403696g at0.0028g/mm³.

## 验证 / Verification

文档32页（说明+31组），所有原图保留。几何与教材质量结果一致。网站JavaScript、44步、7阶段、31原页和所有本地下载链接经过检查；未进行浏览器GPU交互实测。原生生成代码只通过静态检查，未在SOLIDWORKS运行。
Documents have32pages (notes+31pairs), retaining all original images. Geometry matches workbook mass. JavaScript,44steps,7stages,31sourcepages and local links were checked. Browser GPU interaction and SOLIDWORKS runtime have not been tested.
