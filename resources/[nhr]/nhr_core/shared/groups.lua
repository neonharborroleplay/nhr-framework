NHRJobs = {
    unemployed = {
        label = 'Civilian', defaultDuty = false,
        grades = { [0] = { name = 'Unemployed', payment = 10 } }
    },
    police = {
        label = 'Police Department', defaultDuty = false,
        grades = {
            [0] = { name = 'Cadet', payment = 75 },
            [1] = { name = 'Officer', payment = 100 },
            [2] = { name = 'Sergeant', payment = 135 },
            [3] = { name = 'Chief', payment = 175, isBoss = true }
        }
    },
    ambulance = {
        label = 'Emergency Medical Services', defaultDuty = false,
        grades = {
            [0] = { name = 'EMT', payment = 75 },
            [1] = { name = 'Paramedic', payment = 110 },
            [2] = { name = 'Chief', payment = 160, isBoss = true }
        }
    },
    mechanic = {
        label = 'Mechanic', defaultDuty = false,
        grades = {
            [0] = { name = 'Apprentice', payment = 50 },
            [1] = { name = 'Mechanic', payment = 85 },
            [2] = { name = 'Owner', payment = 125, isBoss = true }
        }
    },
    taxi = {
        label = 'Downtown Cab Co.', defaultDuty = false,
        grades = { [0] = { name = 'Driver', payment = 45 }, [1] = { name = 'Manager', payment = 70, isBoss = true } }
    },
    tow = {
        label = 'Los Santos Towing', defaultDuty = false,
        grades = { [0] = { name = 'Operator', payment = 50 }, [1] = { name = 'Manager', payment = 80, isBoss = true } }
    }
}

NHRGangs = {
    none = { label = 'No Gang', grades = { [0] = { name = 'Unaffiliated' } } }
}
