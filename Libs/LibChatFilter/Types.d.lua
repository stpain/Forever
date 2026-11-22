---@meta

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

---@alias ChatEditBox EditBox & ChatFrameEditBoxMixin

---@class LibChatFilter.Context
---@field originalText string Starting text from the chatframe edit box
---@field message string Current message to be sent
---@field historyText string Current message to be pushed to chat history
---@field chatType string ChatType
---@field target string ChatTarget (player name or channel ID)
---@field language string Selected chat language (furbolg, dragon)
---@field editBox ChatEditBox The active chatframe edit box

---Mutator function type expected by the functions below
---@alias LibChatFilter.MutatorFunc fun(text: string, context: LibChatFilter.Context): string

---Example mutator func
---@param text string
---@param context LibChatFilter.Context
---@return string
local function transform(text, context)
    return text:gsub("Meorawr", "Meowaww");
end

---@class LibChatFilter.Mutator
---@field func LibChatFilter.MutatorFunc Message mutation function, returns the altered message
---@field stage LibChatFilter.Stage Mutator pipeline stage
---@field track LibChatFilter.Track Mutator target message track

---@class LibChatFilter
local LibChatFilter = {};

---Registers a mutator
---@param mutator LibChatFilter.MutatorFunc Message mutation function
---@param stage? LibChatFilter.Stage Defaults to TRANSFORM
---@param track? LibChatFilter.Track Defaults to SEND
---@return boolean success Only false if trying to register an exclusive hook when one is already set
---@return string? error Error message if registration failed
function LibChatFilter.RegisterMutator(mutator, stage, track) end

---Registers a mutator as a message transformer
---@param transform LibChatFilter.MutatorFunc Message mutation function
---@param track? LibChatFilter.Track Defaults to SEND
---@return boolean success Only false if trying to register an exclusive hook when one is already set
---@return string? error Error message if registration failed
function LibChatFilter.RegisterTransform(transform, track) end

---Registers a mutator as a message finalizer
---@param mutator LibChatFilter.MutatorFunc Message mutation function
---@param track? LibChatFilter.Track Defaults to SEND
---@return boolean success Only false if trying to register an exclusive hook when one is already set
---@return string? error Error message if registration failed
function LibChatFilter.RegisterFinalizer(mutator, track) end