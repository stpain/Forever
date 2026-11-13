

local addonName, addon = ...;


local locales = {}

locales.enUS = {

    --whats new table list - the addon will format this as a list of lines
    whatsNew = {
        "Added tooltips to the profession reagents.",
        "Profession crafted item tooltip now persists when closing.",
        "Added a QoL Send Mail button, this will open a list of your characters names.",
        "Fixed a bug with Enchanting recipes not loading.",
        "Added a description for Enchanting recipes.",
        "Added a disenchant interface to the enchanting profession recipe list.",
        "Fixed a bug with interactions and secret values.",
        "Added a min level filter to character summary (slider bar)."
    },
    
    --config display text and _TT (tooltip text)
    autoVendorJunk = "Auto vendor junk.",
    autoVendorJunk_TT = "Enabling this will skip the 'Sell Junk' button and dialog and immediately vendor your junk when you open the merchant window.",

    disableInboxGold = "Confirm taking inbox mail gold.",
    disableInboxGold_TT = "Adds a confirmation dialog box when trying to take gold from the mail inbox.",

    displayRestedFlipbook = "Show character resting animations.",
    displayRestedFlipbook_TT = "Shows the Zz animation on the character summary list if the character is currently in a rested area.",

    useServerTimeForJournal = "Use server time for journal events.",
    useServerTimeForJournal_TT = "Setting this will cause the journal to use the game server time (as shown in the minimap clock) to track when events happen.",

    addSendMailCharacterListButton = "Enable the send mail character list button.",
    addSendMailCharacterListButton_TT = "This setting will add a button next to the Send Mail recipient edit box which will open a menu listing your characters names. Clicking a name will set it as the mail recipient.",

    enableDisenchantingRecipeButton = "Enable the disenchanting interface.",
    enableDisenchantingRecipeButton_TT = "This adds a Disenchanting category to your profession UI (if you have enchanting). Select the category recipe to see items which can be disenchanted.",



    --dialogs
    confirmTakeInboxGoldDialogText_S = "Are you sure you want to take this gold?\n\nDo you trust the sender: %s.",
    interactionsNewInteractionDialogText_S = "Add a new note for %s",

    --journal activity entries, the event name is added as a suffix and used to create the display text
    journalActivity_TAXI_FLIGHT = "Took a taxi flight to: %s",
    journalActivity_QUEST_ACCEPTED = "Accepted quest: %s",
    journalActivity_QUEST_TURNED_IN = "Turned in quest: %s\nReceived %d XP and %s.",
    journalActivity_ZONE_CHANGED_NEW_AREA = "Travelled to: %s",
    journalActivity_PLAYER_LEVEL_UP = "Reached level %s!", --technically a number value but its saved as part of a string and there is little gain in using tonumber when it'll work fine as a string value

    --interactions
    interactionEnumRelationshipLevel_1 = "Ignore",
    interactionEnumRelationshipLevel_2 = "Unfriendy",
    interactionEnumRelationshipLevel_3 = "Neutral",
    interactionEnumRelationshipLevel_4 = "Friendly",
    interactionEnumRelationshipLevel_5 = "Good",
    interactionEnumRelationshipLevel_6 = "Epic",
}





local locale = GetLocale();
addon.locales = locales.enUS;
--addon.locales = locales[locale];