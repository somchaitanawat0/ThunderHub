--[[
    ThunderUI.lua - Rayfield UI Wrapper
    Provides the smooth, modern UI framework for Thunder Hub
    Features: No text overlapping, smooth animations, built-in theme switching
]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local UI = {}

function UI.CreateWindow()
    local Window = Rayfield:CreateWindow({
        Name = "Thunder Hub | Cameraman TD",
        LoadingTitle = "Thunder Hub",
        LoadingSubtitle = "Loading Interface...",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "ThunderHub",
            FileName = "Config"
        },
        KeySystem = false
    })
    
    return Window, Rayfield
end

return UI
