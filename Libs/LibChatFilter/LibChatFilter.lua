--@curseforge-project-slug: libchatfilter@
local major, minor = "LibChatFilter", 1;
---@class LibChatFilter
local LibChatFilter = LibStub:NewLibrary(major, minor);

if not LibChatFilter then
    return;
end

------------
--- Context

---@alias ChatEditBox EditBox & ChatFrameEditBoxMixin

---@class LibChatFilter.Context
---@field originalText string Starting text from the chatframe edit box
---@field message string Current message to be sent
---@field historyText string Current message to be pushed to chat history
---@field chatType string ChatType
---@field target string ChatTarget (player name or channel ID)
---@field language string Selected chat language (furbolg, dragon)
---@field editBox ChatEditBox The active chatframe edit box

local CURRENT_CONTEXT;

local function CreateContext(message, chatType, target, language, editBox)
    ---@type LibChatFilter.Context
    local context = {
        originalText = message,
        message = message,
        historyText = message,
        chatType = chatType,
        target = target,
        language = language,
        editBox = editBox,
    };
    CURRENT_CONTEXT = context;
    return context;
end

local function CallMutator(func, message, context)
    local result = securecallfunction(func, message, context);
    return result;
end

local function ApplyToContext(mutator, context)
    local track = mutator.track;
    if FlagsUtil.IsSet(track, LibChatFilter.Track.SEND) then
        context.message = CallMutator(mutator.func, context.message, context) or context.message;
    end
    if FlagsUtil.IsSet(track, LibChatFilter.Track.HISTORY) then
        context.historyText = CallMutator(mutator.func, context.historyText, context) or context.historyText;
    end
end

------------
--- Event Handling

local function ApplyMutators()
    local mutators = LibChatFilter.mutators;
    local sorted = {
        mutators[LibChatFilter.Stage.TRANSFORM],
        mutators[LibChatFilter.Stage.EXCLUSIVE_TRANSFORM],
        mutators[LibChatFilter.Stage.FINALIZE],
        mutators[LibChatFilter.Stage.EXCLUSIVE_FINALIZE]
    };

    for _, mutatorList in ipairs(sorted) do
        for _, mutator in ipairs(mutatorList) do
            ApplyToContext(mutator, CURRENT_CONTEXT);
        end
    end
    return false;
end

---@param editBox ChatEditBox
local function OnPreSendText(_, editBox)
    if C_ChatInfo.InChatMessagingLockdown() then
        return;
    end

    local message = editBox:GetText();
    if not message or message == "" then
        return;
    end

    local chatType = ChatFrameUtil.GetActiveChatType();
    chatType = chatType and chatType:upper() or "SAY";

    local target = editBox:GetTellTarget() or editBox:GetChannelTarget();
    if target == 0 then
        target = nil;
    end

    local language = editBox.languageID;

    local context = CreateContext(
        message,
        chatType,
        target,
        language,
        editBox
    );

    ApplyMutators();

    editBox:SetText(context.message);
end

local function OnSubstituteBeforeSend()
    if not CURRENT_CONTEXT then
        return;
    end

    local context = CURRENT_CONTEXT;
    CURRENT_CONTEXT = nil;

    context.editBox:SetText(context.historyText);
end

EventRegistry:RegisterCallback("ChatFrame.OnEditBoxPreSendText", OnPreSendText);
hooksecurefunc(ChatFrameUtil, "SubstituteChatMessageBeforeSend", OnSubstituteBeforeSend);

------------
--- API

---@enum LibChatFilter.Track
LibChatFilter.Track = {
    SEND = 0x01,
    HISTORY = 0x02,
};

---@enum LibChatFilter.Stage
LibChatFilter.Stage = {
    TRANSFORM = 1,  -- token resolve, emoji expansion, owospeak
    EXCLUSIVE_TRANSFORM = 2, -- very last transform to run, only one of these is allowed
    FINALIZE  = 3,  -- chunking, chattery'ing
    EXCLUSIVE_FINALIZE = 4, -- very last finalizer to run, only one of these is allowed
};
local stageInvert = tInvert(LibChatFilter.Stage);

---Mutator function type expected by the functions below
---@alias LibChatFilter.MutatorFunc fun(text: string, context: LibChatFilter.Context): string

---@class LibChatFilter.Mutator
---@field func LibChatFilter.MutatorFunc Message mutation function, returns the altered message
---@field stage LibChatFilter.Stage Mutator pipeline stage
---@field track LibChatFilter.Track Mutator target message track

---@type table<LibChatFilter.Stage, LibChatFilter.Mutator[]>
LibChatFilter.mutators = {};
for _, stage in pairs(LibChatFilter.Stage) do
    LibChatFilter.mutators[stage] = {};
end

local function HasExclusive(stage)
    return #LibChatFilter.mutators[stage] > 0;
end

---Registers a mutator
---@param mutator LibChatFilter.MutatorFunc Message mutation function
---@param stage? LibChatFilter.Stage Defaults to TRANSFORM
---@param track? LibChatFilter.Track Defaults to SEND
---@return boolean success Only false if trying to register an exclusive hook when one is already set
---@return string? error Error message if registration failed
function LibChatFilter.RegisterMutator(mutator, stage, track)
    assert(type(mutator) == "function", "Mutator must be a function");

    stage = stage or LibChatFilter.Stage.TRANSFORM;

    for _, exclusive in ipairs({LibChatFilter.Stage.EXCLUSIVE_TRANSFORM, LibChatFilter.Stage.EXCLUSIVE_FINALIZE}) do
        if stage == exclusive and HasExclusive(exclusive) then
            local _, firstAddon = issecurevalue(LibChatFilter.mutators[exclusive][1].func);
            local fmt = "Only one filter can be set for stage '%s' (currently set by %s)";
            return false, format(fmt, stageInvert[exclusive], firstAddon);
        end
    end

    local mutatorObj = {
        func = mutator,
        stage = stage,
        track = track or LibChatFilter.Track.SEND,
    };
    tinsert(LibChatFilter.mutators[stage], mutatorObj);
    return true;
end

---Registers a mutator as a message transformer
---@param transform LibChatFilter.MutatorFunc Message mutation function
---@param track? LibChatFilter.Track Defaults to SEND
---@return boolean success Only false if trying to register an exclusive hook when one is already set
---@return string? error Error message if registration failed
function LibChatFilter.RegisterTransform(transform, track)
    track = track or LibChatFilter.Track.SEND;
    return LibChatFilter.RegisterMutator(transform, LibChatFilter.Stage.TRANSFORM, track);
end

---Registers a mutator as a message finalizer
---@param mutator LibChatFilter.MutatorFunc Message mutation function
---@param track? LibChatFilter.Track Defaults to SEND
---@return boolean success Only false if trying to register an exclusive hook when one is already set
---@return string? error Error message if registration failed
function LibChatFilter.RegisterFinalizer(mutator, track)
    track = track or LibChatFilter.Track.SEND;
    return LibChatFilter.RegisterMutator(mutator, LibChatFilter.Stage.FINALIZE, track);
end