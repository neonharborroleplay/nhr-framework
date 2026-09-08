const app=document.querySelector('#app'),content=document.querySelector('#content'),tabs=document.querySelector('#tabs'),cameraViews=document.querySelector('#camera-views');
const save=document.querySelector('#save'),cancel=document.querySelector('#cancel');
const tabNames={identity:'Identity',heritage:'Heritage',face:'Face',hair:'Hair',clothing:'Clothing',props:'Props'};
const faceNames=['Nose width','Nose peak height','Nose peak length','Nose bone height','Nose tip','Nose twist','Brow height','Brow depth','Cheekbone height','Cheekbone width','Cheek width','Eye opening','Lip thickness','Jaw width','Jaw shape','Chin height','Chin length','Chin width','Chin cleft','Neck thickness'];
let state={appearance:null,limits:null,required:false,tab:'identity',camera:'whole'};
const resource=typeof GetParentResourceName==='function'?GetParentResourceName():'nhr_appearance';
const post=(name,data={})=>fetch(`https://${resource}/${name}`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data)}).then(r=>r.json()).catch(()=>false);
const val=(v,d=0)=>Number.isFinite(Number(v))?Number(v):d;
const decimals=n=>{const text=String(n);return text.includes('.')?text.length-text.indexOf('.')-1:0};
const displayValue=(number,precision)=>Number(number.toFixed(precision)).toString();
function slider(label,min,max,value,step,onChange){
  const box=document.createElement('div'),precision=decimals(step);
  let current=Math.max(min,Math.min(max,val(value,min)));
  box.className='control';
  box.innerHTML=`<div class="control-head"><span>${label}</span><div class="stepper"><button type="button" data-step="-1" aria-label="Previous ${label}">‹</button><b class="value">${displayValue(current,precision)}</b><button type="button" data-step="1" aria-label="Next ${label}">›</button></div></div><input type="range" min="${min}" max="${max}" step="${step}" value="${current}">`;
  const input=box.querySelector('input'),out=box.querySelector('b');
  const select=next=>{
    if(next>max)next=min;
    if(next<min)next=max;
    current=Number(next.toFixed(precision));
    input.value=current;
    out.textContent=displayValue(current,precision);
    onChange(current);
  };
  input.addEventListener('input',()=>{current=val(input.value);out.textContent=displayValue(current,precision)});
  input.addEventListener('change',()=>onChange(current));
  box.querySelectorAll('[data-step]').forEach(button=>button.addEventListener('click',()=>select(current+(val(button.dataset.step)*step))));
  return box;
}
function group(title,...children){const el=document.createElement('div');el.className='group';el.innerHTML=`<div class="group-title"><span>${title}</span></div>`;children.forEach(c=>el.appendChild(c));return el}
function renderTabs(){tabs.innerHTML='';Object.entries(tabNames).forEach(([id,label])=>{const b=document.createElement('button');b.textContent=label;b.classList.toggle('active',state.tab===id);b.onclick=()=>{state.tab=id;render()};tabs.appendChild(b)})}
function selectCamera(view){state.camera=view;cameraViews.querySelectorAll('[data-camera]').forEach(button=>button.classList.toggle('active',button.dataset.camera===view));post('camera',{view})}
function renderIdentity(a){const wrap=document.createElement('div'),choice=document.createElement('div');choice.className='choice';['male','female'].forEach(model=>{const b=document.createElement('button');b.textContent=model==='male'?'Male':'Female';b.classList.toggle('active',a.model===model);b.onclick=()=>post('model',{model});choice.appendChild(b)});wrap.appendChild(group('Freemode body',choice));return wrap}
function renderHeritage(a){const wrap=document.createElement('div'),b=a.headBlend||{};wrap.appendChild(group('Parents',slider('Mother',0,45,val(b.mother),1,v=>post('blend',{...b,mother:v})),slider('Father',0,45,val(b.father),1,v=>post('blend',{...b,father:v}))));wrap.appendChild(group('Resemblance',slider('Face mix',0,1,val(b.shapeMix,.5),.05,v=>post('blend',{...b,shapeMix:v})),slider('Skin mix',0,1,val(b.skinMix,.5),.05,v=>post('blend',{...b,skinMix:v}))));return wrap}
function renderFace(a){
  const wrap=document.createElement('div');
  faceNames.forEach((name,i)=>wrap.appendChild(group(name,
    slider('Shape',-1,1,val((a.faceFeatures||[])[i]),.05,v=>post('face',{index:i,value:v}))
  )));
  (state.limits.overlays||[]).forEach(o=>{
    const cur=(a.overlays||{})[String(o.id)]||{};
    const controls=[
      slider('Style',-1,o.max,val(cur.value,-1),1,v=>post('overlay',{id:o.id,value:v,opacity:val(cur.value,-1)<0?1:val(cur.opacity,1),color:val(cur.color),activate:true})),
      slider('Opacity',0,1,val(cur.opacity,1),.05,v=>post('overlay',{id:o.id,value:val(cur.value,-1),opacity:v,color:val(cur.color)}))
    ];
    if(val(o.colorType)>0&&val(o.colorMax,-1)>=0)controls.push(slider('Color',0,o.colorMax,val(cur.color),1,v=>post('overlay',{id:o.id,value:val(cur.value,-1),opacity:val(cur.opacity,1),color:v})));
    wrap.appendChild(group(o.label,...controls));
  });
  return wrap;
}
function renderHair(a){const wrap=document.createElement('div'),h=a.hair||{};wrap.appendChild(group('Hair',slider('Style',0,state.limits.hairMax,val(h.style),1,v=>post('hair',{...h,style:v})),slider('Color',0,state.limits.hairColors,val(h.color),1,v=>post('hair',{...h,color:v})),slider('Highlights',0,state.limits.hairColors,val(h.highlight),1,v=>post('hair',{...h,highlight:v}))));wrap.appendChild(group('Eyes',slider('Eye color',0,31,val(a.eyeColor),1,v=>post('eye',{color:v}))));return wrap}
function renderComponents(a){
  const wrap=document.createElement('div');
  state.limits.components.forEach(item=>{
    const cur=(a.components||{})[String(item.id)]||{};
    wrap.appendChild(group(item.label,
      slider('Drawable',0,item.drawableMax,val(cur.drawable),1,v=>post('component',{id:item.id,drawable:v,texture:0})),
      slider('Texture',0,item.textureMax,val(cur.texture),1,v=>post('component',{id:item.id,drawable:val(cur.drawable),texture:v}))
    ));
  });
  return wrap;
}
function renderProps(a){
  const wrap=document.createElement('div');
  state.limits.props.forEach(item=>{
    const cur=(a.props||{})[String(item.id)]||{};
    wrap.appendChild(group(item.label,
      slider('Drawable',-1,item.drawableMax,val(cur.drawable,-1),1,v=>post('prop',{id:item.id,drawable:v,texture:0})),
      slider('Texture',0,item.textureMax,val(cur.texture),1,v=>post('prop',{id:item.id,drawable:val(cur.drawable,-1),texture:v}))
    ));
  });
  return wrap;
}
function render(){if(!state.appearance||!state.limits)return;renderTabs();content.innerHTML='';const a=state.appearance;content.appendChild(state.tab==='identity'?renderIdentity(a):state.tab==='heritage'?renderHeritage(a):state.tab==='face'?renderFace(a):state.tab==='hair'?renderHair(a):state.tab==='clothing'?renderComponents(a):renderProps(a));cancel.classList.toggle('hidden',state.required)}
cameraViews.querySelectorAll('[data-camera]').forEach(button=>button.onclick=()=>selectCamera(button.dataset.camera));
window.addEventListener('message',e=>{const d=e.data||{};if(d.action==='open'){state.required=!!d.required;state.camera='whole';cameraViews.querySelectorAll('[data-camera]').forEach(button=>button.classList.toggle('active',button.dataset.camera==='whole'));document.body.style.display='block'}else if(d.action==='close'){document.body.style.display='none'}else if(d.action==='hydrate'){state.appearance=d.appearance;state.limits=d.limits;render()}});
document.querySelectorAll('[data-rotate]').forEach(b=>b.onclick=()=>post('rotate',{amount:val(b.dataset.rotate)}));
save.onclick=async()=>{save.disabled=true;await post('save');save.disabled=false};cancel.onclick=()=>post('cancel');
window.addEventListener('keydown',e=>{if(e.key==='Escape'&&!state.required)post('cancel')});
