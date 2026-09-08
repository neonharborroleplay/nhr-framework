NHR = NHR or {}
NHR.Config = NHRConfig
NHR.Shared = { Jobs = NHRJobs, Gangs = NHRGangs }
NHR.Version = '1.0.0'
NHR.Capabilities = {
    accounts = true,
    multicharacter = true,
    multijob = true,
    multigang = true,
    metadata = true,
    persistentPosition = true,
    serverAuthority = true
}

function NHR.GetCoreObject()
    return NHR
end

function NHR.GetRuntimeInfo()
    return {
        name = NHRConfig.Brand.Name,
        shortName = NHRConfig.Brand.ShortName,
        version = NHR.Version,
        resource = GetCurrentResourceName(),
        capabilities = NHR.Capabilities
    }
end

exports('GetCoreObject', NHR.GetCoreObject)
exports('GetRuntimeInfo', NHR.GetRuntimeInfo)
