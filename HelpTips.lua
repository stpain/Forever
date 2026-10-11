

local addonName, addon = ...;


addon.helptipData = {

    --[1] = character summary view
    [1] = {
        {
            text = "Your characters are shown in the list here.",
            buttonStyle = HelpTip.ButtonStyle.Next,
            targetPoint = HelpTip.Point.TopEdgeCenter,
        },
        {
            text = "You can filter the list by class or profession.",
            buttonStyle = HelpTip.ButtonStyle.Next,
            targetPoint = HelpTip.Point.LeftEdgeCenter,
        },
        {
            text = "Character professions will show here. Your profession skill level will be shown as a status bar.",
            buttonStyle = HelpTip.ButtonStyle.Next,
            targetPoint = HelpTip.Point.TopEdgeCenter,
            offsetX = 120,
            offsetY = -5
        },
        {
            text = "This section shows where your character is, how much gold they have and when that character was last logged in.",
            buttonStyle = HelpTip.ButtonStyle.Okay,
            targetPoint = HelpTip.Point.TopEdgeCenter,
            offsetX = -130,
            offsetY = -15
        },
    },

    [2] = {
        {
            text = "Select a profession to view your characters recipes.",
            buttonStyle = HelpTip.ButtonStyle.Next,
            targetPoint = HelpTip.Point.TopEdgeCenter,
        },
        {
            text = "You can also search for recipes.",
            buttonStyle = HelpTip.ButtonStyle.Next,
            targetPoint = HelpTip.Point.RightEdgeCenter,
        },
        {
            text = "Your characters with matching professions or recipes will be listed here. Select a recipe to view its schematic.",
            buttonStyle = HelpTip.ButtonStyle.Next,
            targetPoint = HelpTip.Point.LeftEdgeCenter,
        },
        {
            text = "Recipe schematic information will show here.",
            buttonStyle = HelpTip.ButtonStyle.Okay,
            targetPoint = HelpTip.Point.TopEdgeCenter,
        },
    },

    [3] = {
        {
            text = "Characters who whisper you will show here",
            buttonStyle = HelpTip.ButtonStyle.Next,
            targetPoint = HelpTip.Point.TopEdgeCenter,
        },
        {
            text = "The whisper history between you and the other character will show here. If you whispered them from different characters (alts), the alt name will show above the message.",
            buttonStyle = HelpTip.ButtonStyle.Next,
            targetPoint = HelpTip.Point.TopEdgeCenter,
        },
        {
            text = "You can write your whisper message here. It'll be sent to the character currently showing in the chat history.",
            buttonStyle = HelpTip.ButtonStyle.Okay,
            targetPoint = HelpTip.Point.RightEdgeCenter,
        }
    }
}