Option Explicit

'--------------------------------------------------
'■Include Standard Software Library
'--------------------------------------------------
'FileNameには相対アドレスも指定可能
'--------------------------------------------------
'Include ".\Test\..\..\StandardSoftwareLibrary_vbs\StandardSoftwareLibrary.vbs"  
Call Include(".\Lib\StandardSoftwareLibrary.vbs")

Sub Include(ByVal FileName)
    Dim fso: Set fso = WScript.CreateObject("Scripting.FileSystemObject") 
    Dim Stream: Set Stream = fso.OpenTextFile( _
        fso.GetParentFolderName(WScript.ScriptFullName) _
        + "\" + FileName, 1)
    ExecuteGlobal Stream.ReadAll() 
    Call Stream.Close
End Sub
'--------------------------------------------------

'------------------------------
'◇メイン処理
'------------------------------
Call Main

Sub Main
    Dim MessageText: MessageText = ""

    Dim IniFilePath: IniFilePath = _
        PathCombine(Array(ScriptFolderPath, "SupportTool.ini"))

    Dim IniFile: Set IniFile = New IniFile
    Call IniFile.Initialize(IniFilePath)

    '------------------------------
    '・設定読込
    '------------------------------
    Dim Library_Source_Path: Library_Source_Path = _
        IniFile.ReadString("Option", "LibrarySourcePath", "")

    Dim ProjectName: ProjectName = _
        IniFile.ReadString("Option", "ProjectName", "")

    Dim IgnoreFileFolderName: IgnoreFileFolderName = _
        IniFile.ReadString("Option", "ReleaseIgnoreFileFolderName", "")

    Dim IncludeFileFolderPath: IncludeFileFolderPath = _
        IniFile.ReadString("Option", "ReleaseIncludeFileFolderPath", "")

    Dim ScriptEncoderExePath: ScriptEncoderExePath = _
        IniFile.ReadString("Option", "ScriptEncoderExePath", "")

    Dim ScriptEncodeTargets: ScriptEncodeTargets = _
        IniFile.ReadString("Option", "ScriptEncodeTargets", "")
    '------------------------------

    Dim NowValue: NowValue = Now
    Dim ReleaseFolderPath: ReleaseFolderPath = _
        PathCombine(Array( _
            "..\..\\Release", _
            "Recent", _
            ProjectName))

    Dim SourceFolderPath: SourceFolderPath = _
        "..\..\Source\" + _
        ProjectName
    SourceFolderPath = _
        AbsoluteFilePath(ScriptFolderPath, SourceFolderPath)

    If not fso.FolderExists(SourceFolderPath) Then
        WScript.Echo _
            "コピー元フォルダが見つかりません" + vbCrLF + _
            SourceFolderPath
        Exit Sub
    End If

    'フォルダ再生成コピー
'    Call ReCreateCopyFolder(SourceFolderPath, ReleaseFolderPath)
    Call ReCreateFolder(fso.GetParentFolderName(ReleaseFolderPath))
    Call CopyFolderIgnorePath( _
        SourceFolderPath, ReleaseFolderPath, _
        IgnoreFileFolderName)

    MessageText = MessageText + _
        fso.GetFileName(SourceFolderPath) + vbCrLf

    'バージョン情報ファイルやReadme.txtの指定など
    Dim IncludeFileFolderArray: IncludeFileFolderArray = _
        Split(IncludeFileFolderPath, ",")
    Dim I
    For I = 0 To ArrayCount(IncludeFileFolderArray) - 1
        IncludeFileFolderArray(I) = _
            AbsoluteFilePath(ScriptFolderPath, IncludeFileFolderArray(I))
        If fso.FileExists(IncludeFileFolderArray(I)) Then
            Call ForceCreateFolder(ReleaseFolderPath)
            Call fso.CopyFile( _
                IncludeFileFolderArray(I), _
                    IncludeLastPathDelim(ReleaseFolderPath) + _
                    fso.GetFileName(IncludeFileFolderArray(I)))
        ElseIf fso.FolderExists(IncludeFileFolderArray(I)) Then
            Call ForceCreateFolder(ReleaseFolderPath)
            Call fso.CopyFolder( _
                IncludeFileFolderArray(I), _
                    IncludeLastPathDelim(ReleaseFolderPath) + _
                    fso.GetFileName(IncludeFileFolderArray(I)))
        Else
            MessageText = StringCombine(vbCrLf, Array( _
                MessageText, _
                "Warning:Include File/Folder not found."))
        End If
    Next

    'スクリプトエンコード
    Dim ScriptEncodeTargetArray: ScriptEncodeTargetArray = _
        Split(ScriptEncodeTargets, ",")
    If (1 <= ArrayCount(ScriptEncodeTargetArray)) Then
        If fso.FileExists(ScriptEncoderExePath) = False Then
            MessageText = StringCombine(vbCrLf, Array( _
                MessageText, _
                "Worning:ScriptEncoder not found."))
        Else
            For I = 0 To ArrayCount(ScriptEncodeTargetArray) - 1
                ScriptEncodeTargetArray(I) = AbsoluteFilePath( _ 
                    ScriptFolderPath, ScriptEncodeTargetArray(I))

                'コピー先のリリースフォルダで処理を行う
                ScriptEncodeTargetArray(I) = Replace(ScriptEncodeTargetArray(I), _
                    SourceFolderPath, ReleaseFolderPath)

                Call IncludeExpanded(ScriptEncodeTargetArray(I), ScriptEncodeTargetArray(I))
                Call EncodeVBScriptFile( _
                    ScriptEncoderExePath, _
                    ScriptEncodeTargetArray(I), _
                    ChangeFileExt(ScriptEncodeTargetArray(I), ".vbe"))
            Next
            For I = 0 To ArrayCount(ScriptEncodeTargetArray) - 1
                Call ForceDeleteFile(ScriptEncodeTargetArray(I))
                Call ForceDeleteFolder( _
                    PathCombine(Array( _
                    fso.GetParentFolderName(ScriptEncodeTargetArray(I)), _
                    "Lib")) )
                'vbsファイルとLibフォルダの削除
            Next
        End If
    End If

    Call WScript.Echo(StringCombine(vbCrLf, Array( _
        "Finish " + WScript.ScriptName, _
        "----------", _
        MessageText)))

End Sub

