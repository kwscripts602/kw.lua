-- KING LEGACY - KW EFEITOS, KW MAPA e ESP PLAYER v31
-- Design: Vermelho e Preto | Minimizar | Fechar | Toggle

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Lighting = game:GetService("Lighting")

-- ==================== CONFIG EFEITOS ====================
local ativoEfeitos = true
local removendoGraficos = true
local percentualEfeitos = 80
local congeladosEfeitos = setmetatable({}, {__mode = "k"})

-- ==================== CONFIG ESP ====================
local espAtivado = true
local espHighlights = {}

local PROTEGIDOS = {"damage","number","nametag","health","hp","bar",
                    "gui","ui","hud","text","label","crosshair","cursor",
                    "button","frame","icon","image","logo","panel",
                    "percent","textlabel","textbutton"}

local function ehProtegido(nome)
    local n = string.lower(nome)
    for i = 1, #PROTEGIDOS do
        if string.find(n, PROTEGIDOS[i], 1, true) then return true end
    end
    return false
end

local function ehUI(obj)
    local p = obj.Parent
    while p do
        if p:IsA("ScreenGui") or p:IsA("BillboardGui")
           or p:IsA("SurfaceGui") or p:IsA("PlayerGui") then
            return true
        end
        p = p.Parent
    end
    return false
end

local acumuladorEfeitos = 0
local function deveMatarEfeito(obj)
    acumuladorEfeitos = acumuladorEfeitos + (percentualEfeitos / 100)
    if acumuladorEfeitos >= 1 then
        acumuladorEfeitos = acumuladorEfeitos - 1
        return true
    end
    return false
end

local function processarEfeito(obj)
    if not ativoEfeitos or not removendoGraficos or not obj or not obj.Parent then return end
    if ehProtegido(obj.Name) then return end
    if ehUI(obj) then return end
    if congeladosEfeitos[obj] then return end

    pcall(function()
        local tipo = obj:IsA("ParticleEmitter") or obj:IsA("Beam")
                   or obj:IsA("Trail") or obj:IsA("Fire")
                   or obj:IsA("Smoke") or obj:IsA("Sparkles")
        if not tipo then return end
        if percentualEfeitos <= 0 then return end

        if deveMatarEfeito(obj) then
            congeladosEfeitos[obj] = true
            if obj:IsA("ParticleEmitter") then
                obj.Enabled = false
                obj.Rate = 0
                obj.Lifetime = NumberRange.new(0,0)
                obj.Speed = NumberRange.new(0,0)
                obj.Size = NumberSequence.new(0)
                obj.Transparency = NumberSequence.new(1)
            else
                obj.Enabled = false
                if obj:IsA("Trail") or obj:IsA("Beam") then
                    obj.Transparency = NumberSequence.new(1)
                end
            end
        end
    end)
end

-- ==================== CONFIG MAPA ====================
local ativoMapa = true
local removendoMapa = true
local percentualMapa = 80 
local efeitosRemovidos = {}

local function aplicarMapa()
    if not ativoMapa or not removendoMapa then return end
    pcall(function()
        local fator = percentualMapa / 100
        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("BloomEffect") or obj:IsA("BlurEffect") or obj:IsA("SunRaysEffect") or obj:IsA("DepthOfFieldEffect") or obj:IsA("ColorCorrectionEffect") then
                if not efeitosRemovidos[obj] then efeitosRemovidos[obj] = obj.Enabled end
                obj.Enabled = false
            end
        end
        Lighting.GlobalShadows = (fator < 0.8)
        Lighting.Brightness = 2 * (1 - fator * 0.5)
        Lighting.EnvironmentDiffuseScale = 1 - fator
        Lighting.EnvironmentSpecularScale = 1 - fator
        Lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5):Lerp(Color3.new(0.1, 0.1, 0.1), fator)
        
        local corCorrection = Lighting:FindFirstChild("KW_ColorCorrection")
        if not corCorrection then
            corCorrection = Instance.new("ColorCorrectionEffect")
            corCorrection.Name = "KW_ColorCorrection"
            corCorrection.Parent = Lighting
        end
        corCorrection.Saturation = -fator
        corCorrection.Contrast = fator * 0.2
    end)
end

local function restaurarMapa()
    pcall(function()
        for obj, estado in pairs(efeitosRemovidos) do
            if obj and obj.Parent then obj.Enabled = estado end
        end
        efeitosRemovidos = {}
        local cc = Lighting:FindFirstChild("KW_ColorCorrection")
        if cc then cc:Destroy() end
    end)
end

-- ==================== LOGICA ESP PLAYER ====================
local function atualizarESP()
    if not espAtivado then
        for plr, h in pairs(espHighlights) do
            if h then h:Destroy() end
        end
        espHighlights = {}
        return
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            if not espHighlights[plr] or not espHighlights[plr].Parent then
                local h = Instance.new("Highlight")
                h.Name = "KW_ESP"
                h.Adornee = plr.Character
                h.FillColor = Color3.fromRGB(255, 255, 255)
                h.OutlineColor = Color3.fromRGB(255, 255, 255)
                h.FillTransparency = 0.5
                h.OutlineTransparency = 0
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                h.Parent = plr.Character
                
                local bg = Instance.new("BillboardGui")
                bg.Name = "KW_ESP_Name"
                bg.Size = UDim2.new(0, 100, 0, 20)
                bg.StudsOffset = Vector3.new(0, 3, 0)
                bg.AlwaysOnTop = true
                bg.Parent = plr.Character:FindFirstChild("Head") or plr.Character:FindFirstChild("HumanoidRootPart")
                
                local txt = Instance.new("TextLabel")
                txt.Size = UDim2.new(1, 0, 1, 0)
                txt.BackgroundTransparency = 1
                txt.Text = plr.Name
                txt.TextColor3 = Color3.fromRGB(255, 255, 255)
                txt.TextStrokeTransparency = 0
                txt.Font = Enum.Font.GothamBold
                txt.TextSize = 14
                txt.Parent = bg
                
                espHighlights[plr] = h
            end
        end
    end
end

-- ==================== PAINEL KW EFEITOS ====================
local guiEfeitos = Instance.new("ScreenGui")
guiEfeitos.Name = "KW_Efeitos"
guiEfeitos.ResetOnSpawn = false
guiEfeitos.IgnoreGuiInset = true
guiEfeitos.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
guiEfeitos.Parent = game:GetService("CoreGui")

local frameEfeitos = Instance.new("Frame")
frameEfeitos.Name = "MainFrame"
frameEfeitos.Size = UDim2.new(0, 220, 0, 235) -- Aumentado para caber o botão ESP
frameEfeitos.Position = UDim2.new(0, 20, 0.5, -117)
frameEfeitos.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
frameEfeitos.BorderColor3 = Color3.fromRGB(180, 0, 0)
frameEfeitos.BorderSizePixel = 2
frameEfeitos.Active = true
frameEfeitos.Draggable = true
frameEfeitos.Parent = guiEfeitos

local tituloEfeitos = Instance.new("TextLabel")
tituloEfeitos.Name = "Title"
tituloEfeitos.Size = UDim2.new(1, -60, 0, 30)
tituloEfeitos.Position = UDim2.new(0, 0, 0, 0)
tituloEfeitos.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
tituloEfeitos.BorderSizePixel = 0
tituloEfeitos.Text = "KW EFEITOS"
tituloEfeitos.TextColor3 = Color3.fromRGB(255, 255, 255)
tituloEfeitos.Font = Enum.Font.GothamBold
tituloEfeitos.TextSize = 14
tituloEfeitos.Parent = frameEfeitos

local btnMinEfeitos = Instance.new("TextButton")
btnMinEfeitos.Name = "MinimizeBtn"
btnMinEfeitos.Size = UDim2.new(0, 30, 0, 30)
btnMinEfeitos.Position = UDim2.new(1, -60, 0, 0)
btnMinEfeitos.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
btnMinEfeitos.BorderSizePixel = 0
btnMinEfeitos.Text = "-"
btnMinEfeitos.TextColor3 = Color3.fromRGB(255, 255, 255)
btnMinEfeitos.Font = Enum.Font.GothamBold
btnMinEfeitos.TextSize = 20
btnMinEfeitos.Parent = frameEfeitos

local btnCloseEfeitos = Instance.new("TextButton")
btnCloseEfeitos.Name = "CloseBtn"
btnCloseEfeitos.Size = UDim2.new(0, 30, 0, 30)
btnCloseEfeitos.Position = UDim2.new(1, -30, 0, 0)
btnCloseEfeitos.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
btnCloseEfeitos.BorderSizePixel = 0
btnCloseEfeitos.Text = "X"
btnCloseEfeitos.TextColor3 = Color3.fromRGB(255, 255, 255)
btnCloseEfeitos.Font = Enum.Font.GothamBold
btnCloseEfeitos.TextSize = 14
btnCloseEfeitos.Parent = frameEfeitos

local contentEfeitos = Instance.new("Frame")
contentEfeitos.Name = "Content"
contentEfeitos.Size = UDim2.new(1, 0, 1, -30)
contentEfeitos.Position = UDim2.new(0, 0, 0, 30)
contentEfeitos.BackgroundTransparency = 1
contentEfeitos.Parent = frameEfeitos

local linhaDecoEfeitos = Instance.new("Frame")
linhaDecoEfeitos.Size = UDim2.new(1, -20, 0, 2)
linhaDecoEfeitos.Position = UDim2.new(0, 10, 0, 5)
linhaDecoEfeitos.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
linhaDecoEfeitos.BorderSizePixel = 0
linhaDecoEfeitos.Parent = contentEfeitos

local botaoMenosEfeitos = Instance.new("TextButton")
botaoMenosEfeitos.Size = UDim2.new(0, 50, 0, 35)
botaoMenosEfeitos.Position = UDim2.new(0, 15, 0, 15)
botaoMenosEfeitos.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
botaoMenosEfeitos.BorderColor3 = Color3.fromRGB(120, 0, 0)
botaoMenosEfeitos.BorderSizePixel = 1
botaoMenosEfeitos.Text = "-"
botaoMenosEfeitos.TextColor3 = Color3.fromRGB(255, 255, 255)
botaoMenosEfeitos.Font = Enum.Font.GothamBold
botaoMenosEfeitos.TextSize = 24
botaoMenosEfeitos.Parent = contentEfeitos

local labelPctEfeitos = Instance.new("TextLabel")
labelPctEfeitos.Size = UDim2.new(0, 80, 0, 35)
labelPctEfeitos.Position = UDim2.new(0, 70, 0, 15)
labelPctEfeitos.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
labelPctEfeitos.BorderColor3 = Color3.fromRGB(80, 0, 0)
labelPctEfeitos.BorderSizePixel = 1
labelPctEfeitos.Text = percentualEfeitos .. "%"
labelPctEfeitos.TextColor3 = Color3.fromRGB(230, 200, 80)
labelPctEfeitos.Font = Enum.Font.GothamBold
labelPctEfeitos.TextSize = 18
labelPctEfeitos.Parent = contentEfeitos

local botaoMaisEfeitos = Instance.new("TextButton")
botaoMaisEfeitos.Size = UDim2.new(0, 50, 0, 35)
botaoMaisEfeitos.Position = UDim2.new(0, 155, 0, 15)
botaoMaisEfeitos.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
botaoMaisEfeitos.BorderSizePixel = 0
botaoMaisEfeitos.Text = "+"
botaoMaisEfeitos.TextColor3 = Color3.fromRGB(255, 255, 255)
botaoMaisEfeitos.Font = Enum.Font.GothamBold
botaoMaisEfeitos.TextSize = 24
botaoMaisEfeitos.Parent = contentEfeitos

local btnToggleEfeitos = Instance.new("TextButton")
btnToggleEfeitos.Size = UDim2.new(0, 200, 0, 30)
btnToggleEfeitos.Position = UDim2.new(0, 10, 0, 60)
btnToggleEfeitos.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
btnToggleEfeitos.BorderColor3 = Color3.fromRGB(180, 0, 0)
btnToggleEfeitos.BorderSizePixel = 1
btnToggleEfeitos.Text = "ATIVADO"
btnToggleEfeitos.TextColor3 = Color3.fromRGB(255, 255, 255)
btnToggleEfeitos.Font = Enum.Font.GothamBold
btnToggleEfeitos.TextSize = 12
btnToggleEfeitos.Parent = contentEfeitos

-- NOVO BOTÃO: ESP PLAYER
local btnToggleESP = Instance.new("TextButton")
btnToggleESP.Size = UDim2.new(0, 200, 0, 30)
btnToggleESP.Position = UDim2.new(0, 10, 0, 100)
btnToggleESP.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
btnToggleESP.BorderColor3 = Color3.fromRGB(180, 0, 0)
btnToggleESP.BorderSizePixel = 1
btnToggleESP.Text = "ESP PLAYER: ON"
btnToggleESP.TextColor3 = Color3.fromRGB(255, 255, 255)
btnToggleESP.Font = Enum.Font.GothamBold
btnToggleESP.TextSize = 12
btnToggleESP.Parent = contentEfeitos

local btnAbrirMapa = Instance.new("TextButton")
btnAbrirMapa.Size = UDim2.new(0, 200, 0, 30)
btnAbrirMapa.Position = UDim2.new(0, 10, 0, 140)
btnAbrirMapa.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
btnAbrirMapa.BorderColor3 = Color3.fromRGB(120, 0, 0)
btnAbrirMapa.BorderSizePixel = 1
btnAbrirMapa.Text = "ABRIR MAPA"
btnAbrirMapa.TextColor3 = Color3.fromRGB(255, 255, 255)
btnAbrirMapa.Font = Enum.Font.GothamBold
btnAbrirMapa.TextSize = 12
btnAbrirMapa.Parent = contentEfeitos

-- ==================== PAINEL KW MAPA ====================
local guiMapa = Instance.new("ScreenGui")
guiMapa.Name = "KW_Mapa"
guiMapa.ResetOnSpawn = false
guiMapa.IgnoreGuiInset = true
guiMapa.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
guiMapa.Parent = game:GetService("CoreGui")
guiMapa.Enabled = false

local frameMapa = Instance.new("Frame")
frameMapa.Name = "MainFrame"
frameMapa.Size = UDim2.new(0, 220, 0, 165)
frameMapa.Position = UDim2.new(0, 260, 0.5, -82)
frameMapa.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
frameMapa.BorderColor3 = Color3.fromRGB(180, 0, 0)
frameMapa.BorderSizePixel = 2
frameMapa.Active = true
frameMapa.Draggable = true
frameMapa.Parent = guiMapa

local tituloMapa = Instance.new("TextLabel")
tituloMapa.Name = "Title"
tituloMapa.Size = UDim2.new(1, -60, 0, 30)
tituloMapa.Position = UDim2.new(0, 0, 0, 0)
tituloMapa.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
tituloMapa.BorderSizePixel = 0
tituloMapa.Text = "KW MAPA"
tituloMapa.TextColor3 = Color3.fromRGB(255, 255, 255)
tituloMapa.Font = Enum.Font.GothamBold
tituloMapa.TextSize = 14
tituloMapa.Parent = frameMapa

local btnMinMapa = Instance.new("TextButton")
btnMinMapa.Size = UDim2.new(0, 30, 0, 30)
btnMinMapa.Position = UDim2.new(1, -60, 0, 0)
btnMinMapa.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
btnMinMapa.BorderSizePixel = 0
btnMinMapa.Text = "-"
btnMinMapa.TextColor3 = Color3.fromRGB(255, 255, 255)
btnMinMapa.Font = Enum.Font.GothamBold
btnMinMapa.TextSize = 20
btnMinMapa.Parent = frameMapa

local btnCloseMapa = Instance.new("TextButton")
btnCloseMapa.Size = UDim2.new(0, 30, 0, 30)
btnCloseMapa.Position = UDim2.new(1, -30, 0, 0)
btnCloseMapa.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
btnCloseMapa.BorderSizePixel = 0
btnCloseMapa.Text = "X"
btnCloseMapa.TextColor3 = Color3.fromRGB(255, 255, 255)
btnCloseMapa.Font = Enum.Font.GothamBold
btnCloseMapa.TextSize = 14
btnCloseMapa.Parent = frameMapa

local contentMapa = Instance.new("Frame")
contentMapa.Name = "Content"
contentMapa.Size = UDim2.new(1, 0, 1, -30)
contentMapa.Position = UDim2.new(0, 0, 0, 30)
contentMapa.BackgroundTransparency = 1
contentMapa.Parent = frameMapa

local linhaDecoMapa = Instance.new("Frame")
linhaDecoMapa.Size = UDim2.new(1, -20, 0, 2)
linhaDecoMapa.Position = UDim2.new(0, 10, 0, 5)
linhaDecoMapa.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
linhaDecoMapa.BorderSizePixel = 0
linhaDecoMapa.Parent = contentMapa

local botaoMenosMapa = Instance.new("TextButton")
botaoMenosMapa.Size = UDim2.new(0, 50, 0, 40)
botaoMenosMapa.Position = UDim2.new(0, 15, 0, 20)
botaoMenosMapa.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
botaoMenosMapa.BorderColor3 = Color3.fromRGB(120, 0, 0)
botaoMenosMapa.BorderSizePixel = 1
botaoMenosMapa.Text = "-"
botaoMenosMapa.TextColor3 = Color3.fromRGB(255, 255, 255)
botaoMenosMapa.Font = Enum.Font.GothamBold
botaoMenosMapa.TextSize = 26
botaoMenosMapa.Parent = contentMapa

local labelPctMapa = Instance.new("TextLabel")
labelPctMapa.Size = UDim2.new(0, 80, 0, 40)
labelPctMapa.Position = UDim2.new(0, 70, 0, 20)
labelPctMapa.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
labelPctMapa.BorderColor3 = Color3.fromRGB(80, 0, 0)
labelPctMapa.BorderSizePixel = 1
labelPctMapa.Text = percentualMapa .. "%"
labelPctMapa.TextColor3 = Color3.fromRGB(230, 200, 80)
labelPctMapa.Font = Enum.Font.GothamBold
labelPctMapa.TextSize = 20
labelPctMapa.Parent = contentMapa

local botaoMaisMapa = Instance.new("TextButton")
botaoMaisMapa.Size = UDim2.new(0, 50, 0, 40)
botaoMaisMapa.Position = UDim2.new(0, 155, 0, 20)
botaoMaisMapa.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
botaoMaisMapa.BorderSizePixel = 0
botaoMaisMapa.Text = "+"
botaoMaisMapa.TextColor3 = Color3.fromRGB(255, 255, 255)
botaoMaisMapa.Font = Enum.Font.GothamBold
botaoMaisMapa.TextSize = 26
botaoMaisMapa.Parent = contentMapa

local btnToggleMapa = Instance.new("TextButton")
btnToggleMapa.Size = UDim2.new(0, 200, 0, 30)
btnToggleMapa.Position = UDim2.new(0, 10, 0, 70)
btnToggleMapa.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
btnToggleMapa.BorderColor3 = Color3.fromRGB(180, 0, 0)
btnToggleMapa.BorderSizePixel = 1
btnToggleMapa.Text = "ATIVADO"
btnToggleMapa.TextColor3 = Color3.fromRGB(255, 255, 255)
btnToggleMapa.Font = Enum.Font.GothamBold
btnToggleMapa.TextSize = 12
btnToggleMapa.Parent = contentMapa

-- ==================== LOGICA BOTOES ====================
local function atualizarLabelEfeitos()
    labelPctEfeitos.Text = percentualEfeitos .. "%"
    if percentualEfeitos < 50 then labelPctEfeitos.TextColor3 = Color3.fromRGB(100, 220, 120)
    elseif percentualEfeitos < 85 then labelPctEfeitos.TextColor3 = Color3.fromRGB(230, 200, 80)
    else labelPctEfeitos.TextColor3 = Color3.fromRGB(230, 90, 90) end
end

botaoMenosEfeitos.MouseButton1Click:Connect(function()
    percentualEfeitos = math.max(0, percentualEfeitos - 1)
    atualizarLabelEfeitos()
end)

botaoMaisEfeitos.MouseButton1Click:Connect(function()
    percentualEfeitos = math.min(99, percentualEfeitos + 1)
    atualizarLabelEfeitos()
end)

btnToggleEfeitos.MouseButton1Click:Connect(function()
    removendoGraficos = not removendoGraficos
    btnToggleEfeitos.Text = removendoGraficos and "ATIVADO" or "DESATIVADO"
    btnToggleEfeitos.BackgroundColor3 = removendoGraficos and Color3.fromRGB(120, 0, 0) or Color3.fromRGB(40, 40, 40)
end)

btnToggleESP.MouseButton1Click:Connect(function()
    espAtivado = not espAtivado
    btnToggleESP.Text = espAtivado and "ESP PLAYER: ON" or "ESP PLAYER: OFF"
    btnToggleESP.BackgroundColor3 = espAtivado and Color3.fromRGB(120, 0, 0) or Color3.fromRGB(40, 40, 40)
    atualizarESP()
end)

local minEfeitos = false
btnMinEfeitos.MouseButton1Click:Connect(function()
    minEfeitos = not minEfeitos
    contentEfeitos.Visible = not minEfeitos
    frameEfeitos.Size = minEfeitos and UDim2.new(0, 220, 0, 30) or UDim2.new(0, 220, 0, 235)
    btnMinEfeitos.Text = minEfeitos and "+" or "-"
end)

btnCloseEfeitos.MouseButton1Click:Connect(function()
    guiEfeitos:Destroy()
    guiMapa:Destroy()
    ativoEfeitos = false
    ativoMapa = false
    espAtivado = false
    atualizarESP()
    restaurarMapa()
end)

btnAbrirMapa.MouseButton1Click:Connect(function()
    guiMapa.Enabled = not guiMapa.Enabled
    btnAbrirMapa.Text = guiMapa.Enabled and "FECHAR MAPA" or "ABRIR MAPA"
    btnAbrirMapa.BackgroundColor3 = guiMapa.Enabled and Color3.fromRGB(120, 0, 0) or Color3.fromRGB(40, 40, 40)
end)

-- ==================== LOGICA MAPA ====================
local function atualizarLabelMapa()
    labelPctMapa.Text = percentualMapa .. "%"
    if percentualMapa < 50 then labelPctMapa.TextColor3 = Color3.fromRGB(100, 220, 120)
    elseif percentualMapa < 85 then labelPctMapa.TextColor3 = Color3.fromRGB(230, 200, 80)
    else labelPctMapa.TextColor3 = Color3.fromRGB(230, 90, 90) end
end

botaoMenosMapa.MouseButton1Click:Connect(function()
    percentualMapa = math.max(0, percentualMapa - 1)
    atualizarLabelMapa()
    aplicarMapa()
end)

botaoMaisMapa.MouseButton1Click:Connect(function()
    percentualMapa = math.min(99, percentualMapa + 1)
    atualizarLabelMapa()
    aplicarMapa()
end)

btnToggleMapa.MouseButton1Click:Connect(function()
    removendoMapa = not removendoMapa
    btnToggleMapa.Text = removendoMapa and "ATIVADO" or "DESATIVADO"
    btnToggleMapa.BackgroundColor3 = removendoMapa and Color3.fromRGB(120, 0, 0) or Color3.fromRGB(40, 40, 40)
    if removendoMapa then
        aplicarMapa()
    else
        restaurarMapa()
    end
end)

local minMapa = false
btnMinMapa.MouseButton1Click:Connect(function()
    minMapa = not minMapa
    contentMapa.Visible = not minMapa
    frameMapa.Size = minMapa and UDim2.new(0, 220, 0, 30) or UDim2.new(0, 220, 0, 165)
    btnMinMapa.Text = minMapa and "+" or "-"
end)

btnCloseMapa.MouseButton1Click:Connect(function()
    guiMapa.Enabled = false
    btnAbrirMapa.Text = "ABRIR MAPA"
    btnAbrirMapa.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
end)

-- ==================== MOTORES ====================
-- Motor Efeitos
task.spawn(function()
    for _, obj in ipairs(workspace:
