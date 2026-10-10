# Ranktags Plugin
An Adonis Plugin adding Kronos-Style Ranktags

## Setup
1. Get the Plugin from [Github Releases](https://github.com/Alex-Tech-Incorporated/Ranktags-Plugin/releases)
2. Add the Plugin to `Adonis_Loader` > `Config` > `Plugins`
3. Add Groups to the `Groups` Table within the ModuleScript

### Adding Groups
```lua
{
	Name = "Alex Tech Incorporated"; -- The Groups Name
	ArgName = "AT"; -- Used for :setgroup command, so doing :setgroup AT will set the displayed Group to this Group
	ID = 11404924; -- The Group's ID
	TextColor3 = Color3.new(1, 1, 1); -- The Ranktag's Text Color
	MinRank = 1; -- The minimum required Rank for the Player to be able to display the Group
	IconURI = "rbxassetid://78710756217426"; -- The Group's Icon displayed on the Ranktag (Setting this to nil will use the Group's Icon)
	HideIcon = false; -- If true, the Group's Icon will be hidden from the Ranktag
},
```

## Commands
<details>
<summary>`:setgroup`</summary>

### Description
Changes a Player's displayed Group on the Ranktag

### Usage
`:setgroup AT`

</details>

<details>
<summary>`:setgroup`</summary>

### Description
Changes a Player's displayed Group on the Ranktag

### Usage
`:setgroup AT` | In this case, "AT" is the Group's ArgName

</details>

<details>
<summary>`:HideRanktagGroups`</summary>

### Aliases
`:HideRanktagGroups`, `:HideRanktagData`

### Description
Disables or Enables a Moderator's Group Rank and Groups to be displayed.

### Usage
`:HideRanktagGroups true` | This will hide a Moderator's displayed Groups

</details>

<details>
<summary>`:refreshranktag`</summary>

### Description
Forcefully refreshes a Player's Ranktag

### Usage
`:refreshranktag Player1`

</details>