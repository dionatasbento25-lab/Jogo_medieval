/* =====================================================================
   7. REGRAS DO CITY BUILDER
   ===================================================================== */
const RES=['gold','wood','stone','food'],RICON={gold:'🪙',wood:'🌲',stone:'🪨',food:'🌾'},RNAME={gold:'ouro',wood:'madeira',stone:'pedra',food:'comida'};
const DEF={
 castle:{cost:[0,0,0],unlock:1,desc:'O coração do reino. Define o território, abriga 6 aldeões, cobra impostos e envia os construtores.'},
 house:{cost:[25,35,0],unlock:1,desc:'Moradia para os aldeões. Mais casas = mais gente para trabalhar.'},
 farm:{cost:[35,30,0],unlock:1,job:'food',rate:.55,role:3,desc:'Produz comida. Rende mais em planícies e perto de rios.'},
 lumber:{cost:[30,15,0],unlock:1,job:'wood',rate:.38,role:1,desc:'Corta madeira. Precisa de floresta por perto: quanto mais mata, mais rende.'},
 well:{cost:[20,10,25],unlock:1,desc:'Água fresca deixa o povo mais feliz.'},
 quarry:{cost:[50,60,0],unlock:2,job:'stone',rate:.28,role:2,desc:'Extrai pedra. Rende mais perto das montanhas.'},
 warehouse:{cost:[60,90,20],unlock:2,desc:'Aumenta a capacidade de armazenar recursos.'},
 market:{cost:[120,90,40],unlock:2,job:'gold',rate:.3,role:0,shirt:'#8a5bc2',desc:'Comércio: gera ouro e alegra o povo.'},
 tower:{cost:[90,60,110],unlock:2,desc:'Vigia as fronteiras: o povo se sente seguro e fica mais feliz.'},
 mine:{cost:[100,80,60],unlock:3,job:'gold',rate:.26,role:2,desc:'Extrai ouro. Só funciona perto de montanhas.'},
 tavern:{cost:[160,120,80],unlock:3,job:'happy',rate:0,role:0,shirt:'#f6efe0',desc:'Cerveja e música: muita felicidade para o reino.'},
};
const CASTLE_UP=[null,[200,250,80],[600,500,350],[1500,1200,1000],[4000,3000,2500]];
const ROLE_SHIRT={1:'#c8443a',2:'#7d766b',3:'#7fb24a',4:'#ff8a3d'};
const IDLE_SHIRTS=['#4a78c4','#d9a32a','#3fa7a0','#b8577a','#7a8f3f','#9a6cc8','#d86a3a','#5b7fa8'];
const BUILD_ORDER=['house','farm','lumber','well','quarry','warehouse','market','tower','mine','tavern'];
const HEIGHT={castle:20,house:8,farm:7,lumber:5,quarry:5,mine:5,market:4,tavern:8,warehouse:6,tower:12,well:3};
const GOALS=[
 {t:'Escolha o seu reino e erga o castelo',f:()=>castleL()?1:0,n:1,r:[0,100,0]},
 {t:'Construa 2 casas',f:()=>countB('house'),n:2,r:[60,0,0]},
 {t:'Construa uma fazenda',f:()=>countB('farm'),n:1,r:[0,50,0]},
 {t:'Construa um lenhador',f:()=>countB('lumber'),n:1,r:[50,0,0]},
 {t:'Alcance 12 habitantes',f:()=>S.pop,n:12,r:[80,0,60]},
 {t:'Evolua o castelo ao nível 2',f:()=>castleL()>=2?1:0,n:1,r:[150,0,0]},
 {t:'Construa uma pedreira',f:()=>countB('quarry'),n:1,r:[0,80,0]},
 {t:'Construa um mercado',f:()=>countB('market'),n:1,r:[0,0,100]},
 {t:'Melhore uma casa ao nível 3',f:()=>S.b.some(b=>b.type==='house'&&b.level>=3)?1:0,n:1,r:[200,0,0]},
 {t:'Alcance 30 habitantes',f:()=>S.pop,n:30,r:[300,0,0]},
 {t:'Construa um armazém',f:()=>countB('warehouse'),n:1,r:[0,150,0]},
 {t:'Evolua o castelo ao nível 3',f:()=>castleL()>=3?1:0,n:1,r:[0,0,300]},
 {t:'Construa uma mina de ouro',f:()=>countB('mine'),n:1,r:[0,200,0]},
 {t:'Construa uma taverna',f:()=>countB('tavern'),n:1,r:[400,0,0]},
 {t:'Deixe o povo 85% feliz',f:()=>Math.floor(econ.hap),n:85,r:[300,300,300]},
 {t:'Alcance 60 habitantes',f:()=>S.pop,n:60,r:[800,0,0]},
 {t:'Evolua o castelo ao nível 5',f:()=>castleL()>=5?1:0,n:1,r:[2000,2000,2000]},
];
const SAVE_KEY='reinos_city_v2';
let S={res:{gold:250,wood:250,stone:150,food:80},b:[],pop:0,goal:0,castle:0,nextId:1,saved:0,growT:0,kingdom:-1};
function playerKingdom(){return S.kingdom}
const econ={rate:{gold:0,wood:0,stone:0,food:0},cap:600,popCap:0,hap:60,jobs:0,builders:2};
const byId=new Map(),occ=new Map();
const tkey=(i,j)=>(i+600)*2000+(j+600);
function countB(t){let n=0;for(const b of S.b)if(b.type===t&&b.state==='done')n++;return n}
function castleB(){return S.castle?byId.get(S.castle):null}
function castleL(){const c=castleB();return c&&c.state==='done'?c.level:0}
function costOf(type,level){if(type==='castle')return CASTLE_UP[level]||null;const k=Math.pow(1.7,level-1);return DEF[type].cost.map(c=>Math.round(c*k/5)*5)}
function canPay(c){return c&&S.res.gold>=c[0]&&S.res.wood>=c[1]&&S.res.stone>=c[2]}
function pay(c){S.res.gold-=c[0];S.res.wood-=c[1];S.res.stone-=c[2]}
function costHTML(c){return c.map((v,i)=>v?`<span class="${S.res[RES[i]]>=v?'':'lack'}">${RICON[RES[i]]}${fmt(v)}</span>`:'').join(' ')||'grátis'}
function fmt(n){n=Math.floor(n);return n>=1e4?(n/1e3).toFixed(n>=1e5?0:1)+'k':''+n}
function workTime(type,level){return TYPES[type].time*(1+.6*(level-1))}
function slotsOf(b){const d=DEF[b.type];if(!d.job||b.state!=='done')return 0;if(b.type==='tavern')return 1+Math.floor(b.level/2);return 1+b.level}

/* ---------- Território ---------- */
/* ---------- Território: as províncias do seu reino ---------- */
function ownerAt(x,z){const p=provAt(x,z);return p<0?-1:FEUDAL.prov[p][2]}
function inTerr(x,z,k){return k>=0&&ownerAt(x,z)===k}

/* ---------- Avaliação do terreno para cada construção ---------- */
function fracAround(x,z,r,set){let n=0,k=0;for(let dz=-r;dz<=r;dz+=6)for(let dx=-r;dx<=r;dx+=6){if(dx*dx+dz*dz>r*r)continue;k++;if(set.includes(classAt(x+dx,z+dz)))n++}return n/Math.max(1,k)}
function efficiency(type,x,z){
 if(type==='farm'){const c=classAt(x,z);let e=c===4?.55:c===3?.8:1;if(fracAround(x,z,26,[1])>0||fracAround(x,z,22,[0])>.05)e+=.25;return {e,need:true}}
 if(type==='lumber'){const f=fracAround(x,z,40,[3]);return {e:clamp(.25+f*2.4,.25,1.6),need:f>.03,why:'Precisa de floresta por perto'}}
 if(type==='quarry'){const f=fracAround(x,z,46,[5,6]);return {e:clamp(.35+f*2.6,.35,1.6),need:f>.02,why:'Precisa de montanhas por perto'}}
 if(type==='mine'){const f=fracAround(x,z,40,[5,6]);return {e:clamp(.45+f*2.2,.45,1.7),need:f>.07,why:'A mina precisa ficar ao pé de uma montanha'}}
 return {e:1,need:true}}
function snapPos(type,px,pz){const n=TYPES[type].size;const i0=Math.round(px/TILE-n/2),j0=Math.round(pz/TILE-n/2);return {i0,j0,x:(i0+n/2)*TILE,z:(j0+n/2)*TILE}}
function check(type,px,pz,ignoreId,owner){const K=owner==null?S.kingdom:owner;
 const n=TYPES[type].size,sp=snapPos(type,px,pz),{i0,j0,x,z}=sp,S2=n*TILE/2;
 const res={ok:false,x,z,i0,j0,why:'',e:1,y:0,minH:0};
 if(Math.abs(x)>HX-40||Math.abs(z)>HZ-40){res.why='Longe demais';return res}
 if(type==='castle'&&owner==null&&S.castle&&ignoreId!==S.castle){res.why='O reino já tem um castelo';return res}
 for(let j=j0;j<j0+n;j++)for(let i=i0;i<i0+n;i++){const o=occ.get(tkey(i,j));if(o&&o!==ignoreId){res.why='Espaço ocupado';return res}}
 let mn=1e9,mx=-1e9;const st=Math.min(4,S2);
 for(let dz=-S2;dz<=S2+.01;dz+=st)for(let dx=-S2;dx<=S2+.01;dx+=st){const xx=x+dx,zz=z+dz;if(isWater(xx,zz)){res.why='Não dá para construir na água';return res}
  const c=classAt(xx,zz);if(c===6||(c===5&&type!=='mine'&&type!=='tower')){res.why='Terreno montanhoso demais';return res}
  const h=meshH(xx,zz);mn=Math.min(mn,h);mx=Math.max(mx,h)}
 if(mx-mn>1.4+n*.4){res.why='Terreno inclinado demais';return res}
 for(const [dx,dz] of [[-1,-1],[1,-1],[1,1],[-1,1],[0,0]])if(!inTerr(x+dx*S2,z+dz*S2,K)){res.why=K<0?'Escolha um reino primeiro':'Fora das províncias do seu reino';return res}
 const ef=efficiency(type,x,z);res.e=ef.e;if(!ef.need){res.why=ef.why;return res}
 res.ok=true;res.y=mx+.15;res.minH=mn;return res}

/* ---------- Construções: criar, ocupar, remover ---------- */
function occupy(b,on){const n=TYPES[b.type].size;for(let j=b.j0;j<b.j0+n;j++)for(let i=b.i0;i<b.i0+n;i++){if(on)occ.set(tkey(i,j),b.id);else occ.delete(tkey(i,j))}tileCache.clear();treeKey=''}
function addBuilding(o){const b=Object.assign({level:1,state:'site',prog:0,upg:false,popT:0,rot:0},o);b.id=b.id||S.nextId++;S.nextId=Math.max(S.nextId,b.id+1);
 const n=TYPES[b.type].size,c=check(b.type,b.x,b.z,b.id);b.i0=c.i0;b.j0=c.j0;b.x=c.x;b.z=c.z;b.e=efficiency(b.type,b.x,b.z).e;
 // altura da base (topo do terreno sob o lote)
 let mn=1e9,mx=-1e9;const S2=n*TILE/2;for(let dz=-S2;dz<=S2+.01;dz+=2)for(let dx=-S2;dx<=S2+.01;dx+=2){const h=Math.max(meshH(b.x+dx,b.z+dz),0);mn=Math.min(mn,h);mx=Math.max(mx,h)}
 b.y=mx+.15;b.minH=mn;S.b.push(b);byId.set(b.id,b);occupy(b,true);if(b.type==='castle')S.castle=b.id;prepSpots(b);return b}
function removeBuilding(b){occupy(b,false);S.b.splice(S.b.indexOf(b),1);byId.delete(b.id);if(S.castle===b.id)S.castle=0;
 for(const v of vill){if(v.job===b.id){v.job=0;v.task=null}if(v.home===b.id){v.home=0}if(v.site===b.id){v.site=0;v.task=null}}staticDirty=true;terrDirty=true}
function toWorld(b,lx,lz){const a=b.rot*Math.PI/2,c=Math.cos(a),s=Math.sin(a);return [b.x+lx*c+lz*s,b.z-lx*s+lz*c]}
function doorOf(b){const S2=TYPES[b.type].size*TILE/2;return toWorld(b,b.type==='castle'?0:-.3,S2+.9)}
// Pontos de trabalho de cada construção (onde os aldeões colhem / cortam / quebram pedra)
function prepSpots(b){const sp=[];const T=b.type;
 if(T==='farm'){for(let k=0;k<14;k++){const lx=-7.5+hash2(b.id,k)*8.5+(b.level>=3?1:0),lz=-6+hash2(k,b.id)*7;sp.push(toWorld(b,lx,lz))}}
 else if(T==='lumber'||T==='quarry'||T==='mine'){const set=T==='lumber'?[3]:[5,6],R=T==='lumber'?40:46;
  for(let dz=-R;dz<=R;dz+=5)for(let dx=-R;dx<=R;dx+=5){const x=b.x+dx,z=b.z+dz,d=Math.hypot(dx,dz);if(d>R||d<12)continue;if(!set.includes(classAt(x,z))||isWater(x,z))continue;if(occ.get(tkey(Math.floor(x/TILE),Math.floor(z/TILE))))continue;
   if(T!=='lumber'&&meshH(x,z)>b.y+14)continue;sp.push([x,z,d])}
  sp.sort((a,c)=>a[2]-c[2]);sp.length=Math.min(sp.length,24);
  if(T!=='lumber')for(const [lx,lz] of [[-1.8,-1.2],[-3.2,.2],[0,2.6],[-1,-4.4]])sp.push(toWorld(b,lx,lz));
  if(!sp.length)for(let k=0;k<6;k++){const a=k/6*Math.PI*2;sp.push([b.x+Math.cos(a)*9,b.z+Math.sin(a)*9])}}
 else{const S2=TYPES[T].size*TILE/2;for(let k=0;k<8;k++){const a=k/8*Math.PI*2;sp.push([b.x+Math.cos(a)*(S2+1.2),b.z+Math.sin(a)*(S2+1.2)])}}
 b.spots=sp}

/* ---------- Economia (chamada várias vezes por segundo) ---------- */
function computeEcon(){
 const cl=castleL();let cap=600+400*Math.max(0,cl-1),popCap=0,hap=55;
 for(const b of S.b){if(b.state!=='done')continue;const L=b.level;
  if(b.type==='castle')popCap+=6;if(b.type==='house')popCap+=4+2*(L-1);if(b.type==='warehouse')cap+=500*L;
  if(b.type==='well')hap+=3+2*L;if(b.type==='market')hap+=2*L;if(b.type==='tavern')hap+=8+5*L;if(b.type==='tower')hap+=2+2*L;if(b.type==='house'&&L>=4)hap+=1}
 if(S.res.food<=0)hap-=35;if(S.pop>popCap)hap-=10;
 econ.hap=clamp(hap,0,100);econ.cap=cap;econ.popCap=popCap;econ.builders=1+Math.max(1,cl);
 // distribuição de trabalho: um aldeão por vez em cada posto (rodízio), comida primeiro se faltar
 const posts=S.b.filter(b=>slotsOf(b)>0);const need=S.res.food<40||econ.rate.food<0;
 posts.sort((a,c)=>(need?(a.type==='farm'?0:1)-(c.type==='farm'?0:1):0)||a.id-c.id);
 for(const b of posts)b.workers=0;let free=S.pop,any=true;
 while(free>0&&any){any=false;for(const b of posts){if(free<=0)break;if(b.workers<slotsOf(b)){b.workers++;free--;any=true}}}
 econ.jobs=S.pop-free;econ.idle=free;
 const hf=.75+.5*econ.hap/100,r={gold:.4+.25*Math.max(0,cl-1)+.025*S.pop,wood:0,stone:0,food:-.11*S.pop};
 if(!cl)r.gold=0;
 for(const b of posts){const d=DEF[b.type];if(!d.job||d.job==='happy')continue;b.rate=d.rate*(1+.35*(b.level-1))*b.e*hf;r[d.job]+=b.rate*b.workers}
 econ.rate=r}
function simEcon(dt){for(const k of RES){S.res[k]=clamp(S.res[k]+econ.rate[k]*dt,0,econ.cap)}
 // crescimento da população
 if(castleL()&&S.pop<econ.popCap&&S.res.food>3){S.growT+=dt*(.45+econ.hap/100);if(S.growT>=5){S.growT=0;S.pop++;spawnVillager(false);computeEcon()}}
 if(S.pop>econ.popCap){S.pop=econ.popCap;trimVillagers()}}

/* =====================================================================
   8. ALDEÕES — cada um com casa, trabalho e rotina própria
   ===================================================================== */
const vill=[];let vSeq=1;const MAXV=MOBILE?160:260;
function spawnVillager(builder,at){const c=castleB();const p=at||(c?doorOf(c):[0,0]);
 const v={id:vSeq++,x:p[0]+(Math.random()-.5)*2,z:p[1]+(Math.random()-.5)*2,yaw:0,ph:Math.random()*6,mode:0,role:builder?4:0,carry:0,builder,job:0,home:0,site:0,task:null,hidden:false,
  shirt:hex(builder?ROLE_SHIRT[4]:IDLE_SHIRTS[(vSeq*5)%IDLE_SHIRTS.length]),hair:Math.random(),trips:0,side:Math.random()<.5?1:-1,speed:2.6+Math.random()*.7};
 vill.push(v);return v}
function trimVillagers(){let n=vill.filter(v=>!v.builder).length;for(let i=vill.length-1;i>=0&&n>S.pop;i--)if(!vill[i].builder){vill.splice(i,1);n--}}
function syncVillagers(){// garante 1 boneco por habitante (até o limite visual) e o número certo de construtores
 let civ=vill.filter(v=>!v.builder).length;while(civ<Math.min(S.pop,MAXV)){spawnVillager(false);civ++}trimVillagers();
 let bl=vill.filter(v=>v.builder).length;const want=castleB()?econ.builders:0;
 while(bl<want){spawnVillager(true);bl++}while(bl>want){const i=vill.findIndex(v=>v.builder);vill.splice(i,1);bl--}}
function assignRoles(){// casa e emprego para cada aldeão
 const houses=[];for(const b of S.b)if(b.state==='done'&&(b.type==='house'||b.type==='castle')){const cap=b.type==='castle'?6:4+2*(b.level-1);houses.push({b,cap,n:0})}
 const hm=new Map(houses.map(h=>[h.b.id,h]));const civs=vill.filter(v=>!v.builder);
 for(const v of civs){if(v.home){const h=hm.get(v.home);if(h&&h.n<h.cap)h.n++;else v.home=0}}
 for(const v of civs)if(!v.home){const h=houses.find(h=>h.n<h.cap);if(h){h.n++;v.home=h.b.id}}
 const want=new Map();for(const b of S.b)if(b.workers)want.set(b.id,b.workers);
 for(const v of civs){if(v.job){const n=want.get(v.job)||0;if(n>0)want.set(v.job,n-1);else{v.job=0;v.task=null}}}
 for(const v of civs)if(!v.job){for(const [id,n] of want)if(n>0){v.job=id;want.set(id,n-1);v.task=null;v.trips=0;break}}
 for(const v of civs){const b=byId.get(v.job),d=b&&DEF[b.type];v.role=d?d.role:0;const sc=d?(d.shirt||ROLE_SHIRT[d.role]):null;v.shirt=hex(sc||IDLE_SHIRTS[v.id%IDLE_SHIRTS.length])}}
function pick(arr){return arr[(Math.random()*arr.length)|0]}
function goTo(v,x,z,then,stopAt){v.task={k:'walk',x,z,then,stop:stopAt||0};v.mode=1}
function wanderNear(v,x,z,r){const a=Math.random()*6.283,d=r*.4+Math.random()*r;goTo(v,x+Math.cos(a)*d,z+Math.sin(a)*d,{k:'idle',t:1.5+Math.random()*3})}
function think(v){
 const c=castleB();if(!c){v.task={k:'idle',t:1};return}
 if(v.builder){
  if(v.site&&!byId.get(v.site))v.site=0;
  if(!v.site){// procura o canteiro com menos construtores
   let best=null,bn=1e9;for(const b of S.b){if(!(b.state==='site'||b.upg))continue;if(b.type==='castle'&&b.state==='site'&&false)continue;const n=vill.filter(u=>u.site===b.id).length;if(n<bn){bn=n;best=b}}
   if(best)v.site=best.id}
  if(v.site){const b=byId.get(v.site),S2=TYPES[b.type].size*TILE/2,a=Math.random()*6.283;const r=S2*.95;
   goTo(v,b.x+Math.cos(a)*r,b.z+Math.sin(a)*r,{k:'build',t:3+Math.random()*2,face:[b.x,b.z]});return}
  const d=doorOf(c);wanderNear(v,d[0],d[1],6);return}
 const job=byId.get(v.job),home=byId.get(v.home);
 if(job&&job.state==='done'){
  const T=job.type,d=doorOf(job);
  if(v.trips>=3&&home&&Math.random()<.6){v.trips=0;const hd=doorOf(home);goTo(v,hd[0],hd[1],{k:'rest',t:4+Math.random()*4});return}
  if(T==='farm'||T==='lumber'||T==='quarry'||T==='mine'){const s=pick(job.spots);
   goTo(v,s[0],s[1],{k:'work',t:3.5+Math.random()*2.5,after:{k:'carry',to:job.id,item:T==='lumber'?1:T==='quarry'?2:T==='farm'?3:4}});return}
  // mercado / taverna: atende no local
  const s=pick(job.spots);goTo(v,s[0],s[1],{k:'idle',t:4+Math.random()*5,face:[job.x,job.z]});v.trips+=.5;return}
 // desocupado: passeia pela vila ou descansa em casa
 if(home&&Math.random()<.25){const hd=doorOf(home);goTo(v,hd[0],hd[1],{k:'rest',t:5+Math.random()*6});return}
 const hub=pick(S.b.filter(b=>b.state==='done'&&(b.type==='market'||b.type==='well'||b.type==='castle'||b.type==='tavern')))||c;const hd=doorOf(hub);wanderNear(v,hd[0],hd[1],7)}
function startTask(v,t){v.task=t;v.mode=0;
 if(t.k==='work'){v.mode=2;v.t0=t.t;if(t.face)v.yaw=Math.atan2(t.face[0]-v.x,t.face[1]-v.z)}
 if(t.k==='build'){v.mode=2;if(t.face)v.yaw=Math.atan2(t.face[0]-v.x,t.face[1]-v.z)}
 if(t.k==='idle'&&t.face)v.yaw=Math.atan2(t.face[0]-v.x,t.face[1]-v.z);
 if(t.k==='rest')v.hidden=true;
 if(t.k==='carry'){const b=byId.get(t.to);if(!b){v.task=null;return}v.carry=t.item;const d=doorOf(b);goTo(v,d[0],d[1],{k:'deliver',to:b.id})}}
function blockedAt(x,z,v){const id=occ.get(tkey(Math.floor(x/TILE),Math.floor(z/TILE)));if(!id)return false;const t=v.task&&v.task.goal;return id!==t}
function stepVillager(v,dt){
 if(!v.task){think(v);if(v.task&&v.task.k!=='walk')startTask(v,v.task)}
 const t=v.task;if(!t)return;
 if(t.k==='walk'){
  const dx=t.x-v.x,dz=t.z-v.z,d=Math.hypot(dx,dz);
  if(d<.35){v.mode=0;startTask(v,t.then);return}
  let ux=dx/d,uz=dz/d;const sp=v.speed*dt;
  // desvia de construções que estejam no caminho (exceto a de destino)
  const goal=occ.get(tkey(Math.floor(t.x/TILE),Math.floor(t.z/TILE)));
  const hit=(x,z)=>{const id=occ.get(tkey(Math.floor(x/TILE),Math.floor(z/TILE)));return id&&id!==goal&&id!==v.from};
  if(hit(v.x+ux*1.6,v.z+uz*1.6)){for(const a of [.9,1.5,2.2]){const ca=Math.cos(a*v.side),sa=Math.sin(a*v.side),nx=ux*ca-uz*sa,nz=ux*sa+uz*ca;if(!hit(v.x+nx*1.6,v.z+nz*1.6)){ux=nx;uz=nz;break}}}
  v.x+=ux*Math.min(sp,d);v.z+=uz*Math.min(sp,d);
  let ty=Math.atan2(ux,uz),dy=ty-v.yaw;while(dy>Math.PI)dy-=6.283;while(dy<-Math.PI)dy+=6.283;v.yaw+=dy*Math.min(1,dt*10);
  v.ph+=sp*2.7;v.mode=1;if(!t.life)t.life=0;t.life+=dt;if(t.life>40){v.task=null}return}
 v.ph+=dt*(v.mode===2?4.2:2);
 t.t-=dt;
 if(t.k==='build'){const b=byId.get(v.site);if(!b||!(b.state==='site'||b.upg)){v.task=null;v.site=0;v.mode=0;return}
  if(Math.random()<dt*1.2)spark(v.x+Math.sin(v.yaw)*.8,v.z+Math.cos(v.yaw)*.8);
  if(t.t<=0)v.task=null;return}
 if(t.t>0)return;
 v.hidden=false;
 if(t.k==='work'){startTask(v,t.after);return}
 if(t.k==='deliver'){const b=byId.get(t.to);if(b){const d=DEF[b.type];const amt=(b.rate||0)*(v.t0||4)*2.4;if(amt>0&&isNear(b.x,b.z,280))floatText(b.x,b.y+(HEIGHT[b.type]||5)*.7,b.z,'+'+Math.max(1,Math.round(amt))+' '+RICON[d.job])}
  v.carry=0;v.trips++;v.from=t.to;v.task=null;return}
 v.from=0;v.task=null}
function isNear(x,z,r){return Math.hypot(x-target[0],z-target[2])<r+dist*.6}

/* ---------- Construção e melhorias ---------- */
function simBuild(dt){
 for(const b of S.b){
  if(b.popT>0){b.popT-=dt;if(b.popT<=0){b.popT=0;staticDirty=true}}
  if(!(b.state==='site'||b.upg))continue;
  const here=vill.filter(v=>v.builder&&v.site===b.id&&v.task&&v.task.k==='build').length;
  const solo=b.type==='castle'&&b.state==='site';// o primeiro castelo se ergue mesmo sem construtores
  const rate=(here+(solo?1:0))/b.work;b.prog=Math.min(1,b.prog+rate*dt);
  if(b.prog>=1)finishBuild(b)}}
function finishBuild(b){const wasSite=b.state==='site';b.state='done';b.prog=0;if(b.upg){b.level++;b.upg=false}b.popT=.55;
 b.e=efficiency(b.type,b.x,b.z).e;prepSpots(b);staticDirty=true;terrDirty=true;
 for(const v of vill)if(v.site===b.id){v.site=0;v.task=null}
 toast(`${TYPES[b.type].icon} ${TYPES[b.type].name} ${wasSite?'construída!':'melhorada para o nível '+b.level+'!'}`);
 if(b.type==='castle'&&wasSite){toast('🏰 O reino foi fundado! Construa casas e fazendas.');}
 confetti(b);computeEcon();syncVillagers();assignRoles();refreshPanel();save()}
function placeBuilding(type,c,rot){const cost=type==='castle'?[0,0,0]:costOf(type,1);if(!canPay(cost)){toast('Recursos insuficientes');return null}
 pay(cost);const b=addBuilding({type,x:c.x,z:c.z,rot});b.work=workTime(type,1);
 if(type==='castle'){toast('🏰 O castelo está sendo erguido…');}
 terrDirty=true;computeEcon();syncVillagers();save();return b}
function upgradeBuilding(b){if(b.state!=='done'||b.upg)return;const T=TYPES[b.type];if(b.level>=T.max){toast('Nível máximo');return}
 const c=costOf(b.type,b.level+(b.type==='castle'?0:1));if(b.type!=='castle'&&b.level>=castleL()+1&&b.type!=='well'){toast('Evolua o castelo primeiro');return}
 if(Math.max(...c)>econ.cap){toast('Capacidade insuficiente — construa Armazéns 📦');return}
 if(!canPay(c)){toast('Recursos insuficientes');return}pay(c);b.upg=true;b.prog=0;b.work=workTime(b.type,b.level+1);toast('🔨 Melhoria iniciada');refreshPanel();save()}
function demolish(b){if(b.type==='castle'){toast('O castelo não pode ser demolido');return}const c=costOf(b.type,b.level);
 for(let i=0;i<3;i++)S.res[RES[i]]+=Math.round(c[i]*.5);removeBuilding(b);toast('🗑 Demolido (50% devolvido)');selected=0;closeInfo();computeEcon();syncVillagers();assignRoles();save()}

/* =====================================================================
   9. EFEITOS ANIMADOS (moinhos, bandeiras, fumaça, canteiros)
   ===================================================================== */
const geoBlade=makeGeo(()=>{cyl(0,-.2,0,.3,.4,'#6b5137',8);for(let k=0;k<4;k++){const a=k*Math.PI/2,c=Math.cos(a),s=Math.sin(a);
 // pá: armação + lona, no plano XY
 const P=(r,w)=>[c*r-s*w,s*r+c*w,0];quad(P(.3,-.12),P(3.2,-.12),P(3.2,.12),P(.3,.12),hex('#6b5137'));quad(P(.9,.12),P(3.1,.12),P(3.1,.85),P(.9,.85),hex(k%2?'#f6efe0':'#e6dcc4'))}});
const geoFlag=makeGeo(()=>{box(.65,0,0,1.3,.75,.05,'#2f5fb8');box(.7,.22,.03,.36,.32,.03,'#ffd34d')});
const geoPuff=makeGeo(()=>{ball(0,0,0,.5,'#f4f1ea',1,3,6,false)});
const geoCraneArm=makeGeo(()=>{box(1.4,0,0,3.6,.22,.22,'#7a5232');box(3,-.9,0,.05,1.0,.05,'#3a2a1c');bbox(3,-1.4,0,.55,.5,.55,'#b9b6ad',.06)});
const geoSpark=makeGeo(()=>{box(0,0,0,.18,.18,.18,'#ffd34d')});
const geoConf=['#ff5d73','#ffd23f','#4fb3ff','#7cc35a','#b56cff'].map(c=>makeGeo(()=>box(0,0,0,.32,.06,.22,c)));
const plotGeo=new Map(),siteGeo=new Map(),scafGeo=new Map(),foundGeo=new Map();
function cached(map,key,fn){let g=map.get(key);if(!g){g=makeGeo(fn);map.set(key,g)}return g}
function fxOf(b){const L=b.level,T=b.type,o={flags:[],smoke:[],mill:[],crane:[]};
 if(T==='castle'){const R=9.5,tH=6.5+L*.5;for(const a of [-1,1])for(const c of [-1,1])o.flags.push([a*R,.6+tH+3.7,c*R]);o.flags.push([0,.6+7.5+L*1.1+.7+3.5,-1.2])}
 if(T==='tower')o.flags.push([0,6.5+L*.9+4.1,0]);
 if(T==='house'){const top=(L>=5?1:0)+(L>=3?2.2+1.9:2.5);if(L>=2)o.smoke.push([1.1,top+2.6,-1.0]);if(L>=5)o.flags.push([2.9,3.5,-2.9])}
 if(T==='tavern'){o.smoke.push([-2,7.7,-2]);if(L>=5)o.flags.push([-4.4,4.3,-3.6])}
 if(T==='lumber')o.smoke.push([.1,4.2,-2.0]);
 if(T==='farm'&&L>=2)o.mill.push([-5.6,4.7,5.75]);
 if(T==='quarry'&&L>=2)o.crane.push([3.8,4.2,2.2]);
 if(T==='market'&&L>=5){o.flags.push([-5,4.0,-5]);o.flags.push([5,4.0,-5])}
 if(T==='mine'&&L>=5)o.flags.push([-1.8,4.9,-.4]);
 return o}
function lpos(b,p){const w=toWorld(b,p[0],p[2]);return [w[0],b.y+p[1],w[1]]}
const sparks=[],confs=[];
function spark(x,z){if(sparks.length>60)return;sparks.push({x,y:ground(x,z)+.9,z,vx:(Math.random()-.5)*2,vy:2+Math.random()*2,vz:(Math.random()-.5)*2,t:.5})}
function confetti(b){if(!isNear(b.x,b.z,300))return;for(let k=0;k<40;k++)confs.push({x:b.x,y:b.y+(HEIGHT[b.type]||6)*.8,z:b.z,vx:(Math.random()-.5)*9,vy:4+Math.random()*6,vz:(Math.random()-.5)*9,t:1.6+Math.random(),r:Math.random()*6,c:k%5})}
const staticOut=new Out(1<<15),animOut=new Out(1<<14),ghostOut=new Out(1<<13);
const worldOut=new Out(1<<16),strOut=new Out(1<<10);
/* ---------- Estreitos: linha pontilhada sobre a água (do mapa original) ---------- */
function buildStraits(){const FW=FEUDAL.frame[0],FH=FEUDAL.frame[1],cream=[.97,.91,.74],dark=[.24,.17,.09];
 const g=makeGeo(()=>{for(const sg of FEUDAL.straits){let ax=sg[0]/FW*WX-HX,az=sg[1]/FH*WZ-HZ,bx=sg[2]/FW*WX-HX,bz=sg[3]/FH*WZ-HZ;
  let dx=bx-ax,dz=bz-az,L=Math.hypot(dx,dz)||1;const ux=dx/L,uz=dz/L,ext=Math.max(4,(12-L)/2+3);ax-=ux*ext;az-=uz*ext;bx+=ux*ext;bz+=uz*ext;L+=2*ext;
  const px=-uz,pz=ux,DASH=2.6,GAP=1.8;
  for(let t=0;t<L;t+=DASH+GAP){const t1=Math.min(t+DASH,L),x0=ax+ux*t,z0=az+uz*t,x1=ax+ux*t1,z1=az+uz*t1;
   const y0=Math.max(meshH(x0,z0),0)+.5,y1=Math.max(meshH(x1,z1),0)+.5;
   for(const [w,c,dy] of [[1.9,dark,0],[1.05,cream,.06]])quad([x0-px*w,y0+dy,z0-pz*w],[x0+px*w,y0+dy,z0+pz*w],[x1+px*w,y1+dy,z1+pz*w],[x1-px*w,y1+dy,z1-pz*w],c)}}});
 strOut.reset();strOut.stamp(g,0,0,0);strOut.upload();meshVer++}
/* ---------- Castelos dos outros 60 reinos, na capital de cada um ---------- */
const worldCastles=[];
function findSpot(type,x0,z0,owner,maxR=90){for(let r=0;r<=maxR;r+=4){const n=r?Math.max(8,Math.round(r*1.2)):1;for(let k=0;k<n;k++){const a=k/n*Math.PI*2;const c=check(type,x0+Math.cos(a)*r,z0+Math.sin(a)*r,0,owner);if(c.ok)return c}}return null}
function castleSpotFor(h){const fh=FEUDAL.houses[h],seat=anchorOf(fh.seat);let c=findSpot('castle',seat.x,seat.z,h,140);if(c)return c;
 for(let i=0;i<NP&&!c;i++)if(FEUDAL.prov[i][2]===h){const a=anchorOf(i);c=findSpot('castle',a.x,a.z,h,100)}return c}
function buildWorldCastles(){for(const w of worldCastles)if(w.tiles)for(const t of w.tiles)occ.delete(t);worldCastles.length=0;worldOut.reset();
 FEUDAL.houses.forEach((h,i)=>{if(i===S.kingdom)return;const c=castleSpotFor(i);if(!c)return;
  const L=clamp(1+Math.floor(h.n/4),1,4),n=TYPES.castle.size,b={type:'castle',x:c.x,z:c.z,y:c.y,minH:c.minH,rot:(i*7)%4,level:L,house:i,tiles:[]};
  for(let j=c.j0;j<c.j0+n;j++)for(let q=c.i0;q<c.i0+n;q++){const t=tkey(q,j);occ.set(t,-1-i);b.tiles.push(t)}
  stampFoundation(worldOut,b);stampBuilding(worldOut,b,getModel('castle',L));worldCastles.push(b)});
 worldOut.upload();tileCache.clear();treeKey='';shadowDirty=true;meshVer++}
let staticDirty=true,terrDirty=true;
function stampBuilding(out,b,model,sy=1,sxz=1,tint=1){const a=b.rot*Math.PI/2;out.stamp(model,b.x,b.y,b.z,a,sxz,sy,sxz,tint)}
function stampFoundation(out,b){const n=TYPES[b.type].size*TILE,dep=b.y-b.minH+.6;out.stamp(cached(foundGeo,n,()=>box(0,0,0,n-.3,1,n-.3,'#8a9a5a')),b.x,b.y-dep-.05,b.z,0,1,dep,1)}
function rebuildStatic(){staticOut.reset();for(const b of S.b){if(b.state!=='done'||b.popT>0)continue;stampFoundation(staticOut,b);stampBuilding(staticOut,b,getModel(b.type,b.level))}
 staticOut.upload();staticDirty=false;shadowDirty=true;meshVer++}
function rebuildAnim(t,dt){animOut.reset();const near=dist<700;
 for(const b of S.b){const n=TYPES[b.type].size*TILE,vis=isNear(b.x,b.z,260);
  if(b.state==='site'){stampFoundation(animOut,b);animOut.stamp(cached(plotGeo,b.type,()=>mPlot(n,TYPES[b.type].plot)),b.x,b.y,b.z,b.rot*Math.PI/2);
   animOut.stamp(cached(siteGeo,n,()=>mSite(n)),b.x,b.y,b.z);const sy=Math.max(.03,b.prog);stampBuilding(animOut,b,getModel(b.type,1),sy);
   if(b.prog<.97)animOut.stamp(cached(scafGeo,b.type,()=>mScaffold(n-.6,HEIGHT[b.type]*.75)),b.x,b.y,b.z,0,1,Math.max(.15,Math.min(1,b.prog*1.4)),1);continue}
  if(b.popT>0){const k=1-b.popT/.55,sq=1+Math.sin(k*Math.PI*2.5)*.12*(1-k);stampFoundation(animOut,b);stampBuilding(animOut,b,getModel(b.type,b.level),1/sq,sq)}
  if(b.upg)animOut.stamp(cached(scafGeo,b.type+'u',()=>mScaffold(n-.2,HEIGHT[b.type]*.9)),b.x,b.y,b.z,0,1,.3+.7*b.prog,1);
  if(!near||!vis||b.state!=='done')continue;
  const fx=fxOf(b),a=b.rot*Math.PI/2;
  for(const p of fx.mill){const w=lpos(b,p);const th=t*1.4+b.id;animStampMat(geoBlade,rotYZ(a,th),w)}
  for(const p of fx.flags){const w=lpos(b,p);animOut.stamp(geoFlag,w[0],w[1]-.75,w[2],a+Math.sin(t*2.2+b.id+p[0])*.45+.6,1,1,1)}
  for(const p of fx.crane){const w=lpos(b,p);animOut.stamp(geoCraneArm,w[0],w[1],w[2],a+Math.sin(t*.4+b.id)*1.2)}
  for(const p of fx.smoke){const w=lpos(b,p);for(let k=0;k<4;k++){const u=(t*.32+k/4+b.id*.13)%1,s=.35+u*.9;animOut.stamp(geoPuff,w[0]+u*1.4,w[1]+u*3.2,w[2]+u*.5,0,s*(1-u*.4),s*(1-u*.4),s*(1-u*.4),.92+u*.1)}}}
 for(let i=sparks.length-1;i>=0;i--){const s=sparks[i];s.t-=dt;if(s.t<=0){sparks.splice(i,1);continue}s.vy-=9*dt;s.x+=s.vx*dt;s.y+=s.vy*dt;s.z+=s.vz*dt;animOut.stamp(geoSpark,s.x,s.y,s.z,0,s.t*2,s.t*2,s.t*2)}
 for(let i=confs.length-1;i>=0;i--){const s=confs[i];s.t-=dt;if(s.t<=0){confs.splice(i,1);continue}s.vy-=7*dt;s.vx*=.98;s.vz*=.98;s.x+=s.vx*dt;s.y=Math.max(s.y+s.vy*dt,ground(s.x,s.z)+.05);s.z+=s.vz*dt;s.r+=dt*8;animOut.stamp(geoConf[s.c],s.x,s.y,s.z,s.r)}
 animOut.upload()}
// rotação: primeiro em torno de Z (pás do moinho), depois o giro da construção em Y
function rotYZ(yaw,th){const cy=Math.cos(yaw),sy=Math.sin(yaw),cz=Math.cos(th),sz=Math.sin(th);// M = Ry * Rz
 return [cy*cz,-cy*sz,sy, sz,cz,0, -sy*cz,sy*sz,cy]}
function animStampMat(m,M,t){const out=animOut,N=m.count;out.grow(N);const P=m.p,Cc=m.c,Nn=m.n;let o=out.k*3;
 for(let i=0;i<N*3;i+=3,o+=3){const x=P[i],y=P[i+1],z=P[i+2];out.p[o]=t[0]+M[0]*x+M[1]*y+M[2]*z;out.p[o+1]=t[1]+M[3]*x+M[4]*y+M[5]*z;out.p[o+2]=t[2]+M[6]*x+M[7]*y+M[8]*z;
  out.c[o]=Cc[i];out.c[o+1]=Cc[i+1];out.c[o+2]=Cc[i+2];const a=Nn[i],b2=Nn[i+1],c=Nn[i+2];out.n[o]=M[0]*a+M[1]*b2+M[2]*c;out.n[o+1]=M[3]*a+M[4]*b2+M[5]*c;out.n[o+2]=M[6]*a+M[7]*b2+M[8]*c}out.k+=N}

/* ---------- Instâncias dos aldeões ---------- */
let vGeoMesh=null,vInstBuf=null,vInstData=new Float32Array(12*64),vCount=0,blobBuf=null;
function buildVillagerMesh(){if(!INST)return;const g=villagerGeo();vGeoMesh={p:gl.createBuffer(),c:gl.createBuffer(),n:gl.createBuffer(),a:gl.createBuffer(),count:g.count};
 for(const [b,arr] of [[vGeoMesh.p,g.p],[vGeoMesh.c,g.c],[vGeoMesh.n,g.n],[vGeoMesh.a,g.a]]){gl.bindBuffer(gl.ARRAY_BUFFER,b);gl.bufferData(gl.ARRAY_BUFFER,new Float32Array(arr),gl.STATIC_DRAW)}
 vInstBuf=gl.createBuffer();blobBuf=gl.createBuffer();gl.bindBuffer(gl.ARRAY_BUFFER,blobBuf);gl.bufferData(gl.ARRAY_BUFFER,new Float32Array([-1,0,-1,1,0,-1,1,0,1,-1,0,-1,1,0,1,-1,0,1]),gl.STATIC_DRAW)}
function villagerY(v){const id=occ.get(tkey(Math.floor(v.x/TILE),Math.floor(v.z/TILE)));if(id){const b=byId.get(id);if(b)return b.y+.2}return Math.max(meshH(v.x,v.z),0)+.02}
function uploadVillagers(){vCount=0;if(!INST||dist>650)return;if(vInstData.length<vill.length*12)vInstData=new Float32Array(vill.length*24);
 const R=dist*2.2+120;let o=0;for(const v of vill){if(v.hidden)continue;if(Math.abs(v.x-target[0])>R||Math.abs(v.z-target[2])>R)continue;
  vInstData[o]=v.x;vInstData[o+1]=villagerY(v);vInstData[o+2]=v.z;vInstData[o+3]=v.yaw;vInstData[o+4]=v.ph;vInstData[o+5]=v.mode;vInstData[o+6]=v.role;vInstData[o+7]=v.carry;
  vInstData[o+8]=v.shirt[0];vInstData[o+9]=v.shirt[1];vInstData[o+10]=v.shirt[2];vInstData[o+11]=v.hair;o+=12;vCount++}
 gl.bindBuffer(gl.ARRAY_BUFFER,vInstBuf);gl.bufferData(gl.ARRAY_BUFFER,vInstData.subarray(0,o),gl.DYNAMIC_DRAW)}
