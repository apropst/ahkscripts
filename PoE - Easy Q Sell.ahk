#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

; USING CTRL+SPACE WILL FORCE THE SCRIPT TO STOP.
; IF POE IS NOT THE FOCUS, SCRIPT WILL STOP.

Global Stop := 0

MousePosX := 55
MousePosY := 250

XIndex := 1
YIndex := 1

Array := Object()

ArrayCount := 0

IfWinActive Path of Exile
{
	If (GetType() = "Gem")
	{
		OutputDebug, AHK %A_Now%: Entered base if
		LoopCount := 12
		RowIncrement := 70
	}
	Else
	{
		OutputDebug, AHK %A_Now%: Entered else if
		LoopCount := 6
		RowIncrement := 140
	}
	
	Loop, %LoopCount%
	{
		Loop, 12
		{
			CheckStatus()
			MouseMove, %MousePosX%, %MousePosY%
			CheckStatus()
			Sleep, 100
			
			clipboard :=
			
			Send ^c
			
			;Array[ArrayCount] := ReturnQuality(clipboard)
			
			ArrayCount += 1
			
			MousePosX += 70
			Sleep, 250
		}
		MousePosX := 55
		MousePosY += %RowIncrement%
	}
}
ExitApp

GetType()
{
	MouseMove, 55, 250
	
	clipboard :=
	
	Send ^c
	
	If Clipboard contains Gem
	{
		OutputDebug, AHK %A_Now%: Returned Gem
		return Gem
	}
	Else
	{
		OutputDebug, AHK %A_Now%: Returned Flask
		return Flask
	}
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

}


FindSolution(numbers, target, partial)
{

}

Space::Stop = 1