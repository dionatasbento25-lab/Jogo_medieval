/* =====================================================================
   12. INTERFACE
   ===================================================================== */
const $=id=>document.getElementById(id);
let mode='select',placing=null,ghost=null,selected=0,ghostRot=0;
function toast(s){const box=$('toasts');const el=document.createElement('div');el.className='toast';el.textContent=s;box.appendChild(el);while(box.children.length>3)box.firstChild.remove();setTimeout(()=>{el.classList.add('out');setTimeout(()=>el.remove(),400)},2600)}
function updateHUD(){
 for(const k of RES){$('r_'+k).textContent=fmt(S.res[k]);const r=econ.rate[k];const el=$('rr_'+k);el.textContent=(r>=0?'+':'')+(Math.abs(r)<10?r.toFixed(1):Math.round(r))+'/s';el.className='rate '+(r<-.001?'neg':'');
  $('rb_'+k).style.width=clamp(S.res[k]/econ.cap*100,0,100)+'%'}
 $('r_pop').textContent=S.pop+'/'+econ.popCap;$('rr_pop').textContent=econ.idle?econ.idle+' livres':'todos ocupados';
 $('r_hap').textContent=Math.round(econ.hap)+'%';$('hapIcon').textContent=econ.hap>=80?'😄':econ.hap>=55?'🙂':econ.hap>=35?'😐':'😟';
 $('capTxt').textContent='Capacidade: '+fmt(econ.cap);
 if(menuOpen)renderMenu(false);if(selected)refreshPanel(true);
 const g=GOALS[S.goal];if(g){const v=Math.min(g.n,g.f());$('goalTxt').textContent=g.t;$('goalProg').textContent=g.n>1?`${v}/${g.n}`:'';$('goalBar').style.width=(v/g.n*100)+'%';$('goalRew').innerHTML='Prêmio: '+g.r.map((x,i)=>x?RICON[RES[i]]+x:'').join(' ')}
 else{$('goalTxt').textContent='Todos os objetivos concluídos! Seu reino é lendário 👑';$('goalProg').textContent='';$('goalBar').style.width='100%';$('goalRew').textContent=''}}
let warnT=-99;
function checkGoals(){if(castleL()&&econ.rate.food<0&&S.res.food<40&&gameTime-warnT>45){warnT=gameTime;toast('🌾 A comida está acabando! Construa ou melhore fazendas.')}
 const g=GOALS[S.goal];if(!g)return;if(g.f()>=g.n){for(let i=0;i<3;i++)S.res[RES[i]]+=g.r[i];S.goal++;toast('📜 Objetivo concluído: '+g.t+'!');const el=$('goal');el.classList.remove('done');void el.offsetWidth;el.classList.add('done')}}
// Menu de construção
let menuOpen=false;
function renderMenu(full=true){const box=$('buildMenu'),cl=castleL();if(full){box.innerHTML='';
  for(const t of BUILD_ORDER){const T=TYPES[t],d=DEF[t],el=document.createElement('button');el.className='card';el.dataset.t=t;
   el.innerHTML=`<div class="ic">${T.icon}</div><div class="nm">${T.name}</div><div class="cs"></div><div class="lk"></div>`;el.onclick=()=>startPlacing(t);box.appendChild(el)}}
 for(const el of box.children){const t=el.dataset.t,d=DEF[t],c=costOf(t,1),locked=cl<d.unlock;el.classList.toggle('locked',locked);el.classList.toggle('poor',!locked&&!canPay(c));
  el.querySelector('.cs').innerHTML=locked?'':costHTML(c);el.querySelector('.lk').textContent=locked?`🔒 Castelo nv. ${d.unlock}`:'';el.classList.toggle('active',placing&&placing.type===t)}}
function openMenu(on){menuOpen=on;$('buildMenu').classList.toggle('show',on);$('btnBuild').classList.toggle('active',on);if(on){renderMenu(true);closeInfo()}}
function setMode(m){mode=m;for(const b of document.querySelectorAll('.tool[data-mode]'))b.classList.toggle('active',b.dataset.mode===m);if(m!=='build'){placing=null;ghost=null;$('confirm').classList.remove('show');terrDirty=true}
 $('tip').textContent=m==='demolish'?'🗑 Toque numa construção para demolir (devolve 50%)':m==='build'?'🏗 Escolha um local dentro das províncias do seu reino':'☝ Toque numa construção para ver detalhes e melhorar'}
function startPlacing(t){if(t!=='castle'){const d=DEF[t];if(castleL()<d.unlock){toast(`🔒 Requer castelo nível ${d.unlock}`);return}if(!canPay(costOf(t,1))){toast('Recursos insuficientes');}}
 placing={type:t};setMode('build');mode='build';openMenu(false);
 for(const b of document.querySelectorAll('.tool[data-mode]'))b.classList.toggle('active',b.dataset.mode==='build');
 $('tip').textContent=`🏗 ${TYPES[t].icon} ${TYPES[t].name}: ${MOBILE?'toque no mapa para posicionar':'clique no mapa para construir • R gira'}`;
 if(castleB()&&t!=='castle'&&dist>220){const c=castleB();flyTo(c.x,c.z,170,.95)}}
function updateGhost(px,pz){if(!placing)return;const c=check(placing.type,px,pz);const k=placing.type+c.x+','+c.z+','+ghostRot+c.ok;if(ghost&&ghost.k===k)return;
 ghost=Object.assign(c,{k,type:placing.type});const b={type:placing.type,x:c.x,z:c.z,y:c.ok?c.y:Math.max(meshH(c.x,c.z),0)+.15,minH:c.ok?c.minH:Math.max(meshH(c.x,c.z),0),rot:ghostRot};
 ghostOut.reset();stampFoundation(ghostOut,b);stampBuilding(ghostOut,b,getModel(placing.type,1));ghostOut.upload();
 if(placing.type==='castle')terrDirty=true;
 const g=$('ghostInfo');const ef=DEF[placing.type].job&&DEF[placing.type].job!=='happy'?` • Rendimento ${Math.round(c.e*100)}%`:'';g.innerHTML=c.ok?`<b>${TYPES[placing.type].name}</b>${ef}`:`<span class="bad">⛔ ${c.why}</span>`;g.classList.add('show')}
function confirmPlace(){if(!ghost||!placing)return;if(!ghost.ok){toast('⛔ '+ghost.why);return}const t=placing.type;const b=placeBuilding(t,ghost,ghostRot);if(!b)return;
 ghost=null;ghostOut.reset();ghostOut.upload();$('confirm').classList.remove('show');$('ghostInfo').classList.remove('show');
 if(t==='castle'){placing=null;setMode('select');$('intro').classList.remove('show');flyTo(b.x,b.z,120,.9)}
 else if(!canPay(costOf(t,1))){placing=null;setMode('select')}}
function rotateGhost(){ghostRot=(ghostRot+1)%4;if(ghost){const x=ghost.x,z=ghost.z;ghost=null;updateGhost(x,z)}}
// Painel de informações
function closeInfo(){$('info').classList.remove('show');selected=0}
function select(b){selected=b?b.id:0;if(!b){closeInfo();return}refreshPanel();$('info').classList.add('show');openMenu(false)}
function stars(n,m){let s='';for(let i=1;i<=m;i++)s+=i<=n?'★':'☆';return s}
let panelSig='';
function refreshPanel(soft){const b=byId.get(selected);if(!b){closeInfo();return}const T=TYPES[b.type],d=DEF[b.type];
 let rows=[];const L=b.level;
 if(b.state==='site')rows.push(`<div class="prog"><i style="width:${b.prog*100}%"></i></div><div class="small">Em construção… ${Math.round(b.prog*100)}% — toque no canteiro para ajudar!</div>`);
 else{
  if(b.type==='castle'){const fh=FEUDAL.houses[S.kingdom],Lr=Dyn.C[Dyn.H[S.kingdom].leader];rows.push(`<b>${fh.name}</b> • ${fh.n} províncias`,Lr?`Monarca: <b>${Dyn.title(Lr)} ${esc(Dyn.nm(Lr))}</b> (${Dyn.age(Lr)} anos)`:'',`Impostos: <b>+${(.4+.25*(L-1)+.025*S.pop).toFixed(1)} 🪙/s</b> • Moradia: <b>6</b>`,`Construtores: <b>${econ.builders}</b> <a href="#" id="seeDyn">👑 Ver a dinastia</a>`);
   const nx=BUILD_ORDER.filter(t=>DEF[t].unlock===L+1).map(t=>TYPES[t].icon+' '+TYPES[t].name);if(nx.length)rows.push(`<span class="small">Próximo nível libera: ${nx.join(', ')}</span>`)}
  if(b.type==='house'){const n=vill.filter(v=>v.home===b.id).length;rows.push(`Moradores: <b>${n}/${4+2*(L-1)}</b>`)}
  if(d.job&&d.job!=='happy')rows.push(`Produção: <b>+${((b.rate||0)*(b.workers||0)).toFixed(2)} ${RICON[d.job]}/s</b>`,`Trabalhadores: <b>${b.workers||0}/${slotsOf(b)}</b> • Rendimento do terreno: <b>${Math.round(b.e*100)}%</b>`);
  if(b.type==='tavern')rows.push(`Felicidade: <b>+${8+5*L}%</b> • Atendentes: ${b.workers||0}/${slotsOf(b)}`);
  if(b.type==='well')rows.push(`Felicidade: <b>+${3+2*L}%</b>`);
  if(b.type==='market')rows.push(`Felicidade: <b>+${2*L}%</b>`);
  if(b.type==='warehouse')rows.push(`Capacidade extra: <b>+${500*L}</b>`);
  if(b.type==='tower')rows.push(`Felicidade: <b>+${2+2*L}%</b> (segurança)`);
  if(b.upg)rows.push(`<div class="prog"><i style="width:${b.prog*100}%"></i></div><div class="small">Melhorando para o nível ${L+1}… ${Math.round(b.prog*100)}%</div>`)}
 const canUp=b.state==='done'&&!b.upg&&L<T.max,c=canUp?costOf(b.type,b.type==='castle'?L:L+1):null;
 const sig=[b.id,b.state,L,b.upg,Math.round(b.prog*100),b.workers,Math.round((b.rate||0)*100),canUp&&canPay(c),S.pop].join('|');if(soft&&sig===panelSig)return;panelSig=sig;
 $('infoTitle').innerHTML=`${T.icon} ${T.name} <span class="stars">${stars(L,T.max)}</span>`;
 $('infoBody').innerHTML=`<p class="desc">${d.desc}</p>`+rows.map(r=>`<div class="row">${r}</div>`).join('');
 const up=$('btnUp');up.style.display=canUp?'':'none';if(canUp){up.innerHTML=`⬆ Melhorar <small>${costHTML(c)}</small>`;up.classList.toggle('poor',!canPay(c))}
 $('btnDemo').style.display=b.type==='castle'?'none':'';const sd=$('seeDyn');if(sd)sd.onclick=e=>{e.preventDefault();openHouse(S.kingdom)}}
// Rótulos flutuantes (+recursos) e barras de construção
const floaters=[];
function floatText(x,y,z,txt){if(floaters.length>40)return;const el=document.createElement('div');el.className='float';el.textContent=txt;$('overlay').appendChild(el);floaters.push({x,y,z,el,t:0})}
const bars=new Map();
function updateOverlays(dt){
 for(let i=floaters.length-1;i>=0;i--){const f=floaters[i];f.t+=dt;if(f.t>1.6||dist>650){f.el.remove();floaters.splice(i,1);continue}const p=toScreen(f.x,f.y+f.t*2.5,f.z);
  if(!p){f.el.style.display='none';continue}f.el.style.display='';f.el.style.transform=`translate(${p.x}px,${p.y}px) translate(-50%,-50%) scale(${.8+Math.min(f.t*3,1)*.3})`;f.el.style.opacity=f.t<1.1?1:1-(f.t-1.1)/.5}
 const seen=new Set();
 if(dist<900)for(const b of S.b){if(!(b.state==='site'||b.upg))continue;seen.add(b.id);let el=bars.get(b.id);if(!el){el=document.createElement('div');el.className='bbar';el.innerHTML='<i></i><span>🔨</span>';$('overlay').appendChild(el);bars.set(b.id,el)}
  const p=toScreen(b.x,b.y+(HEIGHT[b.type]||6)+2,b.z);if(!p){el.style.display='none';continue}el.style.display='';el.style.transform=`translate(${p.x}px,${p.y}px) translate(-50%,-50%)`;el.firstChild.style.width=(b.prog*100)+'%';
  const nb=vill.some(v=>v.site===b.id&&v.task&&v.task.k==='build')||(b.type==='castle'&&b.state==='site');el.lastChild.textContent=nb?'🔨':'⏳';el.title=nb?'':'Aguardando construtor'}
 for(const [id,el] of bars)if(!seen.has(id)){el.remove();bars.delete(id)}}

/* ---------- Toques e gestos ---------- */
function tap(x,y){
 if(mode==='build'&&placing){const g=pickGround(x,y);if(!g)return;
  if(MOBILE){if(ghost&&ghost.ok&&Math.abs(snapPos(placing.type,g.x,g.z).x-ghost.x)<.1&&Math.abs(snapPos(placing.type,g.x,g.z).z-ghost.z)<.1){confirmPlace();return}
   updateGhost(g.x,g.z);$('confirm').classList.add('show');return}
  updateGhost(g.x,g.z);confirmPlace();return}
 const b=pickBuilding(x,y);
 if(mode==='demolish'){if(b){if(b.type==='castle'){toast('O castelo não pode ser demolido');return}select(b);$('btnDemo').classList.add('pulse');setTimeout(()=>$('btnDemo').classList.remove('pulse'),900)}return}
 if(b){if(b.state==='site'||b.upg){b.prog=Math.min(1,b.prog+.04);for(let k=0;k<5;k++)spark(b.x+(Math.random()-.5)*6,b.z+(Math.random()-.5)*6);if(b.prog>=1)finishBuild(b)}select(b);return}
 closeInfo();openProvince(x,y)}
/* ---------- Províncias e reinos (do mapa original) ---------- */
function closePanel(){$('panel').classList.remove('show');if(selProv>=0){selProv=-1;buildPolitical()}lastKey=''}window.closePanel=closePanel;
function openProvince(x,y){const p=pickGround(x,y);if(!p)return;const id=provAt(p.x,p.z);
 if(id<0){closePanel();return}
 if(id!==selProv){selProv=id;buildPolitical()}
 const pr=FEUDAL.prov[id],hi=pr[2],h=FEUDAL.houses[hi],rg=FEUDAL.regions[h.region],cl=classAt(p.x,p.z),alt=Math.round(Math.max(meshH(p.x,p.z),0)*10);
 const cnt=[0,0,0,0,0];for(const [,t] of NEIGH[id])cnt[t]++;const nLand=cnt[0]+cnt[1]+cnt[2];
 const extra=[cnt[1]?`${cnt[1]} com rio`:'',cnt[2]?`${cnt[2]} por estreito`:''].filter(Boolean).join(', ');
 const seaTxt=[cnt[3]?`${cnt[3]} por travessia`:'',cnt[4]?`${cnt[4]} além-mar`:''].filter(Boolean).join(' · ');
 const dot=c=>`<span style="display:inline-block;width:10px;height:10px;border-radius:3px;background:${c};margin-right:5px;vertical-align:-1px"></span>`;
 const Lr=Dyn.C[Dyn.H[hi].leader],mineK=hi===S.kingdom;
 $('panelTitle').textContent='🧩 Província '+FEUDAL.ids[id].replace(/^TRT0*/,'');
 $('panelText').innerHTML=`${dot(h.color)}<span class="badge">${h.name}</span>${mineK?' <span class="tag heir">seu reino</span>':''}<br><span class="small">${h.n} províncias${h.seat===id?' · <b>capital do reino</b>':''}</span><br>`+
  `Região: ${dot(rg.color)}${rg.name}<br>Monarca: <span class="badge">${Dyn.title(Lr)} ${esc(Dyn.nm(Lr))} (${Dyn.age(Lr)})</span><br>Vizinhas por terra: <span class="badge">${nLand}</span>${extra?` <span class="small">(${extra})</span>`:''}<br>${seaTxt?`<span class="small">🚢 Pelo mar: ${seaTxt}</span><br>`:''}<span class="small">${CLASS_NAMES[cl]} · ${alt} m</span><br>`+
  (S.kingdom<0?`<button id="rule" class="gold" style="margin-top:8px;width:100%">👑 Governar este reino</button><br>`:'')+
  `<button id="goProv" style="margin-top:8px;background:#3b4d43">📍 Ir até</button> <button id="seeHouse" style="margin-top:8px">👑 Ver o reino</button>`;
 $('seeHouse').onclick=()=>{$('panel').classList.remove('show');openHouse(hi)};
 $('goProv').onclick=()=>{const a=anchorOf(id);flyTo(a.x,a.z,Math.min(dist,320))};
 if($('rule'))$('rule').onclick=()=>chooseKingdom(hi);
 $('panel').classList.add('show')}
function chooseKingdom(h){if(S.kingdom>=0)return;const fh=FEUDAL.houses[h];S.kingdom=h;const c=castleSpotFor(h);
 if(!c){S.kingdom=-1;toast('Não há espaço plano para o castelo neste reino. Escolha outro.');return}
 closePanel();$('intro').classList.remove('show');buildPolitical();buildWorldCastles();
 const b=placeBuilding('castle',c,0);flyTo(b.x,b.z,130,.9);setMode('select');
 toast(`👑 Você agora governa o ${fh.name}!`);GameTime.continuar();save()}
const ptrs=new Map();let moved=false,downPos=null,btn=0,gesture=null,multi=false;
function clampTarget(){target[0]=clamp(target[0],-HX,HX);target[2]=clamp(target[2],-HZ,HZ)}
canvas.addEventListener('pointerdown',e=>{fly=null;const q=toApp(e);canvas.setPointerCapture(e.pointerId);tryLandscapeLock();ptrs.set(e.pointerId,q);
 if(ptrs.size===1){moved=false;multi=false;downPos=q;btn=e.button}else{multi=true;moved=true}gesture=null});
canvas.addEventListener('pointermove',e=>{const q0=toApp(e);
 if(!ptrs.has(e.pointerId)){if(!MOBILE&&e.pointerType==='mouse'&&placing){const g=pickGround(q0.x,q0.y);if(g)updateGhost(g.x,g.z)}return}
 const prev=ptrs.get(e.pointerId),q=q0;ptrs.set(e.pointerId,q);
 if(ptrs.size===1){if(Math.abs(q.x-downPos.x)+Math.abs(q.y-downPos.y)>7)moved=true;if(!moved)return;
  if(btn===2||e.shiftKey){yaw-=(q.x-prev.x)*.007;pitch=clamp(pitch+(q.y-prev.y)*.006,.35,1.45)}
  else{const a=pickPlane(prev.x,prev.y,target[1]),b=pickPlane(q.x,q.y,target[1]);if(a&&b){target[0]+=a.x-b.x;target[2]+=a.z-b.z;clampTarget()}}}
 else{const [a,b]=[...ptrs.values()],mx=(a.x+b.x)/2,my=(a.y+b.y)/2,d=Math.hypot(a.x-b.x,a.y-b.y)||1,ang=Math.atan2(b.y-a.y,b.x-a.x);
  if(gesture){dist=clamp(dist*gesture.d/d,DMIN,DMAX);let da=ang-gesture.ang;if(da>Math.PI)da-=2*Math.PI;if(da<-Math.PI)da+=2*Math.PI;yaw-=da;pitch=clamp(pitch+(my-gesture.my)*.005,.35,1.45);
   const pa=pickPlane(gesture.mx,gesture.my,target[1]),pb=pickPlane(mx,my,target[1]);if(pa&&pb){target[0]+=pa.x-pb.x;target[2]+=pa.z-pb.z;clampTarget()}}
  gesture={d,ang,mx,my}}});
function endPtr(e){if(!ptrs.has(e.pointerId))return;const q=ptrs.get(e.pointerId);ptrs.delete(e.pointerId);gesture=null;
 if(ptrs.size===0){if(!moved&&!multi&&btn!==2)tap(q.x,q.y)}else{downPos=[...ptrs.values()][0];moved=true}}
canvas.addEventListener('pointerup',endPtr);canvas.addEventListener('pointercancel',endPtr);
canvas.addEventListener('contextmenu',e=>e.preventDefault());
canvas.addEventListener('wheel',e=>{e.preventDefault();fly=null;dist=clamp(dist*Math.exp(e.deltaY*.0012),DMIN,DMAX)},{passive:false});
addEventListener('keydown',e=>{if(e.key==='r'||e.key==='R')rotateGhost();if(e.key==='Escape'){setMode('select');openMenu(false);closeInfo()}if(e.key==='b'||e.key==='B')openMenu(!menuOpen)});
$('btnSelect').onclick=()=>{setMode('select');openMenu(false)};
$('btnBuild').onclick=()=>{if(S.kingdom<0){toast('👑 Primeiro toque numa província e escolha o seu reino');return}openMenu(!menuOpen)};
$('btnMap').onclick=()=>{$('mapMenu').classList.toggle('show');openMenu(false)};
for(const b of document.querySelectorAll('#mapMenu button'))b.onclick=()=>{mapMode=b.dataset.map;document.querySelectorAll('#mapMenu button').forEach(x=>x.classList.toggle('active',x===b));buildPolitical();$('mapMenu').classList.remove('show');toast('Mapa: '+MODES[mapMode].name)};
$('full').onclick=()=>goFullscreen().then(r=>{if(r==='sem')toast('Este app não permite tela cheia. Abra o arquivo no Chrome para jogar em tela inteira.');else if(r==='ok')toast('Tela cheia ativada')});
$('btnDemolish').onclick=()=>{setMode('demolish');openMenu(false)};
$('btnUp').onclick=()=>{const b=byId.get(selected);if(b)upgradeBuilding(b)};
$('btnDemo').onclick=()=>{const b=byId.get(selected);if(!b)return;const btn=$('btnDemo');if(btn.dataset.sure!=='1'){btn.dataset.sure='1';btn.textContent='Confirmar?';setTimeout(()=>{btn.dataset.sure='';btn.textContent='🗑 Demolir'},2500);return}btn.dataset.sure='';btn.textContent='🗑 Demolir';demolish(b)};
$('btnClose').onclick=closeInfo;
$('cOk').onclick=confirmPlace;$('cRot').onclick=rotateGhost;$('cNo').onclick=()=>{setMode('select')};
$('plus').onclick=()=>{fly=null;dist=clamp(dist*.7,DMIN,DMAX)};$('minus').onclick=()=>{fly=null;dist=clamp(dist*1.43,DMIN,DMAX)};
$('reset').onclick=()=>{const c=castleB();if(c)flyTo(c.x,c.z,140,.95,0);else flyTo(0,0,HOME.dist,HOME.pitch,0)};
$('orient').onclick=()=>{setLandscape(!wantLand);toast(wantLand?'Modo horizontal ativado':'Modo vertical ativado')};
$('goal').onclick=()=>$('goal').classList.toggle('mini');
$('introGo').onclick=()=>{$('intro').classList.remove('show');$('tip').textContent='👑 Toque numa província do reino que você quer governar';toast('Toque numa província e depois em “Governar este reino”')};
$('backOk').onclick=()=>$('back').classList.remove('show');
$('btnReset').onclick=()=>{if(confirm('Apagar o reino e começar de novo?')){try{localStorage.removeItem(SAVE_KEY)}catch(e){}location.reload()}};

/* ---------- Salvar / carregar (com ganhos enquanto você estava fora) ---------- */
function save(){if(!S.castle)return;S.saved=Date.now();const data={kingdom:S.kingdom,res:S.res,pop:S.pop,goal:S.goal,castle:S.castle,nextId:S.nextId,saved:S.saved,growT:S.growT,
 b:S.b.map(b=>({id:b.id,type:b.type,x:b.x,z:b.z,rot:b.rot,level:b.level,state:b.state,prog:b.prog,upg:b.upg,work:b.work})),cam:[target[0],target[2],dist,yaw,pitch]};
 try{localStorage.setItem(SAVE_KEY,JSON.stringify(data))}catch(e){}}
function load(){let d=null;try{d=JSON.parse(localStorage.getItem(SAVE_KEY)||'null')}catch(e){}if(!d||!d.b||!d.b.length||!(d.kingdom>=0))return false;
 S.kingdom=d.kingdom;buildPolitical();buildWorldCastles();
 S.res=Object.assign({gold:0,wood:0,stone:0,food:0},d.res);S.pop=d.pop|0;S.goal=d.goal|0;S.nextId=d.nextId||1;S.growT=d.growT||0;
 for(const o of d.b){const b=addBuilding({id:o.id,type:o.type,x:o.x,z:o.z,rot:o.rot||0,level:o.level||1,state:o.state,prog:o.prog||0,upg:!!o.upg,work:o.work||workTime(o.type,o.level||1)})}
 S.castle=d.castle;computeEcon();computeEcon();
 const away=clamp((Date.now()-(d.saved||Date.now()))/1000,0,4*3600);
 if(away>60){const gain={};for(const k of RES){const r=econ.rate[k];gain[k]=r>0?r*away*.5:0;S.res[k]=clamp(S.res[k]+gain[k],0,econ.cap)}
  for(const b of S.b)if(b.state==='site'||b.upg){b.prog=Math.min(1,b.prog+away/b.work*.5);if(b.prog>=1){b.state='done';if(b.upg){b.level++;b.upg=false}b.prog=0}}
  const h=Math.floor(away/3600),m=Math.floor(away%3600/60);$('backTxt').innerHTML=`Você ficou fora por <b>${h?h+'h ':''}${m} min</b>.<br>Seu povo continuou trabalhando:`+
   `<div class="gains">${RES.map(k=>gain[k]>=1?`<span>${RICON[k]} +${fmt(gain[k])}</span>`:'').join('')}</div>`;$('back').classList.add('show')}
 if(d.cam){target=[d.cam[0],0,d.cam[1]];dist=d.cam[2];yaw=d.cam[3];pitch=d.cam[4]}
 staticDirty=true;computeEcon();syncVillagers();assignRoles();GameTime.continuar();
 // espalha os aldeões pela vila ao carregar
 const done=S.b.filter(b=>b.state==='done');for(const v of vill){const b=pick(done);if(b){const dd=doorOf(b);v.x=dd[0]+(Math.random()-.5)*4;v.z=dd[1]+(Math.random()-.5)*4}}
 return true}
addEventListener('visibilitychange',()=>{if(document.hidden)save()});addEventListener('pagehide',save);

/* ---------- Inicialização ---------- */
const setLoad=t=>$('loadTxt').textContent=t,tick=()=>new Promise(r=>setTimeout(r,16));
(async()=>{try{const t0=performance.now();
 const [alb,hm,pv,rv]=await Promise.all([loadImg(ALBEDO_SRC),loadImg(HMAP_SRC),loadImg(PROV_SRC),loadImg(RIVER_SRC)]);
 setLoad('Lendo o relevo…');await tick();readHeightmap(hm);buildNodeHeights();
 setLoad('Preparando o terreno…');await tick();uploadAlbedo(alb);bakeNormals();bakeDetail();bakeSplat();bakePatterns();
 setLoad('Desenhando as províncias…');await tick();readProv(pv);readRiver(rv);buildRiverGrid();buildBorders();buildPolitical();buildChunks();
 setLoad('Erguendo os castelos dos 61 reinos…');await tick();buildTreeModels();buildVillagerMesh();for(const t of Object.keys(TYPES))getModel(t,1);buildStraits();
 const had=load();if(!had){buildWorldCastles();$('intro').classList.add('show')}
 window.__loadMs=Math.round(performance.now()-t0);window.__dbg=()=>({drawnChunks,trees:treeNd+treeNc,dist,vill:vill.length,vCount,static:staticOut.count,anim:animOut.count});
 window.__game={S,econ,chooseKingdom,castleSpotFor,FEUDAL,anchorOf,provAt,worldCastles,vill,check,efficiency,fracAround,classAt,computeEcon,syncVillagers,assignRoles,placeBuilding,flyTo,TYPES,byId,setView:(x,z,d,p,y)=>{target=[x,0,z];dist=d;if(p!=null)pitch=p;if(y!=null)yaw=y;fly=null},warp:(sec)=>{for(let t=0;t<sec;t+=.1)simStep(.1)},finishAll:()=>{for(const b of S.b)if(b.state==='site'||b.upg){b.prog=1;finishBuild(b)}}};
 const ld=$('loading');ld.style.opacity='0';setTimeout(()=>ld.remove(),450);
 renderMenu(true);updateHUD();requestAnimationFrame(t=>{lastT=t;frame(t)});
}catch(e){console.error(e);setLoad('Erro de inicialização: '+e.message)}})();
