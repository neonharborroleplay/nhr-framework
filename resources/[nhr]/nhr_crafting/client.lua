local function openBench(name)
    local bench=NHRCrafting[name];local options={}
    for index,definition in ipairs(bench.recipes)do local recipe,i=definition,index;local parts={};for item,count in pairs(recipe.ingredients)do parts[#parts+1]=count..'x '..item end
        options[#options+1]={title=recipe.label,description=('Requires %d XP · %s'):format(recipe.minXp or 0,table.concat(parts,', ')),onSelect=function()if not lib.callback.await('nhr_crafting:begin',false,name,i)then return lib.notify({type='error',description='Requirements not met.'})end;if lib.progressCircle({duration=recipe.time,label='Crafting '..recipe.label,canCancel=false,disable={move=true,combat=true}})then local ok=lib.callback.await('nhr_crafting:finish',false);lib.notify({type=ok and'success'or'error',description=ok and'Item crafted.'or'Crafting failed.'})end end}
    end
    lib.registerContext({id='nhr_crafting_'..name,title=bench.label,options=options});lib.showContext('nhr_crafting_'..name)
end
CreateThread(function()for name,bench in pairs(NHRCrafting)do local id=name;exports.ox_target:addSphereZone({coords=bench.coords,radius=1.5,options={{name='nhr_craft_'..id,label=bench.label,icon='fa-solid fa-hammer',onSelect=function()openBench(id)end}}})end end)
