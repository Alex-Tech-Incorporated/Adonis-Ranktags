--// locals
--// Services
local _workspace = game:GetService("Workspace")
local GroupService = game:GetService("GroupService")

--// Objects
local Ranktag_Object = script:WaitForChild("Ranktag")
local Icon_Base = script:WaitForChild("Icon")
local Container

--// Ranktag Components
--// Groups
local Groups = {
	{
		Name = "Alex Tech Incorporated";
		ArgName = "AT";
		ID = 11404924;
		TextColor3 = Color3.new(1, 1, 1);
		MinRank = 1;
		IconURI = "rbxassetid://78710756217426";
		HideIcon = false;
	},
	{
		Name = "Alex Tech Internal Affairs Department";
		ArgName = "ATIAD";
		ID = 35236008;
		TextColor3 = Color3.new(1, 1, 1);
		MinRank = 1;
		IconURI = "rbxassetid://108636420053511";
		HideIcon = false;
	},
	{
		Name = "Alex Tech Security Division";
		ArgName = "ATSD";
		ID = 34124059;
		TextColor3 = Color3.new(1, 1, 1),
		MinRank = 3;
		IconURI = "rbxassetid://121083515448077";
		HideIcon = false;
	},
}

--// Typecheck
type RanktagGroup = {
	Name: string,
	ArgName: string,
	ID: number,
	TextColor3: Color3?,
	MinRank: number?,
	IconURI: string?,
	HideIcon: boolean?
}
type RoleInfo = {
	IsMember: boolean,
	Roles: any?
}

--// Plugin
return function(Vargs)
	local server, service = Vargs.Server, Vargs.Service
	
	--// Adonis Services
	local Settings = server.Settings
	local Commands = server.Commands
	local Variables = server.Variables
	local Functions = server.Functions
	
	--// Ranktag Data
	local sessionData: {[Player]: {
		Enabled: boolean, 
		Groups: {RanktagGroup}, 
		CurrentGroup: RanktagGroup?, 
		CurrentGroupRole: string?
	}} = {}
	
	--// Set up
	Variables.RanktagGroups = Groups
	Container = service.New("Folder", {
		Parent = _workspace,
		Name = "Ranktag_Container",
		Archivable = false,
	})
	
	-- Internal functions --
	
	--// Gets a Player's highest Rank within a Group
	local function GetHighestRole(Plr : Player, groupID : number): (string, number)
		--// locals
		local RoleInfo = GroupService:GetRolesInGroupAsync(Plr.User, groupID) :: RoleInfo
		
		--// Vars
		local IsMember = RoleInfo.IsMember
		local Roles = RoleInfo.Roles
		if not IsMember then return "Guest", 0 end
		
		--// Fetch Ranks
		local Ranks = {}
		for _, Role in ipairs(Roles) do
			Ranks[Role.Rank] = {Name = Role.Name, Rank = Role.Rank}
		end
		
		--// Fetch Highest Rank
		local HighestRank = table.maxn(Ranks)
		local RoleName = Ranks[HighestRank].Name
		local Rank = Ranks[HighestRank].Rank
		
		--// Export
		return RoleName, Rank
	end
	
	--// Attempts to fetch a Group's Icon
	local function FetchIcon(groupID : number): string
		local success, result = pcall(function()
			return GroupService:GetGroupInfoAsync(groupID)
		end)
		
		if not success then return "rbxassetid://0" end
		return result.EmblemUrl
	end
	
	--// Refreshes the Ranktag and the displayed Rank
	local function Refresh(Plr : Player)
		--// locals
		local Data = sessionData[Plr]
		if not Data then
			Data = {Enabled = true, Groups = {}}
		end
		
		--// Reset CurrentGroup Data
		if Data.CurrentGroup and GetHighestRole(Plr, Data.CurrentGroup) ~= "Guest" then
			Data.CurrentGroup = nil
			Data.CurrentGroupRole = nil
		end
		
		--// Clear Groups
		table.clear(Data.Groups)
		
		--// Get Group Role
		for _, Group in ipairs(Variables.RanktagGroups) do
			local HighestRank, Rank = GetHighestRole(Plr, Group.ID)
			if HighestRank ~= "Guest" then
				--// Add to Session Data
				table.insert(Data.Groups, Group)
				
				--// Add CurrentGroup
				if not Data.CurrentGroup then
					Data.CurrentGroup = Group
					Data.CurrentGroupRole = HighestRank or "Unknown"
				end
			end
		end
		
		--// Set Session Data
		sessionData[Plr] = Data
	end
	
	--// Refreshes the Ranktag Object
	local function RefreshObject(Plr : Player)
		--// locals
		local Data = sessionData[Plr]
		local Ranktag = Container:FindFirstChild(Plr.Name) :: BillboardGui

		--// Check if Ranktag exists
		if not Ranktag then
			--// Generate
			Ranktag = Ranktag_Object:Clone()
			Ranktag.Name = Plr.Name
			Ranktag.Parent = Container
		end

		--// Check for Session Data
		if Data then
			--// locals
			local TagColor = Color3.fromRGB(255, 255, 255)
			if Plr.Team then
				TagColor = Plr.TeamColor.Color
			end

			--// Set Enabled State
			Ranktag.Enabled = Data.Enabled

			--// Set DisplayName
			local TagName = Ranktag:FindFirstChild("PlayerName")
			if TagName then TagName.Text = string.format(`%s (@%s)`, Plr.DisplayName, Plr.Name) end

			--// Get Group Icons for Ranktag
			if #Data.Groups > 0 and Data.CurrentGroup then
				--// Configure Ranktag
				Ranktag.Group.Text = Data.CurrentGroup.Name
				Ranktag.Rank.Text = Data.CurrentGroupRole
				Ranktag.Group.TextColor3 = TagColor
				Ranktag.Rank.TextColor3  = TagColor
			else
				Ranktag.Group.Text = ""
				Ranktag.Rank.Text  = ""
			end

			--// Get Groups
			for _, Group in ipairs(Data.Groups) do
				if not (Group.HideIcon or Ranktag.IconList:FindFirstChild(Group.ArgName)) then
					local Icon = Icon_Base:Clone()
					Icon.Name = Group.ArgName
					Icon.Image = if not Group.IconURI then FetchIcon(Group.ID) else Group.IconURI
					Icon.Parent = Ranktag.IconList
				end
			end

			--// Set Ardonee
			if Plr.Character then task.spawn(function() Ranktag.Adornee = Plr.Character:WaitForChild("Head", 20) end) end
		end
	end
	
	
	
	-- Connections --
	service.Events.CharacterAdded:Connect(RefreshObject)
	service.Events.PlayerAdded:Connect(function(Plr : Player)
		--// Refresh Ranktag and Display
		Refresh(Plr)
		RefreshObject(Plr)
		
		--// Team Change Connection
		Plr:GetPropertyChangedSignal("Team"):Connect(function()
			RefreshObject(Plr)
		end)
	end)
	
	

	-- Commands --
	
	--// SetGroup Command Registration
	Commands.SetGroup = {
		Prefix = Settings.Prefix;
		Commands = {"setgroup"};
		Args = {
			(function()
				--// locals
				local shortNames = {}
				for i, Groups in ipairs(Groups) do
					shortNames[i] = Groups.ArgName:lower()
				end
				return table.concat(shortNames, "/") -- Export
			end)()
		};
		Description = "Sets your displayed group on your Ranktag";	-- Command Description
		Category = "Players";	-- Category to group the command under in the command list
		Hidden = false; -- Is it hidden from the command list?
		Fun = false;	-- Is it fun?
		AdminLevel = "Players";	    -- Admin level; If using settings.CustomRanks set this to the custom rank name (eg. "Baristas")
		Function = function(Plr : Player, args : {string})    -- Function to run for command
			assert(args[1], `Group not specified`)
			
			--// Get Groups
			for _, Group in ipairs(Groups) do
				if args[1]:lower() ~= Group.ArgName:lower() then continue end
				
				--// locals
				local Data = sessionData[Plr]
				local HighestRank, Rank = GetHighestRole(Plr, Group.ID)
				
				--// Check if Player is a Member of the Group
				if Rank < Group.MinRank then
					if table.find(Data, Group) then
						Refresh(Plr)
						RefreshObject(Plr)
					end
					-- error(`You are not a Member of {Group.Name}`)
					-- assert(args[1], `You are not a member of {Group.Name}, or do not meet the minimum rank.`)
					Functions.Hint(
						`You are not a member of {Group.Name}, or do not meet the minimum rank.`,
						{Plr}
					)
					return
				end
				
				--// Check if Group is already displayed
				if Data.CurrentGroup == Group then
					Functions.Hint(
						string.format(`Your displayed Group is already set to %s`, Group.Name),
						{Plr}
					)
					return
				end
				
				--// Set Data
				sessionData[Plr].CurrentGroup = Group
				sessionData[Plr].CurrentGroupRole = HighestRank
				if not table.find(Data.Groups, Group) then
					Refresh(Plr)
				end
				RefreshObject(Plr)
				
				--// Hint
				Functions.Hint(
					string.format(`Your displayed group is now set to %s`, Group.Name),
					{Plr}
				)
				return
			end
			-- error(string.format(`"%s" is not a valid Group.`, args[1]))
			-- assert(args[1], `"{args[1]}" is not a valid Group.`)
			Functions.Hint(
				`"{args[1]}" is not a valid Group.`,
				{Plr}
			)
		end
	}
	
	Commands.HideRanktagGroups = {
		Prefix = Settings.Prefix;
		Commands = {"HideRanktagGroups", "HideRanktagData"};
		Args = {"Hide? (default: true)"};
		Description = "Hides or shows your Ranktags Group Data";
		AdminLevel = "Moderators";
		Function = function(Plr : Player, args : {string})
			--// locals
			local Ranktag = Container:FindFirstChild(Plr.Name) :: BillboardGui
			
			--// Check if Ranktag exists
			if Ranktag then
				--// locals
				local Icons = Ranktag:FindFirstChild("IconList") :: TextLabel
				local Group = Ranktag:FindFirstChild("Group")
				local Rank = Ranktag:FindFirstChild("Rank")

				local ArgState = if not args[1] or (args[1]:lower() == "true" or args[1]:lower() == "yes") then 1 else nil
				local FinalState = if ArgState then false else true

				--// Set States
				Icons.Visible = FinalState
				Group.Visible = FinalState
				Rank.Visible = FinalState
				Functions.Hint(`Set group visibility to {FinalState}.`, {Plr})

			else
				Functions.Hint("Failed to locate Ranktag within Container.", {Plr}, 3)
			end
		end,
	}
	
	Commands.RefreshRanktag = {
		Prefix = Settings.Prefix;
		Commands = {"refreshranktag"};
		Args = {"player"};
		Description = "Forcefully refreshes a Player's Ranktag and Data";
		AdminLevel = "HeadAdmins";
		Function = function(Plr: Player, args: {string})
			assert(args[1], `Missing target player(s) (argument #1)`)
			
			--// Get Target
			for _, TargettedPlr in ipairs(service.GetPlayers(Plr, args[1])) do
				Refresh(TargettedPlr)
				RefreshObject(TargettedPlr)
			end
		end,
	}
end
