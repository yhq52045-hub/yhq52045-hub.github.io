Option Explicit
' T4 Binding Anchor -- native SOLIDWORKS construction, SI API units.
' Workbook pages 24-54. This source has NOT been run in SOLIDWORKS here.
' Only construction reference geometry is fixed; production contours use driving dimensions.
' Save ONE final native part only; stage geometry is validated in memory.
' No intermediate part files and no per-feature modal pauses.
Dim app, model, sm, fm, fs, outDir, currentStage
Dim sketchFeat, activeSketch, upSign, logFile, oldDimPrompt, prefSaved, materialOK

Sub BuildAnchor()
    Dim tpl, topPlane, baseFeat, bottomFeat, recessFeat, slotFeat
    Dim outerFeat, innerFeat, e1, e2, data, edges, b, box, mp, vol
    Set fs = CreateObject("Scripting.FileSystemObject")
    Set app = ConnectSW()
    If app Is Nothing Then Err.Raise 1001, "T4", "Open licensed SOLIDWORKS 2026 first."
    app.Visible = True
    tpl = app.GetUserPreferenceStringValue(8) ' swDefaultTemplatePart
    If Len(tpl) = 0 Then tpl = InputBox("Enter the full path to your MM part template (.prtdot).", "T4 part template")
    If Len(tpl) = 0 Then Err.Raise 1002, "T4", "No part template was selected."
    Set model = app.NewDocument(tpl, 0, 0, 0)
    If model Is Nothing Then Err.Raise 1003, "T4", "Cannot create a part from: " & tpl
    Set sm = model.SketchManager
    Set fm = model.FeatureManager
    model.SetUnits 0, 1, 0, 3, False ' swMM, swDECIMAL
    oldDimPrompt = app.GetUserPreferenceToggle(10) ' swInputDimValOnCreate
    prefSaved = True
    app.SetUserPreferenceToggle 10, False
    Set logFile = fs.CreateTextFile(outDir & "\build_log.txt", True, True)
    LogLine "Native build started: " & Now
    LogLine "API lengths are meters; document dimensions are millimeters."

    currentStage = "01 Base boss: diameter 82, depth 3.5"
    Set topPlane = FindTopPlane()
    If topPlane Is Nothing Then Err.Raise 1010, "T4", "The default Top reference plane was not found."
    model.ClearSelection2 True
    topPlane.Select2 False, 0
    StartSketch "S01_Base_D82"
    MakeCircle 0.082, "BaseDiameter"
    EndSketch
    Set baseFeat = Boss(0.0035, "F01_Base_D82_T3p5")
    Set b = FirstBody()
    box = b.GetBodyBox
    upSign = 1
    If (box(1) + box(4)) < 0 Then upSign = -1
    ValidateStage "01_Base"

    currentStage = "02 Bottom boss: diameter 75, depth 3"
    StartFaceSketch 0, "S02_Bottom_D75"
    MakeCircle 0.075, "BottomDiameter"
    EndSketch
    Set bottomFeat = Boss(0.003, "F02_Bottom_D75_T3")
    EnsureBottomDirection bottomFeat
    ValidateStage "02_Bottom_Boss"

    currentStage = "03 Top recess: diameter 63, depth 3"
    StartFaceSketch 0.0035, "S03_Recess_D63"
    MakeCircle 0.063, "RecessDiameter"
    EndSketch
    Set recessFeat = Cut(0, 0.003, "F03_Recess_D63_Depth3")
    ValidateStage "03_Recess"

    currentStage = "04 Four symmetric through slots"
    StartFaceSketch 0.0005, "S04_Symmetric_Slots"
    MakeMirroredSlots
    EndSketch
    Set slotFeat = Cut(1, 0.01, "F04_Rounded_Slots_ThroughAll")
    ValidateStage "04_Through_Slots"

    currentStage = "05 Outer top round R1.5"
    Set e1 = CircularEdge(0.041, 0.0035)
    Set outerFeat = NewFillet(e1, 0.0015, "F05_Outer_R1p5")
    ValidateStage "05_Outer_Round"

    currentStage = "06 Recess bottom fillet R1"
    Set e1 = CircularEdge(0.0315, 0.0005)
    Set innerFeat = NewFillet(e1, 0.001, "F06_Inner_Edges_R1")
    ValidateStage "06_Inner_Lower_Fillet"

    currentStage = "07 Edit F06: add recess top edge R1"
    Set data = innerFeat.GetDefinition
    If Not data.AccessSelections(model, Nothing) Then Err.Raise 1020, "T4", "Cannot edit inner fillet selections."
    ' AccessSelections temporarily rolls back before this fillet: both original edges exist.
    Set e1 = CircularEdge(0.0315, 0.0005)
    Set e2 = CircularEdge(0.0315, 0.0035)
    edges = Array(e1, e2)
    data.Edges = edges
    If Not innerFeat.ModifyDefinition(data, model, Nothing) Then
        data.ReleaseSelectionAccess
        Err.Raise 1021, "T4", "Failed to add the second inner edge to F06."
    End If
    ValidateStage "07_Final_Geometry"

    currentStage = "08 Verify volume and material density"
    model.ClearSelection2 True
    Set mp = model.Extension.CreateMassProperty
    mp.UseSystemUnits = True
    vol = mp.Volume * 1000000000
    LogLine "Final volume mm^3: " & CStr(vol)
    LogLine "Expected workbook volume mm^3: 19765.727"
    LogLine "Calculated mass at 2800 kg/m^3, grams: " & CStr(vol * 0.0028)
    If Abs(vol - 19765.727) > 0.1 Then
        Err.Raise 1022, "T4", "Geometry volume does not match workbook. See build_log.txt; inspect sketches/fillets. Volume=" & CStr(vol)
    End If
    materialOK = AssignWorkbookDensity()
    SaveNative "Binding_Anchor_FINAL.SLDPRT", 1
    LogLine "SUCCESS. One final editable native part saved: Binding_Anchor_FINAL.SLDPRT. No intermediate part files were saved."
    LogLine "Required density: 2800 kg/m^3; verify Mass Properties approx 55.344 g."
    logFile.Close
    Set logFile = Nothing
    RestorePreferences
    If materialOK Then
        MsgBox "Native editable part saved:" & vbCrLf & outDir & vbCrLf & "Density-only workbook material applied: 2800 kg/m^3. Verify Mass Properties: about 55.344 g." & vbCrLf & "Use Edit Sketch / Edit Feature or the rollback bar to inspect changes.", 64, "T4 native build complete"
    Else
        MsgBox "Native editable geometry saved:" & vbCrLf & outDir & vbCrLf & vbCrLf & "MATERIAL NEEDS MANUAL SELECTION: Right-click Material > Edit Material. Select the supplied T4 workbook material or built-in 2015 Alloy; verify density 2800 kg/m^3, mass about 55.344 g, then save.", 48, "T4 material selection required"
    End If
End Sub

Function AssignWorkbookDensity()
    Dim database, file, xml, massProps, ok
    On Error Resume Next
    ok = False
    database = outDir & "\T4_Aluminum_2800.sldmat"
    xml = "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbCrLf
    xml = xml & "<materials version=""2008.03"" xmlns:sldmaterials=""http://www.solidworks.com/sldmaterials"" xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance"">" & vbCrLf
    xml = xml & "<curves id=""curve0""/><classification name=""T4 Workbook"">" & vbCrLf
    xml = xml & "<material name=""T4 Aluminum 2800 (density only)"" matid=""T4-Al-2800""><description>Workbook density only; not a verified strength or FEA material.</description><source>User-supplied workbook pages 38, 51-53</source>" & vbCrLf
    xml = xml & "<physicalproperties><DENS displayname=""Mass Density"" value=""2800""/></physicalproperties></material></classification></materials>"
    Set file = fs.CreateTextFile(database, True, False)
    file.Write xml
    file.Close
    model.SetMaterialPropertyName2 "", database, "T4 Aluminum 2800 (density only)"
    model.ForceRebuild3 False
    Set massProps = model.Extension.CreateMassProperty
    massProps.UseSystemUnits = True
    If Abs(massProps.Density - 2800) < 0.01 Then ok = True
    If Err.Number <> 0 Then
        Err.Clear
        ok = False
    End If
    If ok Then
        LogLine "Applied density-only custom material; verified density 2800 kg/m^3."
    Else
        LogLine "WARNING: Custom material not verified. Manually assign workbook material or 2015 Alloy and verify density 2800 kg/m^3."
    End If
    On Error GoTo 0
    AssignWorkbookDensity = ok
End Function

Function ConnectSW()
    Dim instance
    On Error Resume Next
    Set instance = Nothing
    Set instance = GetObject(, "SldWorks.Application")
    If instance Is Nothing Then
        Err.Clear
        Set instance = CreateObject("SldWorks.Application")
    End If
    On Error GoTo 0
    Set ConnectSW = instance
End Function

Function FindTopPlane()
    Dim f, n
    n = 0
    Set FindTopPlane = Nothing
    Set f = model.FirstFeature
    Do While Not f Is Nothing
        If f.GetTypeName2 = "RefPlane" Then
            n = n + 1
            If n = 2 Then
                Set FindTopPlane = f
                Exit Function
            End If
        End If
        Set f = f.GetNextFeature
    Loop
End Function

Function FirstBody()
    Dim bodies
    bodies = model.GetBodies2(0, False) ' swSolidBody
    If IsEmpty(bodies) Then Err.Raise 1030, "T4", "No solid body exists at " & currentStage
    If UBound(bodies) <> 0 Then Err.Raise 1031, "T4", "Expected exactly one solid body."
    Set FirstBody = bodies(0)
End Function

Sub StartSketch(nm)
    sm.InsertSketch True
    Set activeSketch = sm.ActiveSketch
    If activeSketch Is Nothing Then Err.Raise 1040, "T4", "Cannot start sketch: " & nm
    Set sketchFeat = activeSketch.GetFeature
    sketchFeat.Name = nm
    model.ClearSelection2 True
End Sub

Sub StartFaceSketch(h, nm)
    Dim face
    Set face = PlanarFaceAt(h)
    model.ClearSelection2 True
    If Not face.Select4(False, Nothing) Then Err.Raise 1041, "T4", "Cannot select sketch support face."
    StartSketch nm
End Sub

Function PlanarFaceAt(h)
    Dim b, faces, f, surf, box, i
    Set PlanarFaceAt = Nothing
    Set b = FirstBody()
    faces = b.GetFaces
    For i = 0 To UBound(faces)
        Set f = faces(i)
        Set surf = f.GetSurface
        If surf.IsPlane Then
            box = f.GetBox
            If Abs(box(1) - upSign * h) < 0.0000001 And Abs(box(4) - upSign * h) < 0.0000001 Then
                Set PlanarFaceAt = f
                Exit Function
            End If
        End If
    Next
    Err.Raise 1042, "T4", "Planar face not found at thickness coordinate " & CStr(h)
End Function

Sub EndSketch()
    sm.AddToDB = False
    model.ClearSelection2 True
    sm.InsertSketch True
    model.ClearSelection2 True
    sketchFeat.Select2 False, 0
End Sub

Function PinnedOrigin()
    Dim p
    sm.AddToDB = True
    Set p = sm.CreatePoint(0, 0, 0)
    sm.AddToDB = False
    RelateOne p, "sgFIXED"
    Set PinnedOrigin = p
End Function

Sub MakeCircle(diameter, dimName)
    Dim c, p, origin, dd, loc
    sm.AddToDB = True
    Set c = sm.CreateCircleByRadius(0, 0, 0, diameter / 2)
    sm.AddToDB = False
    Set p = c.GetCenterPoint2
    Set origin = PinnedOrigin()
    RelateTwo p, origin, "sgCOINCIDENT"
    model.ClearSelection2 True
    c.Select4 False, Nothing
    loc = DimensionLocation(diameter * 0.7, diameter * 0.4)
    Set dd = model.AddDiameterDimension2(loc(0), loc(1), loc(2))
    SetDimension dd, diameter, dimName
    If Not activeSketch.IsFullyDefined Then Err.Raise 1061, "T4", "Circle sketch is not fully defined: " & sketchFeat.Name
    LogLine "Sketch " & sketchFeat.Name & ": diameter=" & CStr(diameter * 1000) & " mm; fully defined=" & CStr(activeSketch.IsFullyDefined)
End Sub

Sub MakeMirroredSlots()
    Dim origin, axV, axH, leftLine, rightLine, upperArc, lowerArc
    Dim p1, p2, topCenter, bottomCenter, dd, loc, allSeg, seg
    Dim count, i, sel
    Set origin = PinnedOrigin()
    sm.AddToDB = True
    Set axV = sm.CreateCenterLine(0, -0.035, 0, 0, 0.035, 0)
    Set axH = sm.CreateCenterLine(-0.035, 0, 0, 0.035, 0, 0)
    Set leftLine = sm.CreateLine(0.008, 0.006, 0, 0.008, 0.022, 0)
    Set upperArc = sm.CreateArc(0.012, 0.022, 0, 0.008, 0.022, 0, 0.016, 0.022, 0, -1)
    Set rightLine = sm.CreateLine(0.016, 0.022, 0, 0.016, 0.006, 0)
    Set lowerArc = sm.CreateArc(0.012, 0.006, 0, 0.016, 0.006, 0, 0.008, 0.006, 0, -1)
    sm.AddToDB = False
    RelateOne axV, "sgFIXED"
    RelateOne axH, "sgFIXED"
    RelateOne leftLine, "sgVERTICAL2D"
    RelateOne rightLine, "sgVERTICAL2D"
    Set p1 = leftLine.GetEndPoint2
    Set p2 = upperArc.GetStartPoint2
    RelateTwo p1, p2, "sgCOINCIDENT"
    Set p1 = upperArc.GetEndPoint2
    Set p2 = rightLine.GetStartPoint2
    RelateTwo p1, p2, "sgCOINCIDENT"
    Set p1 = rightLine.GetEndPoint2
    Set p2 = lowerArc.GetStartPoint2
    RelateTwo p1, p2, "sgCOINCIDENT"
    Set p1 = lowerArc.GetEndPoint2
    Set p2 = leftLine.GetStartPoint2
    RelateTwo p1, p2, "sgCOINCIDENT"
    RelateTwo leftLine, upperArc, "sgTANGENT"
    RelateTwo upperArc, rightLine, "sgTANGENT"
    RelateTwo rightLine, lowerArc, "sgTANGENT"
    RelateTwo lowerArc, leftLine, "sgTANGENT"
    Set topCenter = upperArc.GetCenterPoint2
    Set bottomCenter = lowerArc.GetCenterPoint2

    model.ClearSelection2 True
    upperArc.Select4 False, Nothing
    loc = DimensionLocation(0.025, 0.03)
    Set dd = model.AddRadialDimension2(loc(0), loc(1), loc(2))
    SetDimension dd, 0.004, "SlotRadius"
    SelectPair topCenter, bottomCenter
    loc = DimensionLocation(0.024, 0.014)
    Set dd = model.AddVerticalDimension2(loc(0), loc(1), loc(2))
    SetDimension dd, 0.016, "SlotCenterSpacing"
    SelectPair origin, bottomCenter
    loc = DimensionLocation(0.006, -0.006)
    Set dd = model.AddHorizontalDimension2(loc(0), loc(1), loc(2))
    SetDimension dd, 0.012, "SlotOffsetX"
    SelectPair origin, bottomCenter
    loc = DimensionLocation(0.027, 0.003)
    Set dd = model.AddVerticalDimension2(loc(0), loc(1), loc(2))
    SetDimension dd, 0.006, "SlotOffsetY"

    ' Mirror the seed slot about the vertical centerline, then mirror the pair horizontally.
    Set sel = model.SelectionManager.CreateSelectData
    model.ClearSelection2 True
    sel.Mark = 1
    leftLine.Select4 True, sel
    upperArc.Select4 True, sel
    rightLine.Select4 True, sel
    lowerArc.Select4 True, sel
    sel.Mark = 2
    axV.Select4 True, sel
    model.SketchMirror
    allSeg = activeSketch.GetSketchSegments
    model.ClearSelection2 True
    sel.Mark = 1
    For i = 0 To UBound(allSeg)
        Set seg = allSeg(i)
        If Not seg.ConstructionGeometry Then seg.Select4 True, sel
    Next
    sel.Mark = 2
    axH.Select4 True, sel
    model.SketchMirror
    allSeg = activeSketch.GetSketchSegments
    count = 0
    For i = 0 To UBound(allSeg)
        Set seg = allSeg(i)
        If Not seg.ConstructionGeometry Then count = count + 1
    Next
    If count <> 16 Then Err.Raise 1050, "T4", "Sketch mirror failed: expected 16 slot boundary segments, got " & CStr(count)
    LogLine "Slots: 16 production segments; mirrored with native symmetric relations."
    LogLine "Slots fully defined: " & CStr(activeSketch.IsFullyDefined)
    If Not activeSketch.IsFullyDefined Then Err.Raise 1062, "T4", "Mirrored slot sketch is not fully defined; inspect constraints."
End Sub

Sub RelateOne(a, relation)
    model.ClearSelection2 True
    a.Select4 False, Nothing
    model.SketchAddConstraints relation
End Sub

Sub SelectPair(a, b)
    model.ClearSelection2 True
    a.Select4 False, Nothing
    b.Select4 True, Nothing
End Sub

Sub RelateTwo(a, b, relation)
    SelectPair a, b
    model.SketchAddConstraints relation
End Sub

Function DimensionLocation(x, y)
    Dim mu, p, transform
    Set mu = app.GetMathUtility
    Set p = mu.CreatePoint(Array(x, y, 0.0))
    Set transform = activeSketch.ModelToSketchTransform
    Set transform = transform.Inverse
    Set p = p.MultiplyTransform(transform)
    DimensionLocation = p.ArrayData
End Function

Sub SetDimension(displayDim, meters, nm)
    Dim d
    If displayDim Is Nothing Then Err.Raise 1060, "T4", "Cannot create driving dimension: " & nm
    Set d = displayDim.GetDimension2(0)
    d.Name = nm
    d.SystemValue = meters
    model.ClearSelection2 True
End Sub

Function Boss(depth, nm)
    Dim f
    Set f = fm.FeatureExtrusion2(True, False, False, 0, 0, depth, 0, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)
    If f Is Nothing Then
        If nm = "F02_Bottom_D75_T3" Then
            ' Some face-sketch orientations require the opposite extrusion direction.
            model.ClearSelection2 True
            sketchFeat.Select2 False, 0
            Set f = fm.FeatureExtrusion2(True, False, True, 0, 0, depth, 0, False, False, False, False, 0, 0, False, False, False, False, True, True, True, 0, 0, False)
        End If
    End If
    If f Is Nothing Then Err.Raise 1070, "T4", "Boss creation failed: " & nm
    f.Name = nm
    Set Boss = f
End Function

Sub EnsureBottomDirection(feature)
    Dim b, box, data
    Set b = FirstBody()
    box = b.GetBodyBox
    If Abs((box(4) - box(1)) - 0.0065) > 0.000005 Then
        Set data = feature.GetDefinition
        If Not data.AccessSelections(model, Nothing) Then Err.Raise 1072, "T4", "Cannot access bottom boss direction."
        data.ReverseDirection = Not data.ReverseDirection
        If Not feature.ModifyDefinition(data, model, Nothing) Then
            data.ReleaseSelectionAccess
            Err.Raise 1073, "T4", "Cannot reverse bottom boss direction."
        End If
        model.ForceRebuild3 False
        Set b = FirstBody()
        box = b.GetBodyBox
        LogLine "Adjusted bottom boss extrusion to the outward direction."
    End If
    If Abs((box(4) - box(1)) - 0.0065) > 0.000005 Then Err.Raise 1074, "T4", "Bottom boss must produce total thickness 6.5 mm."
End Sub

Function Cut(endCondition, depth, nm)
    Dim f
    Set f = fm.FeatureCut4(True, False, False, endCondition, 0, depth, 0, False, False, False, False, 0, 0, False, False, False, False, False, True, True, True, True, False, 0, 0, False, False)
    If f Is Nothing Then Err.Raise 1071, "T4", "Cut creation failed: " & nm
    f.Name = nm
    Set Cut = f
End Function

Function CircularEdge(radius, h)
    Dim b, allEdges, edge, c, p, i
    Set CircularEdge = Nothing
    Set b = FirstBody()
    allEdges = b.GetEdges
    For i = 0 To UBound(allEdges)
        Set edge = allEdges(i)
        Set c = edge.GetCurve
        If c.IsCircle Then
            p = c.CircleParams
            If Abs(p(6) - radius) < 0.0000001 And Abs(p(1) - upSign * h) < 0.0000001 Then
                If Abs(p(0)) < 0.0000001 And Abs(p(2)) < 0.0000001 Then
                    Set CircularEdge = edge
                    Exit Function
                End If
            End If
        End If
    Next
    Err.Raise 1080, "T4", "Circular edge not found: radius=" & CStr(radius * 1000) & ", h=" & CStr(h * 1000)
End Function

Function NewFillet(edge, radius, nm)
    Dim f, sel
    model.ClearSelection2 True
    Set sel = model.SelectionManager.CreateSelectData
    sel.Mark = 1
    edge.Select4 False, sel
    ' Options=UniformRadius(2)+TangentPropagation(1); Simple=0; circular profile=0.
    Set f = fm.FeatureFillet3(3, radius, 0, 0, 0, 0, 0, Empty, Empty, Empty, Empty, Empty, Empty, Empty)
    If f Is Nothing Then Err.Raise 1081, "T4", "Fillet creation failed: " & nm
    f.Name = nm
    Set NewFillet = f
End Function

Sub ValidateStage(nm)
    Dim b, mp, volume, target
    model.ClearSelection2 True
    model.ForceRebuild3 False
    Set b = FirstBody()
    Set mp = model.Extension.CreateMassProperty
    mp.UseSystemUnits = True
    volume = mp.Volume * 1000000000
    target = 0
    Select Case nm
        Case "01_Base": target = 18483.560377
        Case "02_Bottom_Boss": target = 31737.154385
        Case "03_Recess": target = 22385.418453
        Case "04_Through_Slots": target = 19889.701699
        Case "05_Outer_Round": target = 19766.329858
        Case "06_Inner_Lower_Fillet": target = 19808.502741
        Case "07_Final_Geometry": target = 19765.727487
    End Select
    If target > 0 Then
        If Abs(volume - target) > 0.1 Then Err.Raise 1091, "T4", "Stage volume mismatch at " & nm & "; actual=" & CStr(volume) & " mm^3. Check sketch plane/extrusion direction."
    End If
    model.ShowNamedView2 "", 7 ' swIsometricView
    model.ViewZoomtofit2
    model.GraphicsRedraw2
    LogLine "Validated " & nm & " | volume=" & CStr(volume) & " mm^3 | " & currentStage
End Sub

Sub SaveNative(filename, options)
    Dim errors, warnings, success
    errors = 0
    warnings = 0
    success = model.Extension.SaveAs(outDir & "\" & filename, 0, options, Nothing, errors, warnings)
    If Not success Or errors <> 0 Then Err.Raise 1090, "T4", "Save failed: " & filename & "; code=" & CStr(errors)
    If warnings <> 0 Then LogLine "Save warning " & CStr(warnings) & " for " & filename
End Sub

Sub LogLine(s)
    If IsObject(logFile) Then
        If Not logFile Is Nothing Then logFile.WriteLine s
    End If
End Sub

Sub RestorePreferences()
    On Error Resume Next
    If IsObject(sm) Then sm.AddToDB = False
    If prefSaved Then app.SetUserPreferenceToggle 10, oldDimPrompt
    On Error GoTo 0
End Sub

Function NewOutputFolder(parentFolder)
    Dim stamp, name, fso, counter
    Set fso = CreateObject("Scripting.FileSystemObject")
    stamp = Year(Now) & Right("0" & Month(Now), 2) & Right("0" & Day(Now), 2) & "_" & Right("0" & Hour(Now), 2) & Right("0" & Minute(Now), 2) & Right("0" & Second(Now), 2)
    name = parentFolder & "\T4_Binding_Anchor_" & stamp
    counter = 0
    Do While fso.FolderExists(name)
        counter = counter + 1
        name = parentFolder & "\T4_Binding_Anchor_" & stamp & "_" & counter
    Loop
    fso.CreateFolder name
    NewOutputFolder = name
End Function


Sub RunNative()
    Dim shell
    Set shell = CreateObject("WScript.Shell")
    outDir = NewOutputFolder(shell.SpecialFolders("MyDocuments"))
    BuildAnchor
End Sub

Dim errorNumber, errorMessage
On Error Resume Next
RunNative
errorNumber = Err.Number
errorMessage = Err.Description
On Error GoTo 0
If errorNumber <> 0 Then
    RestorePreferences
    On Error Resume Next
    LogLine "FAILED " & CStr(errorNumber) & ": " & errorMessage
    If IsObject(logFile) Then logFile.Close
    On Error GoTo 0
    MsgBox "Build stopped at: " & currentStage & vbCrLf & "Error " & CStr(errorNumber) & ": " & errorMessage & vbCrLf & "Build log is in: " & outDir, 16, "T4 - inspect the current step"
    WScript.Quit 1
End If
