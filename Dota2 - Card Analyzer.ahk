#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

ModType := []
Percent := []
ModList := ["Deaths", "CampsStacked", "Stuns"]
PercentList := ["5", "10"]

IfWinExist Dota 2
{
	WinActivate
	
	ImageSearch, FoundX, FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, *10 %A_ScriptDir%\Images\Dota2-CardAnalyzer\Deaths.png
	
	If ErrorLevel = 0
	{
		ModType.Push("Deaths")
		Percent.Push(GetPercent(FoundX, FoundY))
	}
	
	ImageSearch, FoundX, FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, *10 %A_ScriptDir%\Images\Dota2-CardAnalyzer\CampsStacked.png
	
	If ErrorLevel = 0
	{
		ModType.Push("Camps Stacked")
		Percent.Push(GetPercent(FoundX, FoundY))
	}
	
	ImageSearch, FoundX, FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, *10 %A_ScriptDir%\Images\Dota2-CardAnalyzer\Stuns.png
	
	If ErrorLevel = 0
	{
		ModType.Push("Stuns")
		Percent.Push(GetPercent(FoundX, FoundY))
	}
	
	MessageString := "Found the following mods:"
	
	for index, element in ModType
	{
		MessageString .= "`n" ModType[index] ": " Percent[index] "%"
	}
	
	MsgBox %MessageString%
}
ExitApp

GetPercent(TopX, TopY)
{
	ImageSearch, FoundX, FoundY, TopX, TopY, A_ScreenWidth, TopY + 20, *10 %A_ScriptDir%\Images\Dota2-CardAnalyzer\10.png
	
	If ErrorLevel = 0
		return 10
	
	ImageSearch, FoundX, FoundY, TopX, TopY, A_ScreenWidth, TopY + 20, *10 %A_ScriptDir%\Images\Dota2-CardAnalyzer\5.png
	
	If ErrorLevel = 0
		return 5
}