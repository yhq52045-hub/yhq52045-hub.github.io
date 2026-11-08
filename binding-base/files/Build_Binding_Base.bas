Attribute VB_Name = "Build_Binding_Base"
Option Explicit
' Binding Base Plate, workbook pp.74-95, SOLIDWORKS VBA helper source.
' STATUS: NOT EXECUTED IN SOLIDWORKS. This file is not a delivered SLDPRT.
' main builds Tasks 1-5 in ONE UNSAVED part, then explicitly hands over T6-T8.
' Optional InsertBendsFromSelectedFace / rollback helpers require user selection.
' T7 flat-state fillets and T8 thickness-linked hole are MANUAL website steps.
' SaveReviewedFinal is separate, checks named completion features, and asks for
' actual local review. No automatic partial/failure path saves a FINAL part.
' API lengths are meters; all workbook parameters below are millimeters.

Private Const PI As Double = 3.14159265358979
Private Const PLAN_LENGTH As Double = 225#
Private Const BOTTOM_WIDTH As Double = 80#
Private Const TOP_WIDTH As Double = 40#
Private Const PLAN_RADIUS As Double = 75#
Private Const BLOCK_DEPTH As Double = 25#
Private Const THICKNESS As Double = 3#
Private Const CURVE_LEFT_RUN As Double = 40#
Private Const CURVE_RIGHT_INSET As Double = 65#
Private Const EAR_WIDTH As Double = 25#
Private Const EAR1_POSITION As Double = 120#
Private Const EAR2_POSITION As Double = 70#
Private Const EAR_OFFSET As Double = 4#
Private Const EAR_HEIGHT As Double = 32#
Private Const EAR_THICKNESS As Double = 3#
Private Const SLOT_OUTER_R As Double = 14#
Private Const SLOT_END_R As Double = 1.5
Private Const SLOT_NEAR_CENTER_SPACING As Double = 6#
Private Const SLOT_CENTER_TOP_INSET As Double = 6#
Private Const SLOT_CAP_CENTER_CHORD As Double = 6#
Private Const BEND_INNER_R As Double = 3#
Private Const AUTO_RELIEF_RATIO As Double = 0.5
' This is an OPTIONAL assumption, not the 0.5 in the workbook relief panel.
Private Const OPTIONAL_K_FACTOR As Double = 0.5

Private swApp As Object, model As Object, sm As Object, fm As Object
Private mu As Object, topToModel As Object, modelToTop As Object
Private activeSketch As Object, sketchFeature As Object, currentStage As String
Private fso As Object, logFile As Object, logFolder As String
Private oldDimPrompt As Boolean, preferenceSaved As Boolean, topSign As Double
Private slopeUX As Double, slopeUY As Double

Public Sub main()
    Dim template As String, plane As Object, feature As Object
    Dim beforeVolume As Double, afterVolume As Double, reverseCut As Boolean
    On Error GoTo Failed
    currentStage = "Connect and create a NEW document"
    Set swApp = GetObject(, "SldWorks.Application")
    If swApp Is Nothing Then StopBuild "Open licensed SOLIDWORKS 2026 first."
    Set fso = CreateObject("Scripting.FileSystemObject")
    logFolder = NewLogFolder()
    Set logFile = fso.CreateTextFile(logFolder & "\native_helper_log.txt", True, True)
    WriteLog "UNVERIFIED HELPER SOURCE. Started " & CStr(Now)
    WriteLog "Scope main: Tasks 1-5 ONLY. No SLDPRT is saved by main."
    template = swApp.GetUserPreferenceStringValue(8)
    If Len(template) = 0 Then template = InputBox("Full path to your Part template (.prtdot):", "Binding Base Plate template")
    If Len(template) = 0 Then StopBuild "No part template selected."
    Set model = swApp.NewDocument(template, 0, 0, 0)
    If model Is Nothing Then StopBuild "Cannot create a part using that template."
    Set sm = model.SketchManager
    Set fm = model.FeatureManager
    Set mu = swApp.GetMathUtility
    model.SetUnits 0, 1, 0, 3, False
    oldDimPrompt = swApp.GetUserPreferenceToggle(10)
    preferenceSaved = True
    swApp.SetUserPreferenceToggle 10, False
    topSign = 1#

    currentStage = "T1: dimensioned outline and 25 mm block"
    Set plane = FindTopPlane()
    model.ClearSelection2 True
    If Not plane.Select2(False, 0) Then StopBuild "Cannot select Top reference plane."
    BeginSketch "S_T1_Outline225_80_40_R75"
    Set modelToTop = activeSketch.ModelToSketchTransform
    Set topToModel = modelToTop.Inverse
    MakePlanOutline
    CloseSketch
    Set feature = MakeBoss(BLOCK_DEPTH, "F_T1_Block25", False)
    DetermineThicknessSign
    ValidateStage "T1"
    beforeVolume = VolumeMM3()

    currentStage = "T2: curved 3 mm strip and Flip Side To Cut"
    BeginSketchAt Array(0#, 100#, BLOCK_DEPTH / 2#), "S_T2_CurvedStrip3"
    MakeCookieProfile
    reverseCut = ReverseForDirection(Array(-1#, 0#, 0#), True)
    CloseSketch
    Set feature = MakeCut(1, 500#, True, "F_T2_FlipSideThroughAll", reverseCut)
    If Not feature.GetDefinition.FlipSideToCut Then StopBuild "Cut did not retain FlipSideToCut=True."
    ValidateStage "T2"
    afterVolume = VolumeMM3()
    If afterVolume / beforeVolume > 0.3 Or afterVolume / beforeVolume < 0.04 Then StopBuild "T2 volume check failed; inspect cut side and direction."

    currentStage = "T3-T4: first offset, tab and two curved slots"
    MakeEar 1, 0#, 0#, 0#, 1#, 1#, 0#, EAR1_POSITION
    currentStage = "T5: second offset, tab and two curved slots"
    MakeEar 2, -BOTTOM_WIDTH, 0#, slopeUX, slopeUY, -slopeUY, slopeUX, EAR2_POSITION
    ValidateStage "T5 - MANUAL T6-T8 REMAIN"
    SetTag "NativeHelperScope", "Tasks1-5 only; Tasks6-8 require completion"
    SetTag "WorkbookPages", "74-95"
    SetTag "HelperRuntimeStatus", "Source supplied unexecuted; inspect local run"
    model.ShowNamedView2 "", 7
    model.ViewZoomtofit2
    model.GraphicsRedraw2
    WriteLog "HANDOFF: no final file saved. Complete T6-T8 in the teaching website."
    RestorePreferences
    CloseLog
    MsgBox "Tasks 1-5 have been built in ONE UNSAVED part." & vbCrLf & _
           "REQUIRED: complete Task 6 sheet-metal bends, Task 7 FLAT-STATE fillets," & vbCrLf & _
           "and Task 8 D76 thickness-linked hole, then Roll To End." & vbCrLf & _
           "See the bilingual website and native_builder_README.md." & vbCrLf & _
           "No FINAL SLDPRT has been created by this procedure." & vbCrLf & _
           "Log: " & logFolder, vbInformation, "Binding Base Plate: manual completion required"
    Exit Sub
Failed:
    WriteLog "STOPPED at " & currentStage & ": " & CStr(Err.Number) & " " & Err.Description
    MsgBox "Build STOPPED at: " & currentStage & vbCrLf & _
           "Error " & CStr(Err.Number) & ": " & Err.Description & vbCrLf & _
           "No FINAL file was saved. Inspect the current unsaved part." & vbCrLf & _
           "Log folder: " & logFolder, vbCritical, "Binding Base Plate helper stopped"
    RestorePreferences
    CloseLog
End Sub

Private Sub MakePlanOutline()
    Dim cx As Double, cy As Double, vx As Double, vy As Double
    Dim d2 As Double, a As Double, b As Double, tx As Double, ty As Double
    Dim lengthSide As Double, rightLine As Object, topLine As Object
    Dim arc As Object, sideLine As Object, bottomLine As Object, origin As Object
    cx = -TOP_WIDTH: cy = PLAN_LENGTH - PLAN_RADIUS
    vx = -BOTTOM_WIDTH - cx: vy = -cy
    d2 = vx * vx + vy * vy
    If d2 <= PLAN_RADIUS * PLAN_RADIUS Then StopBuild "Plan dimensions do not permit the tangent side."
    a = PLAN_RADIUS * PLAN_RADIUS / d2
    b = PLAN_RADIUS * Sqr(d2 - PLAN_RADIUS * PLAN_RADIUS) / d2
    tx = cx + a * vx + b * vy
    ty = cy + a * vy - b * vx
    lengthSide = Sqr((tx + BOTTOM_WIDTH) ^ 2 + ty ^ 2)
    slopeUX = (tx + BOTTOM_WIDTH) / lengthSide
    slopeUY = ty / lengthSide
    Set rightLine = AddLine(Array(0#, 0#, 0#), Array(0#, PLAN_LENGTH, 0#))
    Set topLine = AddLine(Array(0#, PLAN_LENGTH, 0#), Array(-TOP_WIDTH, PLAN_LENGTH, 0#))
    Set arc = AddArcAbout(Array(cx, cy, 0#), Array(-TOP_WIDTH, PLAN_LENGTH, 0#), Array(tx, ty, 0#))
    Set sideLine = AddLine(Array(tx, ty, 0#), Array(-BOTTOM_WIDTH, 0#, 0#))
    Set bottomLine = AddLine(Array(-BOTTOM_WIDTH, 0#, 0#), Array(0#, 0#, 0#))
    JoinLoop Array(rightLine, topLine, arc, sideLine, bottomLine)
    RelateOne rightLine, "sgVERTICAL2D"
    RelateOne topLine, "sgHORIZONTAL2D"
    RelateOne bottomLine, "sgHORIZONTAL2D"
    RelateTwo topLine, arc, "sgTANGENT"
    RelateTwo arc, sideLine, "sgTANGENT"
    Set origin = DatumPoint()
    RelateTwo rightLine.GetStartPoint2, origin, "sgCOINCIDENT"
    AddLengthDimension rightLine, PLAN_LENGTH, "PlanLength225"
    AddLengthDimension topLine, TOP_WIDTH, "TopWidth40"
    AddLengthDimension bottomLine, BOTTOM_WIDTH, "BottomWidth80"
    AddRadiusDimension arc, PLAN_RADIUS, "PlanRadius75"
    FullyDimensionSketch origin
    WriteLog "T1 tangent point mm: " & CStr(tx) & ", " & CStr(ty)
End Sub

Private Sub MakeCookieProfile()
    Dim h As Double, rL As Double, rR As Double, yR As Double
    Dim leftCenter, rightCenter, leftLow, rightLow, leftUp, rightUp
    Dim seg(7) As Object, datum As Object
    h = BLOCK_DEPTH / 2#
    yR = PLAN_LENGTH - CURVE_RIGHT_INSET
    rL = (CURVE_LEFT_RUN ^ 2 + h ^ 2) / (2# * h)
    rR = (CURVE_RIGHT_INSET ^ 2 + h ^ 2) / (2# * h)
    leftCenter = Array(0#, CURVE_LEFT_RUN, rL)
    rightCenter = Array(0#, yR, rR)
    leftLow = Array(0#, 0#, h)
    rightLow = Array(0#, PLAN_LENGTH, h)
    leftUp = RadialOffsetPoint(leftCenter, leftLow, rL - THICKNESS)
    rightUp = RadialOffsetPoint(rightCenter, rightLow, rR - THICKNESS)
    Set seg(0) = AddLine(Array(0#, CURVE_LEFT_RUN, 0#), Array(0#, yR, 0#))
    Set seg(1) = AddArcAbout(rightCenter, Array(0#, yR, 0#), rightLow)
    Set seg(2) = AddLine(rightLow, rightUp)
    Set seg(3) = AddArcAbout(rightCenter, rightUp, Array(0#, yR, THICKNESS))
    Set seg(4) = AddLine(Array(0#, yR, THICKNESS), Array(0#, CURVE_LEFT_RUN, THICKNESS))
    Set seg(5) = AddArcAbout(leftCenter, Array(0#, CURVE_LEFT_RUN, THICKNESS), leftUp)
    Set seg(6) = AddLine(leftUp, leftLow)
    Set seg(7) = AddArcAbout(leftCenter, leftLow, Array(0#, CURVE_LEFT_RUN, 0#))
    JoinLoop Array(seg(0), seg(1), seg(2), seg(3), seg(4), seg(5), seg(6), seg(7))
    RelateTwo seg(0), seg(1), "sgTANGENT"
    RelateTwo seg(0), seg(7), "sgTANGENT"
    RelateTwo seg(4), seg(3), "sgTANGENT"
    RelateTwo seg(4), seg(5), "sgTANGENT"
    RelateTwo seg(1), seg(3), "sgCONCENTRIC"
    RelateTwo seg(5), seg(7), "sgCONCENTRIC"
    AddRadiusDimension seg(7), rL, "LeftOuterR"
    AddRadiusDimension seg(1), rR, "RightOuterR"
    AddRadiusDimension seg(5), rL - THICKNESS, "LeftInnerR"
    AddRadiusDimension seg(3), rR - THICKNESS, "RightInnerR"
    ' Arc radii are independent driving dimensions here, not an Offset-Entities
    ' relation. Edit inner/outer radii together to retain 3 mm normal thickness.
    Set datum = DatumPoint()
    FullyDimensionSketch datum
    WriteLog "Cookie radii outer/inner: " & rL & "/" & rL - THICKNESS & "; " & rR & "/" & rR - THICKNESS
End Sub

Private Sub MakeEar(ByVal number As Long, ByVal ox As Double, ByVal oy As Double, _
                    ByVal ux As Double, ByVal uy As Double, ByVal nx As Double, _
                    ByVal ny As Double, ByVal startS As Double)
    Dim prefix As String, feature As Object, beforeVolume As Double, expectDelta As Double
    Dim support, p0, p1, p2, p3, direction, reverseBoss As Boolean
    prefix = "E" & CStr(number)
    support = EarPoint(ox, oy, ux, uy, nx, ny, startS + EAR_WIDTH / 2#, THICKNESS / 2#, 0#)
    BeginSketchAt support, "S_" & prefix & "_Offset"
    p0 = EarPoint(ox, oy, ux, uy, nx, ny, startS, 0#, 0#)
    p1 = EarPoint(ox, oy, ux, uy, nx, ny, startS + EAR_WIDTH, 0#, 0#)
    p2 = EarPoint(ox, oy, ux, uy, nx, ny, startS + EAR_WIDTH, THICKNESS, 0#)
    p3 = EarPoint(ox, oy, ux, uy, nx, ny, startS, THICKNESS, 0#)
    MakeRectangle p0, p1, p2, p3, EAR_WIDTH, THICKNESS, prefix & "Offset"
    direction = Array(nx, ny, 0#)
    reverseBoss = ReverseForDirection(direction, False)
    CloseSketch
    beforeVolume = VolumeMM3()
    Set feature = MakeBoss(EAR_OFFSET, "F_" & prefix & "_Offset4", reverseBoss)
    expectDelta = EAR_WIDTH * THICKNESS * EAR_OFFSET
    CheckDelta beforeVolume, expectDelta, prefix & " offset direction"
    ValidateStage prefix & " offset"

    support = EarPoint(ox, oy, ux, uy, nx, ny, startS + EAR_WIDTH / 2#, THICKNESS / 2#, EAR_OFFSET)
    BeginSketchAt support, "S_" & prefix & "_Tab32x25"
    p0 = EarPoint(ox, oy, ux, uy, nx, ny, startS, 0#, EAR_OFFSET)
    p1 = EarPoint(ox, oy, ux, uy, nx, ny, startS + EAR_WIDTH, 0#, EAR_OFFSET)
    p2 = EarPoint(ox, oy, ux, uy, nx, ny, startS + EAR_WIDTH, EAR_HEIGHT, EAR_OFFSET)
    p3 = EarPoint(ox, oy, ux, uy, nx, ny, startS, EAR_HEIGHT, EAR_OFFSET)
    MakeRectangle p0, p1, p2, p3, EAR_WIDTH, EAR_HEIGHT, prefix & "Tab"
    reverseBoss = ReverseForDirection(direction, False)
    CloseSketch
    beforeVolume = VolumeMM3()
    Set feature = MakeBoss(EAR_THICKNESS, "F_" & prefix & "_TabThickness3", reverseBoss)
    expectDelta = EAR_WIDTH * EAR_HEIGHT * EAR_THICKNESS
    CheckDelta beforeVolume, expectDelta, prefix & " tab direction"
    ValidateStage prefix & " tab"

    support = EarPoint(ox, oy, ux, uy, nx, ny, startS + EAR_WIDTH / 2#, 18#, EAR_OFFSET + EAR_THICKNESS)
    BeginSketchAt support, "S_" & prefix & "_MirroredCurvedSlots"
    MakeMirroredCurvedSlots ox, oy, ux, uy, nx, ny, startS
    reverseBoss = ReverseForDirection(Array(-nx, -ny, 0#), True)
    CloseSketch
    beforeVolume = VolumeMM3()
    Set feature = MakeCut(2, EAR_THICKNESS, False, "F_" & prefix & "_SlotsUpToNext", reverseBoss)
    If VolumeMM3() >= beforeVolume - 0.1 Then StopBuild "Tab slots did not remove material: " & prefix
    ValidateStage prefix & " two curved slots"
End Sub

Private Sub MakeRectangle(p0, p1, p2, p3, ByVal width As Double, ByVal height As Double, ByVal prefix As String)
    Dim seg(3) As Object, datum As Object, i As Long, a, b
    Set seg(0) = AddLine(p0, p1)
    Set seg(1) = AddLine(p1, p2)
    Set seg(2) = AddLine(p2, p3)
    Set seg(3) = AddLine(p3, p0)
    JoinLoop Array(seg(0), seg(1), seg(2), seg(3))
    For i = 0 To 3
        a = PointInSketchPoint(seg(i).GetStartPoint2)
        b = PointInSketchPoint(seg(i).GetEndPoint2)
        If Abs(a(0) - b(0)) < 0.0000001 Then
            RelateOne seg(i), "sgVERTICAL2D"
        ElseIf Abs(a(1) - b(1)) < 0.0000001 Then
            RelateOne seg(i), "sgHORIZONTAL2D"
        Else
            StopBuild "A side rectangle is not aligned with this face-sketch axes."
        End If
    Next
    AddLengthDimension seg(0), width, prefix & "Width"
    AddLengthDimension seg(1), height, prefix & "Height"
    Set datum = DatumPoint()
    FullyDimensionSketch datum
End Sub

Private Sub MakeMirroredCurvedSlots(ByVal ox As Double, ByVal oy As Double, ByVal ux As Double, ByVal uy As Double, _
                                    ByVal nx As Double, ByVal ny As Double, ByVal startS As Double)
    Dim trackR As Double, halfGap As Double, aH As Double, oH As Double
    Dim thetaA As Double, sweep As Double, thetaB As Double, n As Double
    Dim aU As Double, bU As Double, bH As Double, sMid As Double
    Dim oa, ob, ib, ia, capA, capB, center, seg(3) As Object
    Dim axis As Object, datum As Object, selectionData As Object, allSeg, item As Object
    Dim i As Long, count As Long
    trackR = SLOT_OUTER_R - SLOT_END_R
    halfGap = SLOT_NEAR_CENTER_SPACING / 2#
    aU = halfGap: aH = EAR_HEIGHT - SLOT_CENTER_TOP_INSET
    If trackR <= halfGap Or SLOT_CAP_CENTER_CHORD >= 2# * trackR Then StopBuild "Slot parameters have no valid arcs."
    oH = aH - Sqr(trackR * trackR - halfGap * halfGap)
    thetaA = Atn(halfGap / Sqr(trackR * trackR - halfGap * halfGap))
    sweep = 2# * Atn((SLOT_CAP_CENTER_CHORD / (2# * trackR)) / Sqr(1# - (SLOT_CAP_CENTER_CHORD / (2# * trackR)) ^ 2))
    thetaB = thetaA + sweep
    bU = trackR * Sin(thetaB): bH = oH + trackR * Cos(thetaB)
    sMid = startS + EAR_WIDTH / 2#: n = EAR_OFFSET + EAR_THICKNESS
    center = EarPoint(ox, oy, ux, uy, nx, ny, sMid, oH, n)
    oa = EarPoint(ox, oy, ux, uy, nx, ny, sMid + SLOT_OUTER_R * Sin(thetaA), oH + SLOT_OUTER_R * Cos(thetaA), n)
    ob = EarPoint(ox, oy, ux, uy, nx, ny, sMid + SLOT_OUTER_R * Sin(thetaB), oH + SLOT_OUTER_R * Cos(thetaB), n)
    ib = EarPoint(ox, oy, ux, uy, nx, ny, sMid + (trackR - SLOT_END_R) * Sin(thetaB), oH + (trackR - SLOT_END_R) * Cos(thetaB), n)
    ia = EarPoint(ox, oy, ux, uy, nx, ny, sMid + (trackR - SLOT_END_R) * Sin(thetaA), oH + (trackR - SLOT_END_R) * Cos(thetaA), n)
    capB = EarPoint(ox, oy, ux, uy, nx, ny, sMid + bU + SLOT_END_R * Cos(thetaB), bH - SLOT_END_R * Sin(thetaB), n)
    capA = EarPoint(ox, oy, ux, uy, nx, ny, sMid + aU - SLOT_END_R * Cos(thetaA), aH + SLOT_END_R * Sin(thetaA), n)
    Set seg(0) = AddArcAbout(center, oa, ob)
    Set seg(1) = AddArcThree(ob, ib, capB)
    Set seg(2) = AddArcAbout(center, ib, ia)
    Set seg(3) = AddArcThree(ia, oa, capA)
    JoinLoop Array(seg(0), seg(1), seg(2), seg(3))
    For i = 0 To 3
        RelateTwo seg(i), seg((i + 1) Mod 4), "sgTANGENT"
    Next
    RelateTwo seg(0), seg(2), "sgCONCENTRIC"
    AddRadiusDimension seg(0), SLOT_OUTER_R, "SlotOuterRadius14"
    AddRadiusDimension seg(1), SLOT_END_R, "SlotCapRadius1p5"
    Set axis = AddLine(EarPoint(ox, oy, ux, uy, nx, ny, sMid, 0#, n), EarPoint(ox, oy, ux, uy, nx, ny, sMid, EAR_HEIGHT + 4#, n))
    axis.ConstructionGeometry = True
    ' ONLY this construction reference and the datum are fixed. No slot contour is fixed.
    RelateOne axis, "sgFIXED"
    Set datum = DatumPoint()
    FullyDimensionSketch datum
    model.ClearSelection2 True
    Set selectionData = model.SelectionManager.CreateSelectData
    selectionData.Mark = 1
    For i = 0 To 3
        If Not seg(i).Select4(True, selectionData) Then StopBuild "Cannot select seed slot for mirror."
    Next
    selectionData.Mark = 2
    If Not axis.Select4(True, selectionData) Then StopBuild "Cannot select slot mirror axis."
    model.SketchMirror
    allSeg = activeSketch.GetSketchSegments
    count = 0
    For i = 0 To UBound(allSeg)
        Set item = allSeg(i)
        If Not item.ConstructionGeometry Then count = count + 1
    Next
    If count <> 8 Then StopBuild "Native sketch mirror did not produce two four-arc slot contours."
    If Not activeSketch.IsFullyDefined Then StopBuild "Mirrored slots remain underdefined; inspect the sketch."
End Sub

' OPTIONAL T6 helper. Select exactly the central fixed planar face before running.
' This deliberately asks about K; K=0.5 is a supplemental assumption, not a source value.
Public Sub InsertBendsFromSelectedFace()
    Dim face As Object, status As Boolean, answer As VbMsgBoxResult
    On Error GoTo Failed
    AttachActivePart
    currentStage = "Optional T6: selected fixed face and InsertBends2"
    If model.SelectionManager.GetSelectedObjectCount2(-1) <> 1 Then StopBuild "Select exactly ONE central flat top face first."
    If model.SelectionManager.GetSelectedObjectType3(1, -1) <> 2 Then StopBuild "The selected entity must be a FACE."
    Set face = model.SelectionManager.GetSelectedObject6(1, -1)
    If Not face.GetSurface.IsPlane Then StopBuild "The fixed face must be planar."
    answer = MsgBox("The source pages do NOT specify K-factor." & vbCrLf & _
                   "Use supplemental K = 0.5 for this local attempt?" & vbCrLf & _
                   "Choose No to set your instructor's allowance manually instead.", vbYesNo + vbQuestion, "Explicit bend-allowance assumption")
    If answer <> vbYes Then Exit Sub
    ' UseBendAllowance=-1 disables that alternative. DoFlatten=True creates
    ' Sheet-Metal + Flatten-Bends + Process-Bends, per official API documentation.
    status = model.InsertBends2(BEND_INNER_R / 1000#, "", OPTIONAL_K_FACTOR, -1#, True, AUTO_RELIEF_RATIO, True)
    If Not status Then StopBuild "InsertBends2 failed; no automatic fillets or final save were attempted."
    ValidateStage "Optional T6 only"
    SetTag "BendAllowanceAssumption", "K=0.5 explicitly chosen by local user; not specified in source"
    MsgBox "Bends inserted; inspect radius 3 mm, fixed face and rectangular relief in SOLIDWORKS." & vbCrLf & _
           "Complete T7 and T8 manually in the flattened state. No final file saved.", vbInformation
    Exit Sub
Failed:
    MsgBox "Optional bend helper stopped: " & Err.Description & vbCrLf & "No final file saved.", vbCritical
End Sub

Public Sub RollbackBeforeSelectedFeature()
    Dim feature As Object
    On Error GoTo Failed
    AttachActivePart
    If model.SelectionManager.GetSelectedObjectCount2(-1) <> 1 Then StopBuild "Select the Process-Bends feature in the tree first."
    Set feature = model.SelectionManager.GetSelectedObject6(1, -1)
    If Not fm.EditRollback(3, CStr(feature.Name)) Then StopBuild "Rollback failed. Select the Process-Bends tree feature."
    Exit Sub
Failed:
    MsgBox "Rollback helper: " & Err.Description, vbCritical
End Sub

Public Sub RollToEnd()
    On Error GoTo Failed
    AttachActivePart
    If Not fm.EditRollback(1, "") Then StopBuild "Roll To End failed."
    model.ForceRebuild3 False
    Exit Sub
Failed:
    MsgBox "Roll To End: " & Err.Description, vbCritical
End Sub

' Only run after physically completing and reviewing T6-T8 in SOLIDWORKS.
' Rename the three manual fillets F_T7_R15 / F_T7_R6 / F_T7_R2 and hole F_T8_HoleD76.
' Presence tests are guards, NOT mathematical proof of correct selections or dimensions.
Public Sub SaveReviewedFinal()
    Dim feature As Object, required, i As Long, path As String
    Dim errors As Long, warnings As Long, ok As Boolean, answer As VbMsgBoxResult
    On Error GoTo Failed
    AttachActivePart
    currentStage = "Explicit local final review and single native save"
    required = Array("F_T7_R15", "F_T7_R6", "F_T7_R2", "F_T8_HoleD76")
    For i = 0 To UBound(required)
        Set feature = model.FeatureByName(CStr(required(i)))
        If feature Is Nothing Then StopBuild "Completion gate missing: " & required(i) & ". Finish T6-T8 and rename these features first."
    Next
    If Not HasSheetMetalBody() Then StopBuild "No native sheet-metal solid body was found."
    If Not fm.EditRollback(1, "") Then StopBuild "Cannot roll all features to the end."
    ValidateStage "Local final review gate"
    answer = MsgBox("Confirm you have actually checked ALL items in SOLIDWORKS:" & vbCrLf & _
                   "1) ONE body; thickness3, native inner bends R3 (outer R6)." & vbCrLf & _
                   "2) FLAT-STATE fillets: three R15, four ear top R6, four root R2." & vbCrLf & _
                   "3) D76 hole: 50 from right straight edge, 110 from FLAT bottom edge." & vbCrLf & _
                   "4) Hole Link To Thickness; part rolls to end and flattens correctly." & vbCrLf & _
                   "5) No feature rebuild errors; K/allowance checked with instructor." & vbCrLf & _
                   "This helper does not independently certify those manual operations." & vbCrLf & _
                   "Save ONE final native part now?", vbYesNo + vbQuestion, "Required actual local review")
    If answer <> vbYes Then Exit Sub
    path = InputBox("Full NEW output path ending in .SLDPRT:", "Save reviewed final", _
                    CreateObject("WScript.Shell").SpecialFolders("MyDocuments") & "\Binding_Base_Plate_FINAL.SLDPRT")
    If Len(path) = 0 Then Exit Sub
    If LCase$(Right$(path, 7)) <> ".sldprt" Then StopBuild "Output extension must be .SLDPRT."
    Set fso = CreateObject("Scripting.FileSystemObject")
    If fso.FileExists(path) Then StopBuild "Output already exists; choose a new path to avoid overwriting it."
    SetTag "NativeHelperScope", "T1-T5 helper; T6-T8 completed and reviewed by local user"
    SetTag "FinalReviewDate", CStr(Now)
    errors = 0: warnings = 0
    ok = model.Extension.SaveAs(path, 0, 1, Nothing, errors, warnings)
    If Not ok Or errors <> 0 Then
        ' path was proved absent before SaveAs; only remove this new failed output.
        If fso.FileExists(path) Then fso.DeleteFile path, True
        StopBuild "SaveAs reported failure; any new failed output removed, error=" & CStr(errors)
    End If
    If Not fso.FileExists(path) Then StopBuild "SaveAs returned without an output file."
    MsgBox "ONE locally reviewed native part saved:" & vbCrLf & path & vbCrLf & _
           "Save warnings code: " & CStr(warnings), vbInformation
    Exit Sub
Failed:
    MsgBox "Final save gate stopped: " & Err.Description & vbCrLf & _
           "No substitute file or alternate-format rename was made.", vbCritical
End Sub

Private Sub AttachActivePart()
    Set swApp = GetObject(, "SldWorks.Application")
    Set model = swApp.ActiveDoc
    If model Is Nothing Then StopBuild "Open the relevant native part first."
    If model.GetType <> 1 Then StopBuild "The active document must be a part."
    Set sm = model.SketchManager
    Set fm = model.FeatureManager
    Set mu = swApp.GetMathUtility
End Sub

Private Function FindTopPlane() As Object
    Dim feature As Object, count As Long
    Set feature = model.FirstFeature
    Do While Not feature Is Nothing
        If feature.GetTypeName2 = "RefPlane" Then
            count = count + 1
            If count = 2 Then
                Set FindTopPlane = feature
                Exit Function
            End If
        End If
        Set feature = feature.GetNextFeature
    Loop
    StopBuild "Default second reference plane (Top) not found; use an ordinary Part template."
End Function

Private Sub BeginSketch(ByVal name As String)
    sm.InsertSketch True
    Set activeSketch = sm.ActiveSketch
    If activeSketch Is Nothing Then StopBuild "Cannot start sketch: " & name
    Set sketchFeature = activeSketch.GetFeature
    sketchFeature.Name = name
    model.ClearSelection2 True
End Sub

Private Sub BeginSketchAt(taskPoint, ByVal name As String)
    Dim face As Object
    Set face = FindPlanarFaceAt(taskPoint)
    model.ClearSelection2 True
    If Not face.Select4(False, Nothing) Then StopBuild "Cannot select sketch face for " & name
    BeginSketch name
End Sub

Private Sub CloseSketch()
    sm.AddToDB = False
    model.ClearSelection2 True
    sm.InsertSketch True
    model.ClearSelection2 True
    If Not sketchFeature.Select2(False, 0) Then StopBuild "Cannot select completed sketch."
End Sub

Private Function ModelPoint(taskPoint)
    Dim point As Object
    Set point = mu.CreatePoint(Array(CDbl(taskPoint(0)) / 1000#, CDbl(taskPoint(1)) / 1000#, topSign * CDbl(taskPoint(2)) / 1000#))
    Set point = point.MultiplyTransform(topToModel)
    ModelPoint = point.ArrayData
End Function

Private Function SketchPoint(taskPoint)
    Dim point As Object, v
    v = ModelPoint(taskPoint)
    Set point = mu.CreatePoint(v)
    Set point = point.MultiplyTransform(activeSketch.ModelToSketchTransform)
    v = point.ArrayData
    If Abs(v(2)) > 0.000001 Then StopBuild "Requested geometry is not in the selected sketch plane."
    SketchPoint = v
End Function

Private Function PointInSketchPoint(ByVal point As Object)
    PointInSketchPoint = Array(CDbl(point.X), CDbl(point.Y), CDbl(point.Z))
End Function

Private Function AddLine(p0, p1) As Object
    Dim a, b
    a = SketchPoint(p0): b = SketchPoint(p1)
    sm.AddToDB = True
    Set AddLine = sm.CreateLine(a(0), a(1), 0#, b(0), b(1), 0#)
    sm.AddToDB = False
    If AddLine Is Nothing Then StopBuild "Line creation failed."
End Function

Private Function AddArcThree(p0, p1, pm) As Object
    Dim a, b, mid
    a = SketchPoint(p0): b = SketchPoint(p1): mid = SketchPoint(pm)
    sm.AddToDB = True
    Set AddArcThree = sm.Create3PointArc(a(0), a(1), 0#, b(0), b(1), 0#, mid(0), mid(1), 0#)
    sm.AddToDB = False
    If AddArcThree Is Nothing Then StopBuild "Three-point arc creation failed."
End Function

Private Function AddArcAbout(center, p0, p1) As Object
    Dim i As Long, mid(2) As Double, norm As Double, radius As Double, v(2) As Double
    For i = 0 To 2
        v(i) = CDbl(p0(i)) + CDbl(p1(i)) - 2# * CDbl(center(i))
        norm = norm + v(i) ^ 2
        radius = radius + (CDbl(p0(i)) - CDbl(center(i))) ^ 2
    Next
    If norm < 0.0000001 Then StopBuild "Use AddArcThree with an explicit midpoint for a semicircle."
    For i = 0 To 2
        mid(i) = CDbl(center(i)) + v(i) * Sqr(radius / norm)
    Next
    Set AddArcAbout = AddArcThree(p0, p1, mid)
End Function

Private Function RadialOffsetPoint(center, point, ByVal newRadius As Double)
    Dim i As Long, length As Double, result(2) As Double
    For i = 0 To 2
        length = length + (CDbl(point(i)) - CDbl(center(i))) ^ 2
    Next
    length = Sqr(length)
    If length = 0# Or newRadius <= 0# Then StopBuild "Invalid radial-offset geometry."
    For i = 0 To 2
        result(i) = CDbl(center(i)) + (CDbl(point(i)) - CDbl(center(i))) * newRadius / length
    Next
    RadialOffsetPoint = result
End Function

Private Function EarPoint(ByVal ox As Double, ByVal oy As Double, ByVal ux As Double, ByVal uy As Double, _
                          ByVal nx As Double, ByVal ny As Double, ByVal s As Double, ByVal h As Double, ByVal offset As Double)
    EarPoint = Array(ox + ux * s + nx * offset, oy + uy * s + ny * offset, h)
End Function

Private Sub JoinLoop(segments)
    Dim i As Long, nextIndex As Long, a As Object, b As Object
    For i = 0 To UBound(segments)
        nextIndex = (i + 1) Mod (UBound(segments) + 1)
        Set a = segments(i).GetEndPoint2
        Set b = segments(nextIndex).GetStartPoint2
        RelateTwo a, b, "sgCOINCIDENT"
    Next
End Sub

Private Sub RelateOne(ByVal entity As Object, ByVal relation As String)
    model.ClearSelection2 True
    If Not entity.Select4(False, Nothing) Then StopBuild "Cannot select relation entity."
    model.SketchAddConstraints relation
End Sub

Private Sub RelateTwo(ByVal a As Object, ByVal b As Object, ByVal relation As String)
    model.ClearSelection2 True
    If Not a.Select4(False, Nothing) Then StopBuild "Cannot select first relation entity."
    If Not b.Select4(True, Nothing) Then StopBuild "Cannot select second relation entity."
    model.SketchAddConstraints relation
End Sub

Private Function DatumPoint() As Object
    Dim point As Object
    sm.AddToDB = True
    Set point = sm.CreatePoint(0#, 0#, 0#)
    sm.AddToDB = False
    If point Is Nothing Then StopBuild "Cannot create sketch construction datum."
    ' This is a single reference datum, NOT a fixed production contour.
    RelateOne point, "sgFIXED"
    Set DatumPoint = point
End Function

Private Sub FullyDimensionSketch(ByVal datum As Object)
    Dim result As Long
    If Not activeSketch.IsFullyDefined Then
        model.ClearSelection2 True
        ' Official API: dimensions enabled; no automatic relation guesses.
        ' Baseline scheme=1, both datum arguments use this reference point.
        result = sm.FullyDefineSketch(True, False, 0, True, 1, datum, 1, datum, 0, 0)
    End If
    If Not activeSketch.IsFullyDefined Then StopBuild "Sketch remains underdefined: " & sketchFeature.Name
    WriteLog "Fully dimensioned: " & sketchFeature.Name & "; production geometry is not Fixed."
End Sub

Private Sub AddLengthDimension(ByVal entity As Object, ByVal millimeters As Double, ByVal name As String)
    Dim a As Object, b As Object, pos, display As Object
    Set a = entity.GetStartPoint2: Set b = entity.GetEndPoint2
    pos = AnnotationAt((a.X + b.X) / 2# + 0.012, (a.Y + b.Y) / 2# + 0.012)
    model.ClearSelection2 True
    entity.Select4 False, Nothing
    Set display = model.AddDimension2(pos(0), pos(1), pos(2))
    SetDrivingDimension display, millimeters, name
End Sub

Private Sub AddRadiusDimension(ByVal entity As Object, ByVal millimeters As Double, ByVal name As String)
    Dim p As Object, pos, display As Object
    Set p = entity.GetCenterPoint2
    pos = AnnotationAt(p.X + millimeters / 1300#, p.Y + millimeters / 1300#)
    model.ClearSelection2 True
    entity.Select4 False, Nothing
    Set display = model.AddRadialDimension2(pos(0), pos(1), pos(2))
    SetDrivingDimension display, millimeters, name
End Sub

Private Function AnnotationAt(ByVal x As Double, ByVal y As Double)
    Dim transform As Object, point As Object
    Set transform = activeSketch.ModelToSketchTransform.Inverse
    Set point = mu.CreatePoint(Array(x, y, 0#))
    Set point = point.MultiplyTransform(transform)
    AnnotationAt = point.ArrayData
End Function

Private Sub SetDrivingDimension(ByVal display As Object, ByVal millimeters As Double, ByVal name As String)
    Dim dimension As Object
    If display Is Nothing Then StopBuild "Driving dimension failed: " & name
    Set dimension = display.GetDimension2(0)
    dimension.Name = name
    dimension.SystemValue = millimeters / 1000#
    model.ClearSelection2 True
End Sub

Private Function ReverseForDirection(taskDirection, ByVal cut As Boolean) As Boolean
    Dim localNormal As Object, wanted As Object, transform As Object
    Dim a, b, dot As Double, sign As Double
    Set transform = activeSketch.ModelToSketchTransform.Inverse
    Set localNormal = mu.CreateVector(Array(0#, 0#, 1#))
    Set localNormal = localNormal.MultiplyTransform(transform)
    Set wanted = mu.CreateVector(Array(CDbl(taskDirection(0)), CDbl(taskDirection(1)), topSign * CDbl(taskDirection(2))))
    Set wanted = wanted.MultiplyTransform(topToModel)
    a = localNormal.ArrayData: b = wanted.ArrayData
    dot = a(0) * b(0) + a(1) * b(1) + a(2) * b(2)
    If Abs(dot) < 0.99 Then StopBuild "Extrusion direction is not normal to the sketch."
    If cut Then dot = -dot
    ReverseForDirection = (dot < 0#)
End Function

Private Function MakeBoss(ByVal depthMM As Double, ByVal name As String, ByVal reverse As Boolean) As Object
    Dim feature As Object
    Set feature = fm.FeatureExtrusion2(True, False, reverse, 0, 0, depthMM / 1000#, 0#, False, False, False, False, 0#, 0#, False, False, False, False, True, True, True, 0, 0#, False)
    If feature Is Nothing Then StopBuild "Boss creation failed: " & name
    feature.Name = name
    Set MakeBoss = feature
End Function

Private Function MakeCut(ByVal endCondition As Long, ByVal depthMM As Double, ByVal flipOutside As Boolean, _
                         ByVal name As String, ByVal reverse As Boolean) As Object
    Dim feature As Object
    ' FeatureCut3: Sd,Flip,Dir,T1,T2,D1,D2,Dchk1,Dchk2,Ddir1,Ddir2,
    ' Dang1,Dang2,OffsetReverse1,OffsetReverse2,TranslateSurface1,
    ' TranslateSurface2,NormalCut,UseFeatScope,UseAutoSelect,
    ' AssemblyFeatureScope,AutoSelectComponents,PropagateFeatureToParts,
    ' T0,StartOffset,FlipStartOffset. 26 arguments, per official API.
    Set feature = fm.FeatureCut3(True, flipOutside, reverse, endCondition, 0, depthMM / 1000#, 0#, False, False, False, False, 0#, 0#, False, False, False, False, False, True, True, False, False, False, 0, 0#, False)
    If feature Is Nothing Then StopBuild "Cut creation failed: " & name
    feature.Name = name
    Set MakeCut = feature
End Function

Private Function FirstBody() As Object
    Dim bodies
    bodies = model.GetBodies2(0, False)
    If IsEmpty(bodies) Then StopBuild "No solid body exists."
    If UBound(bodies) <> 0 Then StopBuild "Expected exactly ONE solid body."
    Set FirstBody = bodies(0)
End Function

Private Function FindPlanarFaceAt(taskPoint) As Object
    Dim body As Object, faces, i As Long, face As Object, p, q
    p = ModelPoint(taskPoint)
    Set body = FirstBody()
    faces = body.GetFaces
    For i = 0 To UBound(faces)
        Set face = faces(i)
        If face.GetSurface.IsPlane Then
            q = face.GetClosestPointOn(p(0), p(1), p(2))
            If Not IsEmpty(q) Then
                If (q(0) - p(0)) ^ 2 + (q(1) - p(1)) ^ 2 + (q(2) - p(2)) ^ 2 < 0.0000000000001 Then
                    Set FindPlanarFaceAt = face
                    Exit Function
                End If
            End If
        End If
    Next
    StopBuild "Required planar support face not found at specified geometry point."
End Function

Private Sub DetermineThicknessSign()
    Dim mp As Object, v, point As Object
    Set mp = model.Extension.CreateMassProperty
    mp.UseSystemUnits = True
    v = mp.CenterOfMass
    Set point = mu.CreatePoint(v)
    Set point = point.MultiplyTransform(modelToTop)
    v = point.ArrayData
    If Abs(v(2)) < 0.001 Then StopBuild "Cannot identify initial extrusion side."
    If v(2) < 0# Then topSign = -1# Else topSign = 1#
End Sub

Private Function VolumeMM3() As Double
    Dim mp As Object
    model.ClearSelection2 True
    Set mp = model.Extension.CreateMassProperty
    mp.UseSystemUnits = True
    VolumeMM3 = mp.Volume * 1000000000#
    If VolumeMM3 <= 0# Then StopBuild "Nonpositive body volume."
End Function

Private Sub CheckDelta(ByVal beforeVolume As Double, ByVal targetDelta As Double, ByVal description As String)
    Dim actual As Double
    actual = VolumeMM3() - beforeVolume
    If Abs(actual - targetDelta) > 0.5 Then StopBuild description & " volume delta mismatch: " & CStr(actual) & " vs " & CStr(targetDelta) & " mm^3."
End Sub

Private Sub ValidateStage(ByVal name As String)
    Dim body As Object, volume As Double
    model.ForceRebuild3 False
    Set body = FirstBody()
    volume = VolumeMM3()
    WriteLog name & ": one solid, volume mm^3=" & CStr(volume)
End Sub

Private Function HasSheetMetalBody() As Boolean
    Dim body As Object
    Set body = FirstBody()
    HasSheetMetalBody = body.IsSheetMetal
End Function

Private Sub SetTag(ByVal name As String, ByVal value As String)
    Dim manager As Object, result As Long
    Set manager = model.Extension.CustomPropertyManager("")
    result = manager.Add3(name, 30, value, 2)
End Sub

Private Function NewLogFolder() As String
    Dim parent As String, folder As String, suffix As Long
    parent = CreateObject("WScript.Shell").SpecialFolders("MyDocuments")
    folder = parent & "\Binding_Base_Plate_Helper_" & Format$(Now, "yyyymmdd_hhnnss")
    Do While fso.FolderExists(folder)
        suffix = suffix + 1
        folder = parent & "\Binding_Base_Plate_Helper_" & Format$(Now, "yyyymmdd_hhnnss") & "_" & CStr(suffix)
    Loop
    fso.CreateFolder folder
    NewLogFolder = folder
End Function

Private Sub WriteLog(ByVal message As String)
    Debug.Print message
    If Not logFile Is Nothing Then logFile.WriteLine message
End Sub

Private Sub CloseLog()
    On Error Resume Next
    If Not logFile Is Nothing Then logFile.Close
    Set logFile = Nothing
    On Error GoTo 0
End Sub

Private Sub RestorePreferences()
    On Error Resume Next
    If Not sm Is Nothing Then sm.AddToDB = False
    If preferenceSaved Then swApp.SetUserPreferenceToggle 10, oldDimPrompt
    preferenceSaved = False
    On Error GoTo 0
End Sub

Private Sub StopBuild(ByVal message As String)
    Err.Raise vbObjectError + 4301, "Binding Base Plate helper", message
End Sub
