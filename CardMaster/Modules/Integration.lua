local _, Addon = ...

Addon.IntegratedDefaults = {}

-- 1. 拆分独立页面的默认配置数据
Addon.IntegratedDefaults.DEFAULT_SKILL = {
    scale = 0.7,
    mainDuration = 0.5,
    slideX = -150,
    slideY = 50,
    slideOutX = 300,
    slideOutY = -50,
    rotateAngle = 0,
    zoomType = 1,
    stackType = 1, -- 1 = 横向排列，2 = 随机排列
    randomOffsetX = 200,
    randomOffsetY = 50,
    randomRotation = 20,
    zoomW = 1.5,
    zoomH = 1.5,
    posX = 0,
    posY = 200,
}

Addon.IntegratedDefaults.DEFAULT_COMBAT = {
    ciScale = 0.7,
    ciSpeed = 60,   
    ciCardSpacing = 150,
    ciCardRandomX = 0,
    ciCardRandomY = 0,
    ciCardRandomRotation = 0,
    ciPosX = 0,
    ciPosY = -50,
    ciBottomLayer = false,
    ciNormalCombat = true, -- 默认勾选进入普通战斗加载
    ciBossCombat = true,   -- 默认勾选进入首领战斗加载
}


function Addon:IsIntegratedEnabled(key)
    return self.db and self.db.modules[key] and self.db.modules[key].enabled == true
end

function Addon:InitIntegratedModules()
    self.db.integratedCards = self.db.integratedCards or {}
    self.legacyDB = self.db.integratedCards
    for _, defaults in ipairs({self.IntegratedDefaults.DEFAULT_SKILL, self.IntegratedDefaults.DEFAULT_COMBAT}) do
        for key, value in pairs(defaults) do
            if self.legacyDB[key] == nil then self.legacyDB[key] = value end
        end
    end
    self.SingleSpell.SetEnabled(self:IsIntegratedEnabled("singleSpell"))
    self.CombatIn.SetEnabled(self:IsIntegratedEnabled("inCombat"))
end

function Addon:SetIntegratedEnabled(key, enabled)
    self.db.modules[key].enabled = enabled and true or false
    local module = key == "singleSpell" and self.SingleSpell or self.CombatIn
    module.SetEnabled(enabled)
end

function Addon:ResetIntegratedModule(key)
    local single = key == "singleSpell"
    local module = single and self.SingleSpell or self.CombatIn
    module.Stop()
    local defaults = single and self.IntegratedDefaults.DEFAULT_SKILL or self.IntegratedDefaults.DEFAULT_COMBAT
    for name, value in pairs(defaults) do self.legacyDB[name] = value end
    local moduleDefaults = self.defaults.modules[key]
    if moduleDefaults then self.db.modules[key].soundEnabled = moduleDefaults.soundEnabled end
    if single then module.ResetToDefault() else module.UpdateSettings() end
end
