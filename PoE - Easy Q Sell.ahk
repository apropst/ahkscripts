#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

; USING CTRL+SPACE WILL FORCE THE SCRIPT TO STOP.
; IF POE IS NOT THE FOCUS, SCRIPT WILL STOP.
; To-Do:
; -Add logic to handle auto-sell of 20% qual item
; -Add logic to get sums of items = 40%, optimize to maximize Count
; -Add picking functionality, ctrl+click into inventory
; -Add functionality for scanning for an item if no item exists in slot 1,1

Global Stop := 0

MousePosX := 55
MousePosY := 250

XIndex := 1
YIndex := 1

Array := Object()

IfWinActive Path of Exile
{
	If (GetType() = Gem)
	{
		LoopCount := 12
		RowIncrement := 70
	}
	Else If (GetType() = Flask)
	{
		LoopCount := 6
		RowIncrement := 140
	}
	Else
	{
		OutputDebug, AHK %A_Now%: GetType failed.
		ExitApp
	}
	
	Loop, %LoopCount%
	{
		Loop, 12
		{
			CheckStatus()
			MouseMove, %MousePosX%, %MousePosY%
			CheckStatus()
			Sleep, 100
			
			clipboard := "EMPTY"
			
			SendEvent ^c
			
			Array[%XIndex%, %YIndex%] := ReturnQuality(clipboard)
			
			XIndex += 1
			MousePosX += 70
			Sleep, 100
		}
		XIndex := 1
		YIndex += 1
		MousePosX := 55
		MousePosY += %RowIncrement%
	}
}
ExitApp

GetType()
{
	MouseMove, 55, 250
	
	clipboard :=
	
	SendEvent ^c
	
	If Clipboard contains Gem
		return Gem
	Else
		return Flask
}

CheckStatus()
{
	IfWinNotActive Path of Exile
		ExitApp
	If stop = 1
		ExitApp
}

ReturnQuality(textstring)
{
	RegExMatch(textstring, "Quality.*", output)
	StringSplit, outputarray, output, "+"
	StringSplit, outputarrayfinal, outputarray2, "`%"
	return %outputarrayfinal1%
}


FindSolution(numbers, target, partial)
{

}

Space::Stop = 1