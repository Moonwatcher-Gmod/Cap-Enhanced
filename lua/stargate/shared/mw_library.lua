-- Addon library for shared functionality

if SERVER then

    function GetCurrentFileName()
        local info = debug.getinfo(2, "S")
        if info and info.source then
            -- 'info.source' usually contains the file path in the format '@<file_path>'
            -- We can extract the file name by removing the leading '@'
            return info.source:sub(2)
        end
        return nil
    end






    util.AddNetworkString("MWToServer:")
    util.AddNetworkString("MWToClient:")


    net.Receive("MWToServer:", function(len, ply)
        local originEntity = net.ReadEntity()
        local receiverEntityID = net.ReadEntity()
        local subject = net.ReadString()
        local numMessages = net.ReadUInt(2) --3 messages

        local data = {}

        for i = 1, numMessages do
            local messageType = net.ReadString()
            if messageType == "string" then
                data[i] = net.ReadString()
            elseif messageType == "int" then
                data[i] = net.ReadInt(32)
            elseif messageType == "Entity" then
                data[i] = net.ReadEntity()
            elseif messageType == "table" then
                data[i] = net.ReadTable()
            elseif messageType == "boolean" then
                data[i] = net.ReadBool()
            elseif messageType == "Vector" then
                data[i] = net.ReadVector() 
            else
                print("Unhandled message type server:", messageType)
                return
            end
        end

        if IsValid(receiverEntityID) and receiverEntityID.HandleMessageFromClient then
            receiverEntityID:HandleMessageFromClient(ply, originEntity, receiverEntityID, subject, unpack(data))
        else
            print("Invalid or not found server-side receiver entity with ID:", receiverEntityID)
        end
    end)

    -- This method below should be placed serverside on entities --------------------------------
    --function HandleMessageFromClient(ply, originEntity, receiverEntityID, subject, ...)
    --    if subject == "test2" then
    --        print("Received a message:", ...)
    --    else
    --        print("Unhandled subject:", subject)
    --    end
    --end
    ---------------------------------------------------------------------------------------------
    -- Function to send a message from the serverside to the client-side entity
    function SendMessageToClient(receiverPlayer, originEntity, subject, ...)
        local data = {...}
        local numMessages = #data

        net.Start("MWToClient:")
            net.WriteEntity(originEntity)
            net.WriteString(subject)
            net.WriteUInt(numMessages, 2) -- Assuming you won't have more than 3 messages

            for _, messageData in ipairs(data) do
                local messageType = type(messageData)
                net.WriteString(messageType)

                -- Write the data based on its type
                if messageType == "string" then
                    net.WriteString(messageData)
                elseif messageType == "int" then
                    net.WriteInt(messageData, 32)
                elseif messageType == "Entity" then
                    net.WriteEntity(messageData)
                elseif messageType == "table" then
                    net.WriteTable(messageData)
                elseif messageType == "boolean" then
                    net.WriteBool(messageData) 
                elseif messageType == "Vector" then
                    net.WriteVector(messageData)                   
                else
                    print("Unhandled message type:", messageType)
                    return
                end
            end
        net.Send(receiverPlayer)
    end
end

if CLIENT then
    net.Receive("MWToClient:", function(len)
        local senderEntity = net.ReadEntity()
        local subject = net.ReadString()
        local data = {}
        local numMessages = net.ReadUInt(2)

        for i = 1, numMessages do
            local messageType = net.ReadString()
            if messageType == "string" then
                data[i] = net.ReadString()
            elseif messageType == "int" then
                data[i] = net.ReadInt()
            elseif messageType == "Entity" then
                data[i] = net.ReadEntity()
            elseif messageType == "table" then
                data[i] = net.ReadTable()
            elseif messageType == "boolean" then
                data[i] = net.ReadBool()
            elseif messageType == "Vector" then
                data[i] = net.ReadVector()                              
            else
                print("Unhandled message type:", messageType)
                return
            end
        end

        if senderEntity and senderEntity.HandleMessageFromServer then
            senderEntity:HandleMessageFromServer(senderEntity, subject, unpack(data))
        else
            print("Invalid or unsupported sender entity:", senderEntity)
        end
    end)
    ------- This method below should be placed clientside on entities --------------------------------
    --function HandleMessageFromServer(originEntity, subject, ...)
    --    print("Received message from server-side entity:", originEntity, subject, ...)
    --end
    ---------------------------------------------------------------------------------------------
    function SendMessageToServer(originEntity, receiverEntity, subject, ...)
        local data = {...}
        local numMessages = #data

        net.Start("MWToServer:")
            net.WriteEntity(originEntity)
            net.WriteEntity(receiverEntity)
            net.WriteString(subject)
            net.WriteUInt(numMessages, 2) -- Assuming you won't have more than 3 messages

            for _, messageData in ipairs(data) do
                local messageType = type(messageData)
                net.WriteString(messageType)

                -- Write the data based on its type
                if messageType == "string" then
                    net.WriteString(messageData)
                elseif messageType == "int" then
                    net.WriteInt(messageData, 32)
                elseif messageType == "Entity" then
                    net.WriteEntity(messageData)
                elseif messageType == "table" then
                    net.WriteTable(messageData)
                elseif messageType == "boolean" then
                    net.WriteBool(messageData)                     
                elseif messageType == "Vector" then
                    net.WriteVector(messageData)                
                else
                    print("Unhandled message type:", messageType)
                    return
                end
            end

        net.SendToServer()
    end
end
