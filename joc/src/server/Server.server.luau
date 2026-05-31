-- Server (Script al servidor)
-- TODO: envia'ns el contingut original d'aquest script si en tens
local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	print(player.Name .. " ha entrat al joc")
end)

Players.PlayerRemoving:Connect(function(player)
	print(player.Name .. " ha sortit del joc")
end) 
