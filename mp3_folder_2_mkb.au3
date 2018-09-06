#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=n
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <AutoItConstants.au3>
#include <File.au3>
#include <Date.au3>

Local $Apendto = ''
Local $sDrive = "", $sDir = "", $sFileName = "", $sExtension = ""


$media_info_dll = DllOpen(@ScriptDir & "\MediaInfo.dll")
If $media_info_dll = -1 Then
	OnAutoItExitUnRegister("OnAutoItExit")
	MsgBox(16, "Error", "Was unable to load MediaInfo DLL." & @CRLF & @CRLF & "Reinstalling the application may fix the issue.")
	Exit
EndIf
$media_info_handle = DllCall($media_info_dll, "ptr", "MediaInfo_New")

Local $sFileSelectFolder = FileSelectFolder('Select folder of mp3 files', "")

Local $aFileList = _FileListToArray($sFileSelectFolder, "*.mp3", 1, True)
If @error = 1 Then
	MsgBox($MB_SYSTEMMODAL, "", "Path was invalid.")
	Exit
EndIf
If @error = 4 Then
	MsgBox($MB_SYSTEMMODAL, "", "No file(s) were found.")
	Exit
EndIf

;~ Getting Output & Path
$aPathSplit = _PathSplit($aFileList[1], $sDrive, $sDir, $sFileName, $sExtension)
$aPathSplit[1] = StringUpper($aPathSplit[1])
$aPathSplit[2] = StringReplace($aPathSplit[2], '\', '\\')
$aPathSplit[0] = $aPathSplit[1] & $aPathSplit[2] & $aPathSplit[3] & $aPathSplit[4]
$aPathSplit[4] = $aPathSplit[1] & $aPathSplit[2] & $aPathSplit[3] & '.mkb'
$Output = $aPathSplit[4]
$path = $aPathSplit[1] & $aPathSplit[2]

;~ chapters
Global $aArray_2D[UBound($aFileList) + 1][6]
$aArray_2D[1][4] = 0
$chfile = FileOpen(@WorkingDir & "\chapters.txt", 2)
For $x = 1 To UBound($aFileList) - 1
	$aArray_2D[$x][0] = $aFileList[$x]
	$aPathSplit = _PathSplit($aArray_2D[$x][0], $sDrive, $sDir, $sFileName, $sExtension)
	$aArray_2D[$x][1] = $aPathSplit[3]
	$aArray_2D[$x][2] = _Get_MediaInfo($aArray_2D[$x][0], "General;%Duration/String3%")
	$aArray_2D[$x][3] = _TimeToTicksEx($aArray_2D[$x][2])
	$aArray_2D[$x + 1][4] = $aArray_2D[$x][3] + $aArray_2D[$x][4]
	$aArray_2D[$x][5] = _TicksToTimeEx($aArray_2D[$x][4])
	FileWriteLine($chfile, "CHAPTER" & StringFormat("%.2i", $x) & '=' & $aArray_2D[$x][5])
	FileWriteLine($chfile, 'CHAPTER' & StringFormat("%.2i", $x) & 'NAME=' & $aArray_2D[$x][1])
Next
FileClose($chfile)


;~ Generate options.json
$jsfile = FileOpen(@WorkingDir & "\options.json", 2)
FileWriteLine($jsfile, '[')
FileWriteLine($jsfile, '  "--ui-language",')
FileWriteLine($jsfile, '  "en",')
FileWriteLine($jsfile, '  "--output",')
FileWriteLine($jsfile, '  "' & $Output & '",')
FileWriteLine($jsfile, '  "--language",')
FileWriteLine($jsfile, '  "0:und",')
For $x = 1 To $aFileList[0]
	FileWriteLine($jsfile, '  "(",')
	$aPathSplit = _PathSplit($aFileList[$x], $sDrive, $sDir, $sFileName, $sExtension)
	FileWriteLine($jsfile, '  "' & StringUpper($aPathSplit[1]) & StringReplace($aPathSplit[2], '\', '\\') & $aPathSplit[3] & $aPathSplit[4] & '",')
	FileWriteLine($jsfile, '  ")",')
	If $x = $aFileList[0] Then
		Sleep(0)
	Else
		FileWriteLine($jsfile, '  "+",')
	EndIf
Next
For $y = 1 To $aFileList[0] - 1
	If $y = $aFileList[0] - 1 Then
		$Apendto = $Apendto & $y & ':0:' & $y - 1 & ':0'
	Else
		$Apendto = $Apendto & $y & ':0:' & $y - 1 & ':0,'
	EndIf
Next
If FileExists(@WorkingDir & "\folder.jpg") Then
	FileWriteLine($jsfile, '  "--attachment-name",')
	FileWriteLine($jsfile, '  "folder.jpg",')
	FileWriteLine($jsfile, '  "--attachment-mime-type",')
	FileWriteLine($jsfile, '  "image/jpeg",')
	FileWriteLine($jsfile, '  "--attach-file",')
	FileWriteLine($jsfile, '  "' & $path & 'folder.jpg",')
EndIf

FileWriteLine($jsfile, '  "--chapters",')
FileWriteLine($jsfile, '  "' & $path & 'chapters.txt",')
FileWriteLine($jsfile, '  "--append-to",')
FileWriteLine($jsfile, '  "' & $Apendto & '"')
FileWriteLine($jsfile, ']')
FileClose($jsfile)









RunWait('C:\Program Files\MKVToolNix\mkvmerge.exe --gui-mode @options.json', @WorkingDir)




Func OnAutoItExit()
	DllCall($media_info_dll, "none", "MediaInfo_Delete", "ptr", $media_info_handle[0])
	DllClose($media_info_dll)
EndFunc   ;==>OnAutoItExit
Func _Get_MediaInfo($path, $info_type)
	DllCall($media_info_dll, "none", "MediaInfo_Delete", "ptr", $media_info_handle[0])
	$media_info_handle = DllCall($media_info_dll, "ptr", "MediaInfo_New")
	DllCall($media_info_dll, "int", "MediaInfo_Open", "ptr", $media_info_handle[0], "wstr", $path)
	DllCall($media_info_dll, "wstr", "MediaInfo_Option", "ptr", 0, "wstr", "Inform", "wstr", $info_type)
	$return = DllCall($media_info_dll, "wstr", "MediaInfo_Inform", "ptr", $media_info_handle[0], "int", 0)
	Return $return[0]
EndFunc   ;==>_Get_MediaInfo



; #FUNCTION# ====================================================================================================================
; Name...........: _TicksToTimeEx
; Description ...: Converts a tick count to time in the following format HH:MM:SS or HH:MM or the numerical representation HH.MM
; Syntax.........: _TicksToTimeEx( $iTicks [, $Seconds = 1 [, $Convert = 0 [, $Standard = 0 [, $Milli ]]]] )
; Parameters ....: $iTicks 	 - The number of ticks to convert
;				   $Seconds  - [optional] Sets wether or not the seconds are returned or just hours and minutes. 1 is shown, 0 is not shown. Default is 1
;				   $Convert  - [optional] Sets wether or not the resulting time is converted to the numerical representation of the number. 1 is convert, 0 is don't convert. Default is 0
;				   $Standard - [optional] Sets wether or not the time is returned in Standard time rather than military time. 1 is Standard, 0 is military. Default is 0
;				   $Milli	 - [optional] Sets wether or not the seconds will be rounded to the nearest second, or show the milliseconds. 1 shows the milliseconds, 0 does not. Default is 0
; Return values .: Success - The timestamp in the format HH:MM:SS.MS, HH:MM:SS, HH:MM or HH.MM
;				   Failure - 0
; Author ........: Kris Mills <fett8802 at gmail dot com>
; Remarks .......: May include options for other formats later.
;				   Standard mode won't be used very often.
; Required.File..: #include <Date.au3> - This is included as part of this UDF
; UserCallTip....: _TicksToTimeEx ( "ticks" [, "seconds" [, "convert" [, "standard" [, "milliseconds" ]]]] ) Converts a tick count to time in the following format - HH:MM:SS.MS, HH:MM:SS, HH:MM or the numerical representation HH.MM (required: #include <KrisUDF.au3>)
; Modified.......: 3/8/2011  - Created, commented, added function header
;				   3/29/2011 - Added the $Seconds, $Convert, and $Standard coding and functionality
;				   3/30/2011 - Changed the $iExt to include the " " rather than an extra space in the return
;				   5/2/2011  - Added the millisecond functionality to the function
; ===============================================================================================================================
Func _TicksToTimeEx($iTicks, $Seconds = 1, $Convert = 0, $Standard = 0, $Milli = 1)
	Local $iHours, $iMins, $iSecs, $iExt, $iMilli = "" ;Set the local time variables
	If $Milli = 1 Then ;If the user has selected to use the Milliseconds, then
		$iMilli = StringRight($iTicks, 3) ;Return the millisecond value
		$iTicks = StringTrimRight($iTicks, 3) & "000" ;Get the new iTicks value (remove the milliseconds and add '000')
	EndIf
	$Fail = _TicksToTime($iTicks, $iHours, $iMins, $iSecs) ;Run the original TicksToTime function
	If $Fail = 0 Then Return 0 ;If the TicksToTime function fails, return 0
	If StringLen($iHours) = 1 Then $iHours = 0 & $iHours ;Pad the Hours number with a leading 0 if only one digit
	If StringLen($iMins) = 1 Then $iMins = 0 & $iMins ;Pad the Minutes number with a leading 0 if only one digit
	If StringLen($iSecs) = 1 Then $iSecs = 0 & $iSecs ;Pad the Second number with a leading 0 if only one digit
	If $Convert = 1 Then ;If the user chose to convert, then
		If $iHours < 10 Then $iHours = StringTrimLeft($iHours, 1) ;If $iHours is less then ten, remove the leading 0
		$iMins = StringTrimLeft(Round($iMins / 60, 2), 2) ;Convert $iMins to the numerical value
		If $iMins = "" Then Return $iHours ;If $iMins is blank, return just the hours
		Return $iHours & "." & $iMins ;Return the time in a numerical value
	EndIf
	If $Standard = 1 Then ;If the user has chosen to return the value in standard time, then
		If $iHours < 12 Then $iExt = " AM" ;If the time is below 12:00 PM then write AM
		If $iHours >= 12 Then $iExt = " PM" ;If the time is above 12:00 PM then write PM
		If $iHours >= 13 Then $iHours = $iHours - 12 ;If the time is 1 PM or above, subtract 12 from the value
		If $iHours = "00" Then $iHours = 12 ;If the time is 12 AM, set the $iHours to 12
	EndIf
	If $Seconds = 0 Then Return $iHours & ":" & $iMins & $iExt ;If the user chose not to see seconds, return only hours and minutes
	If $Milli = 1 Then Return $iHours & ":" & $iMins & ":" & $iSecs & "." & StringFormat("%.3i", $iMilli) ;If the user chose to return milliseconds, return the resulting timestamp
	Return $iHours & ":" & $iMins & ":" & $iSecs & $iExt ;Return the resulting timestamp
EndFunc   ;==>_TicksToTimeEx


; #FUNCTION# ====================================================================================================================
; Name...........: _TimeToTicksEx
; Description ...: Converts a given time (In Military, Standard, or Numeric) to a tick amount
; Syntax.........: _TimeToTicksEx( $Time [, $Numeric = 0 ] )
; Parameters ....: $Time - The time to convert to ticks. Format can be any of the following:
;							(Military)		(Standard)(If Numeric = 1)
;							- HH			- HH A			- HH AM			- HH P			- HH PM			- N
;							- HH:MM			- HH:MM A		- HH:MM AM		- HH:MM P		- HH:MM PM		- N.N
;							- HH:MM:SS		- HH:MM:SS A	- HH:MM:SS AM	- HH:MM:SS P	- HH:MM:SS PM	- etc.
;							- HH:MM:SS.MS	- HH:MM:SS.MS A	- HH:MM:SS.MS AM- HH:MM:SS.MS P	- HH:MM:SS.MS PM
; Return values .: Success - The tick amount
;				   Failuer - 0 - Denotes that a user tried to enter a time value as a numeric value.
; Author ........: Kris Mills <fett8802 at gmail dot com>
; Remarks .......:
; Required.File..: #include <Date.au3> and #include <Array.au3> - Both are included as part of this UDF
; UserCallTip....: _TimeToTicksEx ( "time" [, "numeric" ] ) Converts a time (Standard A/P/AM/PM, Military, or Numeric) to a tick amount.(required: #include <KrisUDF.au3>)
; Modified.......: 3/29/2011 - Created, commented, added a function header
;				   3/31/2011 - Removed the $Ticks variable from the last line (Return $Ticks) and just directly returned the result
;							 - Added the numeric functionality
;				   5/2/2011	 - Added the milliseconds functionality to the function
; ===============================================================================================================================
Func _TimeToTicksEx($Time, $Numeric = 0)
	Dim $TimeArray[3], $DecArray[2] ;Declare the local arrays for use in this function
	Local $AM = 0, $PM = 0 ;Declare the local variables for use in this function
	If $Numeric = 1 Then ;If the user has selected to return a numeric value, then
		If StringInStr($Time, ":") <> 0 Then Return 0 ;If the given time is in a timestamp, return an error
		$Time = _ForceInsigZero($Time, 3) ;Force the number to contain two decimal places
		$TimeArray = StringSplit($Time, ".") ;Delimit the string based on .
		MsgBox(0, 'TEST', $TimeArray)
		_ArrayDisplay($TimeArray)
		Return _TimeToTicks($TimeArray[1], Round((($TimeArray[2] * 60) / 100), 0)) ;Return the tick value for the entered numerical value
	EndIf
	If StringInStr($Time, "A") <> 0 Or StringInStr($Time, "P") <> 0 Then ;If the string contains an A or a P
		If StringInStr($Time, "A") <> 0 Then $AM = 1 ;Set the $AM variable to 1 if the time is AM
		If StringInStr($Time, "P") <> 0 Then $PM = 12 ;If the time is P or PM, then set the $PM variable to 12
		If StringInStr($Time, "M") = 0 Then $Time = StringTrimRight($Time, 2) ;If the string does not contain an M, remove two characters from the right
		If StringInStr($Time, "M") <> 0 Then $Time = StringTrimRight($Time, 3) ;If the string contains an M, remove three characters from the right
	EndIf
	$TimeArray = StringSplit($Time, ":") ;Delimit the string based on ":"
	If $TimeArray[1] = 12 And $AM = 1 Then $TimeArray[1] = "00" ;Set the hours to 00 if the time was 12 AM
	If $TimeArray[1] <> 12 Then $TimeArray[1] = $TimeArray[1] + $PM ;Add the $PM value to the hour variable in the array if the value is already 12
	If UBound($TimeArray) = 2 Then _ArrayAdd($TimeArray, "00") ;If there is no second value, make it "00"
	If UBound($TimeArray) = 3 Then _ArrayAdd($TimeArray, "00") ;If there is no third valur, make it "00"
	If StringInStr($TimeArray[3], ".") <> 0 Then ;If there are milliseconds in the seconds time, then
		$DecArray = StringSplit($TimeArray[3], ".") ;Delimit the string at the decimal
		$DecArray[2] = ('.' & $DecArray[2]) * 1000
		$Ticks = _TimeToTicks($TimeArray[1], $TimeArray[2], $DecArray[1]) ;Get the ticks value
		Return $Ticks + $DecArray[2] ;Add the milliseconds to the ticks value
	EndIf
	Return _TimeToTicks($TimeArray[1], $TimeArray[2], $TimeArray[3]) ;Get the ticks of the time and return the value
EndFunc   ;==>_TimeToTicksEx

; #FUNCTION# ====================================================================================================================
; Name...........: _PauseScript
; Description ...: Pauses the script and prompts the user to return to the script, or exit
; Syntax.........: _PauseScript()
; Parameters ....: None
; Return values .: None
; Author ........: Kris Mills <fett8802 at gmail dot com>
; Remarks .......:
; UserCallTip....: _PauseScript ( ) Pause the script and prompt the user to end or continue.(required: #include <KrisUDF.au3>)
; Modified.......: 3/8/2011
; ===============================================================================================================================
Func _PauseScript()
	$Pause_Msg = MsgBox(4164, "Script Paused", "The script has been paused. Do you wish to resume the script?") ;Prompt the user to eithe continue or end the script
	If $Pause_Msg = 7 Then Exit ;If the user selects to end the script, then exit
EndFunc   ;==>_PauseScript

; #FUNCTION# ====================================================================================================================
; Name...........: _ForceInsigZero
; Description ...: Forces insignificant zeroes onto the end of a number string. Also can be used to define exactly how many decimal places to be return
; Syntax.........: _ForceInsigZero( $Number [, $DecimalPlaces = 2 ] )
; Parameters ....: $Number 			- The original number to be modified
;				   $DecimalPlaces 	- [optional] The amount of decimal places to be returned. If this is lower than the current amount
;												 of decimal places, the extras are removed. If this is above the current amount, zeroes are added
; Return values .: The modified number
; Author ........: Kris Mills <fett8802 at gmail dot com>
; Remarks .......:
; UserCallTip....: _ForceInsigZero ( "number" [, "decimal places" ] ) Forces insignificant zeroes onto the end of a number string. Also can be used to define exactly how many decimal places to be return.(required: #include <KrisUDF.au3>)
; Modified.......: 3/31/2011 - Created, commented, and added a function header
; ===============================================================================================================================
Func _ForceInsigZero($Number, $DecimalPlaces = 2)
	Dim $aNumber[3] ;Declare the array to be used in this function
	If StringInStr($Number, ".") <> 0 Then ;If the string does include a . , then
		$aNumber = StringSplit($Number, ".") ;Delimit the string based on .
	Else ;If the string does not include a . , then
		$aNumber[1] = $Number ;Set the aNumber[1] to the given number
	EndIf
	If $DecimalPlaces > 0 Then ;If the user chose to have decimal places, then
		If $DecimalPlaces < StringLen($aNumber[2]) Then Return $aNumber[1] & "." & StringLeft($aNumber[2], $DecimalPlaces) ;If the given decimal places is lower than the length of the string, return the shortened number
		For $i = StringLen($aNumber[2]) To $DecimalPlaces - 1 ;Start a For loop. This will repeat for each added zero
			$aNumber[2] = $aNumber[2] & "0" ;Add a zero to the end of the string
		Next ;Perform the next iteration of the For loop
		Return $aNumber[1] & "." & $aNumber[2] ;Return the full number with added zeros
	Else ;If the user chose not to have decimal places, then
		Return $aNumber[1] ;Return only the integer
	EndIf
EndFunc   ;==>_ForceInsigZero
