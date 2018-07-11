#NoEnv
SetBatchLines -1
ListLines Off
SendMode Input
SetWorkingDir %A_ScriptDir%

global ModType := []
global Percent := []
global ModTypeList := ["CampsStacked", "CreepScore", "Deaths", "FirstBlood", "Kills","ObsWardsPlanted", "RoshanKills", "RunesGrabbed", "Stuns", "Teamfight", "TowerKills"]
global PercentList := ["5", "10", "15", "20", "25"]

IfWinExist Dota 2
{
	WinActivate
	
	For index, element in ModTypeList
	{		
		CurrentMod := ModTypeList[index]
		
		ImageSearch, FoundX, FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, *15 %A_ScriptDir%\Images\Dota2-CardAnalyzer\%CurrentMod%.png
		
		If ErrorLevel = 0
		{
			ModType.Push(CurrentMod)
			Percent.Push(GetPercent(FoundX, FoundY))
		}
	}
	
	MessageString := "Found the following mods:"
	
	for index, element in ModType
	{
		MessageString .= "`n" ModType[index] ": " Percent[index] "%"
	}
	
	MsgBox %MessageString%
}
ExitApp

GetModType()
{

}

GetPercent(TopX, TopY)
{
	For indexPer, elementPer in PercentList
	{
		CurrentPercent := PercentList[indexPer]
		
		ImageSearch, FoundX, FoundY, TopX, TopY, TopX + 400, TopY + 25, *15 %A_ScriptDir%\Images\Dota2-CardAnalyzer\%CurrentPercent%.png
		
		If ErrorLevel = 0
			return %CurrentPercent%
	}
}