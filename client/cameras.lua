local SetCamCoord                  = SetCamCoord
local SetCamRot                    = SetCamRot
local IsControlPressed             = IsControlPressed
local GetCamRot                    = GetCamRot
local GetCamFov                    = GetCamFov
local SetCamFov                    = SetCamFov
local IsControlJustPressed         = IsControlJustPressed
local DoScreenFadeOut              = DoScreenFadeOut
local IsScreenFadedOut             = IsScreenFadedOut
local Wait                         = Wait
local DoScreenFadeIn               = DoScreenFadeIn
local ClearTimecycleModifier       = ClearTimecycleModifier
local ResetScenarioTypesEnabled    = ResetScenarioTypesEnabled
local RenderScriptCams             = RenderScriptCams
local SetCamActive                 = SetCamActive
local CreateCamWithParams          = CreateCamWithParams
local SetTimecycleModifier         = SetTimecycleModifier
local SetTimecycleModifierStrength = SetTimecycleModifierStrength
local FreezeEntityPosition         = FreezeEntityPosition



local camPos
local camRot
local currentCamera = 1
local camera
local viewingCam
local currentRotCam = 0

local function updateCamInstruction(count)
    local camCount = ("%s / %s"):format(count, #Config.PoliceStation.cameras.views)

    lib.showTextUI(locale("camera_instructions"):format(camCount), {
        position = 'right-center',
        style = {
            borderRadius = 5,
            backgroundColor = '#212529',
            color = '#F8F9FA',
        },
    })
end


local function switchCamera(nextCamera)
    currentRotCam = 0
    if nextCamera > #Config.PoliceStation.cameras.views then
        nextCamera = 1
    elseif nextCamera < 1 then
        nextCamera = #Config.PoliceStation.cameras.views
    end

    SetCamCoord(camera, Config.PoliceStation.cameras.views[nextCamera].pos)
    SetCamRot(camera, Config.PoliceStation.cameras.views[nextCamera].rot)

    return nextCamera
end

local function startLoop()
    while viewingCam do
        FreezeEntityPosition(cache.ped, true)
        if IsControlPressed(0, 9) or IsControlPressed(0, 34) then
            local expression = (IsControlPressed(0, 9) and currentRotCam < 40) or
                (not IsControlPressed(0, 9) and currentRotCam > -40)

            if expression then
                currentRotCam = currentRotCam + (IsControlPressed(0, 9) and 1 or -1)
                local currentRot = GetCamRot(camera)
                local newRot = currentRot + vector3(0, 0, (IsControlPressed(0, 9) and -0.5) or 0.5)
                SetCamRot(camera, newRot)
            end
        end

        if IsControlPressed(0, 14) or IsControlPressed(0, 15) then
            local currentFov = GetCamFov(camera)
            local newFov = currentFov + (IsControlPressed(0, 14) and 1 or -1)
            SetCamFov(camera, newFov)
        end

        if IsControlJustPressed(0, 38) or IsControlJustPressed(0, 44) then
            currentCamera = switchCamera(currentCamera + (IsControlJustPressed(0, 38) and 1 or -1))
            updateCamInstruction(currentCamera)
        end

        if IsControlJustPressed(0, 177) then
            DoScreenFadeOut(800)
            while not IsScreenFadedOut() do Wait(0) end
            DoScreenFadeIn(800)

            ClearTimecycleModifier()
            ResetScenarioTypesEnabled()
            RenderScriptCams(false, false, 1, false, false)
            SetCamActive(camera, false)
            currentCamera = 1
            viewingCam = false
            lib.hideTextUI()
        end
        Wait(1)
    end
    FreezeEntityPosition(cache.ped, false)
end

local function viewCamera()
    DoScreenFadeOut(800)
    while not IsScreenFadedOut() do Wait(0) end
    DoScreenFadeIn(800)

    RenderScriptCams(false, false, 1, false, false)

    camPos = Config.PoliceStation.cameras.views[currentCamera].pos
    camRot = Config.PoliceStation.cameras.views[currentCamera].rot

    camera = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", camPos, camRot, 100.0, true, 2)
    RenderScriptCams(true, true, 1, true, true)
    SetCamActive(camera, true)

    SetTimecycleModifier("scanline_cam_cheap")
    SetTimecycleModifierStrength(2.0)

    local playerPed = cache.ped
    updateCamInstruction(currentCamera)
    viewingCam = true
    startLoop()
end

exports.ox_target:addBoxZone({
    coords = Config.PoliceStation.cameras.pos,
    size = vector3(2.0, 2.0, 2.0),
    drawSprite = true,
    groups = Config.PoliceJobName,
    options = {
        {
            name = "view_cameras",
            icon = 'fa-solid fa-road',
            label = locale("view_cameras_label"),
            groups = Config.PoliceJobName,
            onSelect = function(data)
                viewCamera()
            end
        }
    }
})
