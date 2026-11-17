local _, Addon = ...
local locales = {enUS=1, zhCN=2, zhTW=3, deDE=4, frFR=5, esES=6, esMX=6, itIT=7, ptBR=8, ruRU=9, koKR=10}
local titles = {"Release notes","更新日志","更新日誌","Versionshinweise","Notes de version","Notas de versión","Note di versione","Notas da versão","Примечания к версиям","업데이트 내역"}

-- Add one entry per packaged release. Columns follow the locale order above.
-- A tilde separates bullets within each translation.
local releases = {
    {191, "2026/11/13",
        "Single Spell Cards now have separate triggers for regular combat (on by default) and boss encounters (off by default).~Added a switch for collection sounds in the Card Overview. New card notifications still appear when sound is off.~Fixed an error when Retail raids restrict access to AFK status.~Loot cards skip restricted messages and continue to process readable loot and raid messages.~Fixed a collection progress tooltip error when Retail instances restrict unit information.",
        "单张技能卡牌可分别设置普通战斗和首领战斗触发，默认开启普通战斗、关闭首领战斗。~卡牌总览新增收藏音效开关，关闭后仍会显示新卡收藏提示。~修复正式服团本读取受保护挂机状态时的报错。~掉落卡牌跳过受保护的消息，继续处理可读取的拾取和团队消息。~修复正式服副本中单位信息受保护时的收藏进度提示报错。",
        "單張技能卡牌可分別設定一般戰鬥和首領戰鬥觸發，預設開啟一般戰鬥、關閉首領戰鬥。~卡牌總覽新增收藏音效開關，關閉後仍會顯示新卡收藏提示。~修正正式服團隊副本讀取受保護暫離狀態時的錯誤。~掉落卡牌會略過受保護的訊息，繼續處理可讀取的拾取和團隊訊息。~修正正式服副本中單位資訊受保護時的收藏進度提示錯誤。",
        "Einzelne Zauberkarten lassen sich getrennt für normale Kämpfe (standardmäßig an) und Bosskämpfe (aus) einstellen.~Der Sammelton lässt sich in der Kartenübersicht abschalten. Hinweise auf neue Karten bleiben sichtbar.~Fehler bei geschütztem AFK-Status in Retail-Schlachtzügen behoben.~Beutekarten überspringen geschützte Nachrichten und verarbeiten lesbare Beute- und Schlachtzugsnachrichten weiter.~Fehler im Sammlungsfortschritt-Tooltip bei geschützten Einheiten in Retail-Instanzen behoben.",
        "Les cartes de sort individuelles ont des déclencheurs distincts en combat normal (activé par défaut) et contre les boss (désactivé).~Le son de collection est réglable dans l’aperçu. Les notifications de nouvelles cartes restent visibles.~Correction d’une erreur liée au statut d’absence protégé dans les raids de la version moderne.~Les cartes de butin ignorent les messages protégés et traitent les messages de butin et de raid lisibles.~Correction de l’infobulle de progression quand les données d’unité sont protégées dans les instances modernes.",
        "Las cartas de hechizo individuales tienen activadores separados para el combate normal (activo por defecto) y contra jefes (inactivo).~El sonido de colección se puede desactivar en el resumen. Los avisos de cartas nuevas siguen apareciendo.~Se corrigió un error con el estado ausente protegido en bandas de Retail.~Las cartas de botín omiten los mensajes protegidos y procesan los mensajes de botín y banda legibles.~Se corrigió el aviso de progreso cuando los datos de unidad están protegidos en estancias de Retail.",
        "Le carte magia singole hanno attivatori distinti per combattimenti normali (attivi per impostazione predefinita) e boss (disattivati).~Il suono della collezione è disattivabile dalla panoramica. Gli avvisi delle nuove carte restano visibili.~Corretto un errore con lo stato di assenza protetto nelle incursioni di Retail.~Le carte bottino ignorano i messaggi protetti e continuano a elaborare quelli leggibili di bottino e incursione.~Corretta l’informazione sul progresso quando i dati dell’unità sono protetti nelle istanze di Retail.",
        "As cartas de feitiço individuais têm gatilhos separados para combate normal (ativo por padrão) e chefes (inativo).~O som da coleção pode ser desativado na visão geral. Os avisos de novas cartas continuam visíveis.~Corrigido um erro com o estado de ausência protegido em raides de Retail.~As cartas de saque ignoram mensagens protegidas e processam as mensagens legíveis de saque e raide.~Corrigida a dica de progresso quando os dados da unidade são protegidos em instâncias de Retail.",
        "Для отдельных карт заклинаний добавлены отдельные условия для обычного боя (включено по умолчанию) и боя с боссом (выключено).~Звук коллекции можно отключить в обзоре карт. Уведомления о новых картах сохраняются.~Исправлена ошибка с защищённым статусом отсутствия в рейдах Retail.~Карты добычи пропускают защищённые сообщения и обрабатывают доступные сообщения о добыче и рейде.~Исправлена подсказка о прогрессе коллекции при защищённых данных юнита в подземельях Retail.",
        "단일 주문 카드의 일반 전투(기본 켜짐) 및 우두머리 전투(기본 꺼짐) 발동을 따로 설정할 수 있습니다.~카드 목록에서 수집 소리를 끌 수 있으며 새 카드 알림은 계속 표시됩니다.~본 서버 공격대에서 보호된 자리 비움 상태를 읽을 때 발생하는 오류를 수정했습니다.~전리품 카드는 보호된 메시지를 건너뛰고 읽을 수 있는 전리품 및 공격대 메시지를 처리합니다.~본 서버 인스턴스에서 유닛 정보가 보호될 때 수집 진행률 툴팁에 발생하던 오류를 수정했습니다.",
    },
    {187, "2026/11/04",
        "Added 88 boss cards to each series, with Chinese and English boss names and encounter recognition.~Added seven legendary loot cards to each series and the Card Overview.",
        "两套系列各新增 88 张首领卡，支持中英文首领名称和遭遇战识别。~两套系列各新增 7 张橙色掉落卡，并加入卡牌总览。",
        "兩套系列各新增 88 張首領卡，支援中英文首領名稱及遭遇戰辨識。~兩套系列各新增 7 張傳奇掉落卡，並加入卡牌總覽。",
        "Je Serie 88 neue Bosskarten mit chinesischen und englischen Bossnamen sowie Begegnungserkennung.~Je Serie sieben legendäre Beutekarten zur Kartenübersicht hinzugefügt.",
        "Ajout de 88 cartes de boss par série, avec noms chinois et anglais et détection des rencontres.~Ajout de sept cartes de butin légendaire par série dans l’aperçu.",
        "Se añadieron 88 cartas de jefe por serie, con nombres en chino e inglés y detección de encuentros.~Se añadieron siete cartas de botín legendario por serie al resumen.",
        "Aggiunte 88 carte boss per serie, con nomi in cinese e inglese e riconoscimento degli scontri.~Aggiunte sette carte bottino leggendario per serie alla panoramica.",
        "Adicionadas 88 cartas de chefes por série, com nomes em chinês e inglês e detecção de confrontos.~Adicionadas sete cartas de saque lendário por série à visão geral.",
        "В каждую серию добавлено 88 карт боссов с китайскими и английскими именами и распознаванием боёв.~В обзор каждой серии добавлено семь карт легендарной добычи.",
        "시리즈마다 우두머리 카드 88장을 추가하고 중국어 및 영어 이름과 전투 인식을 지원합니다.~시리즈마다 전설 전리품 카드 7장을 추가해 카드 목록에 표시합니다.",
    },
}

function Addon:AttachReleaseNotes(window)
    local button = CreateFrame("Button", nil, window)
    button:SetSize(30, 27)
    button:SetPoint("TOPRIGHT", window, "TOPRIGHT", -23, -32)
    button:SetFrameLevel(window:GetFrameLevel() + 8)
    button:SetNormalTexture("Interface\\Icons\\INV_Scroll_03")
    button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

    local dismiss = CreateFrame("Button", nil, window)
    dismiss:SetAllPoints(UIParent)
    dismiss:SetFrameLevel(window:GetFrameLevel() + 6)
    dismiss:Hide()

    local panel = CreateFrame("Frame", nil, window, "BackdropTemplate")
    panel:SetPoint("TOPRIGHT", button, "BOTTOMRIGHT", 0, -3)
    panel:SetSize(460, 385)
    panel:SetFrameLevel(window:GetFrameLevel() + 7)
    panel:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12,
    })
    panel:SetBackdropColor(.075, .065, .06, .99)
    panel:SetBackdropBorderColor(.65, .49, .29, 1)
    panel:EnableMouse(true)
    panel:Hide()

    local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -38)
    scroll:SetPoint("BOTTOMRIGHT", -32, 12)
    local body = CreateFrame("Frame", nil, scroll)
    body:SetSize(416, 1)
    scroll:SetScrollChild(body)

    local function label(parent, size)
        local font = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        font:SetJustifyH("LEFT")
        font.cmInterfaceNominal = size
        return font
    end

    local title = label(panel, 15)
    title:SetPoint("TOPLEFT", 14, -12)
    title:SetTextColor(1, .82, .28)
    local rows = {}
    local language, fontSize
    local pinned, away = false, 0
    local function populate()
        local index = locales[self:EffectiveLanguage()] or 1
        local size = self:ClientInterfaceFontSize(13)
        if language == index and fontSize == size then return end
        title:SetText(titles[index])
        self:ApplyLocaleFont(title)
        local y = 0
        for i, release in ipairs(releases) do
            local row = rows[i]
            if not row then
                row = {heading = label(body, 13), bullets = {}}
                row.heading:SetTextColor(1, .82, .32)
                rows[i] = row
            end
            row.heading:ClearAllPoints()
            row.heading:SetPoint("TOPLEFT", 2, -y)
            row.heading:SetText(("v%d  %s"):format(release[1], release[2]))
            self:ApplyLocaleFont(row.heading)
            y = y + row.heading:GetStringHeight() + 10
            local count = 0
            for paragraph in release[index + 2]:gmatch("[^~]+") do
                count = count + 1
                local bullet = row.bullets[count]
                if not bullet then
                    bullet = {dot = label(body, 12), text = label(body, 12)}
                    bullet.dot:SetText("•")
                    bullet.text:SetWidth(394)
                    bullet.text:SetWordWrap(true)
                    bullet.text:SetSpacing(3)
                    row.bullets[count] = bullet
                end
                bullet.dot:ClearAllPoints()
                bullet.dot:SetPoint("TOPLEFT", 2, -y)
                bullet.text:ClearAllPoints()
                bullet.text:SetPoint("TOPLEFT", 18, -y)
                bullet.text:SetText(paragraph)
                self:ApplyLocaleFont(bullet.dot)
                self:ApplyLocaleFont(bullet.text)
                bullet.dot:Show()
                bullet.text:Show()
                y = y + bullet.text:GetStringHeight() + 8
            end
            for j = count + 1, #row.bullets do
                row.bullets[j].dot:Hide()
                row.bullets[j].text:Hide()
            end
            y = y + 12
        end
        body:SetHeight(math.max(1, y))
        scroll:SetVerticalScroll(0)
        language, fontSize = index, size
    end

    local function open()
        away = 0
        dismiss:Show()
        panel:Show()
        populate()
    end
    local function close()
        pinned = false
        panel:Hide()
        dismiss:Hide()
    end
    dismiss:SetScript("OnClick", close)
    button:SetScript("OnEnter", open)
    button:SetScript("OnClick", function()
        if pinned then close()
        else pinned = true; open() end
    end)
    panel:SetScript("OnUpdate", function(frame, elapsed)
        populate()
        if pinned or button:IsMouseOver() or frame:IsMouseOver() then
            away = 0
            return
        end
        away = away + elapsed
        if away > .35 then close() end
    end)
    window:HookScript("OnHide", close)
end
