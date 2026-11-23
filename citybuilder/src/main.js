/* =====================================================================
   10. ÁRVORES PERTO DA CÂMERA (sem nascer dentro das construções)
   ===================================================================== */
const TREE_DIST=430,TTILE=48,TREE_CAP=MOBILE?9000:18000,TREE_R_MAX=MOBILE?380:520;
const treeBufD=gl.createBuffer(),treeBufC=gl.createBuffer();let treeNd=0,treeNc=0,treeKey='',treeVer=0;const tileCache=new Map(),extraTrees=[];
function occNear(x,z){for(const [dx,dz] of [[0,0],[-3.4,-3.4],[3.4,-3.4],[3.4,3.4],[-3.4,3.4],[0,3.6],[0,-3.6],[3.6,0],[-3.6,0]])if(occ.get(tkey(Math.floor((x+dx)/TILE),Math.floor((z+dz)/TILE))))return true;return false}
function tileTrees(ti,tj){const key=ti+','+tj;let t=tileCache.get(key);if(t)return t;
 let s=((ti*73856093)^(tj*19349663)^0x5bd1e995)>>>0;const r=()=>{s=(s*1664525+1013904223)>>>0;return s/4294967296};const d=[],c=[];
 for(let k=0;k<170;k++){const x=(ti+r())*TTILE,z=(tj+r())*TTILE;if(Math.abs(x)>HX-4||Math.abs(z)>HZ-4){r();continue}
  const cl=classAt(x,z);let p=0,coni=.5;
  if(cl===3)p=.82;else if(cl===2)p=.03;else if(cl===5){p=htF(x,z)<48?.13:0;coni=.95}else if(cl===4)p=.004;
  if(r()>p)continue;const y=meshH(x,z);if(y<.4)continue;const sc=.75+r()*.6,rot=r()*6.283,tn=.82+r()*.32,isC=r()<coni;if(occNear(x,z))continue;(isC?c:d).push(x,y-.2,z,sc,rot,tn)}
 t={d,c};if(tileCache.size>2500)tileCache.clear();tileCache.set(key,t);return t}
function updateTrees(){
 if(!INST||dist>TREE_DIST){if(treeNd||treeNc){treeNd=treeNc=0;treeVer++;shadowDirty=true;treeKey=''}return}
 const R=clamp(dist*1.9+60,140,TREE_R_MAX),fl=Math.hypot(forward[0],forward[2])||1,cx=target[0]+forward[0]/fl*R*.35,cz=target[2]+forward[2]/fl*R*.35;
 const ci=Math.round(cx/TTILE),cj=Math.round(cz/TTILE),Rk=Math.round(R/40),key=ci+'|'+cj+'|'+Rk+'|'+extraTrees.length;if(key===treeKey)return;treeKey=key;
 const n=Math.ceil(R/TTILE),list=[];for(let j=-n;j<=n;j++)for(let i=-n;i<=n;i++){const dd=Math.hypot(i,j)*TTILE;if(dd<=R+TTILE*.7)list.push([dd,ci+i,cj+j])}list.sort((a,b)=>a[0]-b[0]);
 const D=[],Cn=[];for(const t of extraTrees)(t[6]?Cn:D).push(...t.slice(0,6));
 for(const [,i,j] of list){if((D.length+Cn.length)/6>=TREE_CAP)break;const t=tileTrees(i,j);for(let k=0;k<t.d.length;k++)D.push(t.d[k]);for(let k=0;k<t.c.length;k++)Cn.push(t.c[k])}
 gl.bindBuffer(gl.ARRAY_BUFFER,treeBufD);gl.bufferData(gl.ARRAY_BUFFER,new Float32Array(D),gl.DYNAMIC_DRAW);gl.bindBuffer(gl.ARRAY_BUFFER,treeBufC);gl.bufferData(gl.ARRAY_BUFFER,new Float32Array(Cn),gl.DYNAMIC_DRAW);
 treeNd=D.length/6;treeNc=Cn.length/6;treeVer++;shadowDirty=true}
function bindModel(m){for(let [b,a] of [[m.p,0],[m.c,1],[m.n,2]]){gl.bindBuffer(gl.ARRAY_BUFFER,b);gl.enableVertexAttribArray(a);gl.vertexAttribPointer(a,3,gl.FLOAT,false,0,0)}}
function drawTrees(depthOnly){if(!INST||!(treeNd+treeNc))return;
 for(const [m,buf,n] of [[treeDec,treeBufD,treeNd],[treeCon,treeBufC,treeNc]]){if(!n)continue;
  if(depthOnly){gl.bindBuffer(gl.ARRAY_BUFFER,m.p);gl.enableVertexAttribArray(0);gl.vertexAttribPointer(0,3,gl.FLOAT,false,0,0)}else bindModel(m);
  gl.bindBuffer(gl.ARRAY_BUFFER,buf);gl.enableVertexAttribArray(3);gl.vertexAttribPointer(3,4,gl.FLOAT,false,24,0);gl.enableVertexAttribArray(4);gl.vertexAttribPointer(4,2,gl.FLOAT,false,24,16);
  INST.vertexAttribDivisorANGLE(3,1);INST.vertexAttribDivisorANGLE(4,1);INST.drawArraysInstancedANGLE(gl.TRIANGLES,0,m.count,n)}
 INST.vertexAttribDivisorANGLE(3,0);INST.vertexAttribDivisorANGLE(4,0);gl.disableVertexAttribArray(3);gl.disableVertexAttribArray(4)}

/* =====================================================================
   11. CÂMERA, SOMBRAS E DESENHO
   ===================================================================== */
function sub(a,b){return a.map((v,i)=>v-b[i])}function cross(a,b){return [a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]]}function norm(a){let d=Math.hypot(...a);return a.map(v=>v/(d||1))}function dot(a,b){return a.reduce((s,x,i)=>s+x*b[i],0)}function mul(a,b){let m=new Array(16).fill(0);for(let c=0;c<4;c++)for(let r=0;r<4;r++)for(let k=0;k<4;k++)m[c*4+r]+=a[k*4+r]*b[c*4+k];return m}
const HOME={yaw:0,pitch:1.15,dist:2350,t:[0,0,0]};
let yaw=HOME.yaw,pitch=HOME.pitch,dist=HOME.dist,target=HOME.t.slice(),eye=[0,0,0],right=[1,0,0],up=[0,1,0],forward=[0,0,-1];
const DMIN=16,DMAX=2600;let fly=null;
function effPitch(){return Math.max(pitch,pitch+(1.32-pitch)*smoothstep(500,2200,dist))}
function cam(){const p=effPitch();eye=[target[0]+dist*Math.sin(yaw)*Math.cos(p),target[1]+dist*Math.sin(p),target[2]+dist*Math.cos(yaw)*Math.cos(p)];
 const gy=Math.max(meshH(eye[0],eye[2]),0)+6;if(eye[1]<gy)eye[1]=gy;forward=norm(sub(target,eye));right=norm(cross(forward,[0,1,0]));up=norm(cross(right,forward))}
function projection(){let aspect=canvas.width/canvas.height,f=1/Math.tan(Math.PI/6),n=Math.max(.4,dist*.012),far=dist*4+3000;return [f/aspect,0,0,0,0,f,0,0,0,0,(far+n)/(n-far),-1,0,0,(2*far*n)/(n-far),0]}
function view(){let r=right,u=up,f=forward;return [r[0],u[0],-f[0],0,r[1],u[1],-f[1],0,r[2],u[2],-f[2],0,-dot(r,eye),-dot(u,eye),dot(f,eye),1]}
let vw=0,vh=0;const DPR_CAP=MOBILE?1.4:1.75;
function resize(){let dpr=Math.min(devicePixelRatio||1,DPR_CAP),w=Math.round(AW*dpr),h=Math.round(AH*dpr);if(vw!==w||vh!==h){canvas.width=vw=w;canvas.height=vh=h}}
function lookAtM(e,c,u0){let f=norm(sub(c,e)),r=norm(cross(f,u0)),u=cross(r,f);return [r[0],u[0],-f[0],0,r[1],u[1],-f[1],0,r[2],u[2],-f[2],0,-dot(r,e),-dot(u,e),dot(f,e),1]}
function orthoM(E,n,f){return [1/E,0,0,0,0,1/E,0,0,0,0,-2/(f-n),0,0,0,-(f+n)/(f-n),1]}
let shadowKey='',lightMat=new Array(16).fill(0),shOff=.2,shadowDirty=true,meshVer=0;
function bindPos(buf){gl.bindBuffer(gl.ARRAY_BUFFER,buf);gl.enableVertexAttribArray(0);gl.vertexAttribPointer(0,3,gl.FLOAT,false,0,0)}
function updateShadow(){
 let r=clamp(dist*1.45,40,2000),k=Math.ceil(Math.log(r/40)/Math.log(1.2));r=Math.min(40*Math.pow(1.2,k),2100);
 let fx=forward[0],fz=forward[2],fl=Math.hypot(fx,fz)||1,snap=r/8;
 let cx=Math.round((target[0]+fx/fl*r*.3)/snap)*snap,cz=Math.round((target[2]+fz/fl*r*.3)/snap)*snap,E=r*1.12,key=E.toFixed(1)+'|'+cx.toFixed(1)+'|'+cz.toFixed(1);
 if(key===shadowKey&&!shadowDirty)return;shadowKey=key;shadowDirty=false;
 const R=E*1.5+160,D=R+60,ctr=[cx,10,cz],le=[cx+Lf[0]*D,10+Lf[1]*D,cz+Lf[2]*D];
 lightMat=mul(orthoM(E,D-R,D+R),lookAtM(le,ctr,[0,1,0]));shOff=(2*E/SHS)*3.0;if(!shadowsOK)return;
 gl.activeTexture(gl.TEXTURE0);gl.bindTexture(gl.TEXTURE_2D,null);
 gl.bindFramebuffer(gl.FRAMEBUFFER,shFB);gl.viewport(0,0,SHS,SHS);gl.clearColor(1,1,1,1);gl.clear(gl.COLOR_BUFFER_BIT|gl.DEPTH_BUFFER_BIT);gl.enable(gl.DEPTH_TEST);
 const lm=new Float32Array(lightMat);gl.useProgram(dpr_);gl.uniformMatrix4fv(uD.uLight,false,lm);gl.disableVertexAttribArray(1);gl.disableVertexAttribArray(2);
 gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER,chunkIdx);for(const c of chunks){if(c.under||!boxVisible(lightMat,c.box))continue;bindPos(c.p);gl.drawElements(gl.TRIANGLES,chunkIdxCount,gl.UNSIGNED_SHORT,0)}
 if(staticOut.count){bindPos(staticOut.buf.p);gl.drawArrays(gl.TRIANGLES,0,staticOut.count)}
 if(INST&&treeNd+treeNc){gl.useProgram(dipr);gl.uniformMatrix4fv(uDI.uLight,false,lm);drawTrees(true)}
 gl.bindFramebuffer(gl.FRAMEBUFFER,null)}
function fogVals(){return [dist*2.2+250,dist*3+900,dist>900?0:.24]}
function setCommon(u,mvp,lm){gl.uniformMatrix4fv(u.uMVP,false,mvp);gl.uniform3fv(u.uEye,eye);gl.uniformMatrix4fv(u.uLight,false,lm);gl.uniform3fv(u.uL,Lf);gl.uniform1f(u.uOff,shOff);gl.uniform1f(u.uTexel,1/SHS);gl.uniform1f(u.uUseSh,shadowsOK?1:0);gl.uniform3fv(u.uFog,fogVals())}
let drawnChunks=0,lastM=null,gameTime=0;
const terrU=new Float32Array(4*MAXTERR);let terrN=0;
function updateTerrUniform(){const circ=terrCircles();if(placing&&placing.type==='castle'&&ghost&&!S.castle)circ.push([ghost.x,ghost.z,55]);terrN=Math.min(circ.length,MAXTERR);terrU.fill(0);for(let i=0;i<terrN;i++){terrU[i*4]=circ[i][0];terrU[i*4+1]=circ[i][1];terrU[i*4+2]=circ[i][2]}}
function drawMesh(o,tint){if(!o.count)return;gl.uniform4fv(uO.uTint,tint||[0,0,0,0]);bindModel(o.buf);gl.drawArrays(gl.TRIANGLES,0,o.count)}
function draw(){
 gl.viewport(0,0,vw,vh);gl.clearColor(.55,.66,.70,1);gl.clear(gl.COLOR_BUFFER_BIT|gl.DEPTH_BUFFER_BIT);gl.enable(gl.DEPTH_TEST);gl.disable(gl.CULL_FACE);
 const M=mul(projection(),view()),mvp=new Float32Array(M),lm=new Float32Array(lightMat);lastM=M;
 gl.activeTexture(gl.TEXTURE0);gl.bindTexture(gl.TEXTURE_2D,shTex);
 gl.useProgram(tpr);setCommon(uT,mvp,lm);gl.uniform1f(uT.uDetFar,Math.max(240,dist*1.5));
 gl.uniform4fv(uT.uTerr,terrU);gl.uniform1f(uT.uNT,terrN);gl.uniform1f(uT.uTime,gameTime);
 gl.uniform4f(uT.uGrid,ghost?ghost.x:0,ghost?ghost.z:0,placing&&ghost?42:0,placing?1:0);
 const sb=selected&&byId.get(selected);gl.uniform4f(uT.uSel,sb?sb.x:0,sb?sb.z:0,sb?TYPES[sb.type].size*TILE/2+.6:0,0);
 gl.disableVertexAttribArray(1);gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER,chunkIdx);drawnChunks=0;
 for(const c of chunks){if(!boxVisible(M,c.box))continue;drawnChunks++;bindPos(c.p);gl.bindBuffer(gl.ARRAY_BUFFER,c.n);gl.enableVertexAttribArray(2);gl.vertexAttribPointer(2,3,gl.FLOAT,false,0,0);gl.drawElements(gl.TRIANGLES,chunkIdxCount,gl.UNSIGNED_SHORT,0)}
 gl.useProgram(wpr);setCommon(uW,mvp,lm);gl.uniform1f(uW.uTime,gameTime);gl.disableVertexAttribArray(2);bindPos(waterBuf);gl.drawArrays(gl.TRIANGLES,0,6);
 gl.useProgram(opr);setCommon(uO,mvp,lm);drawMesh(staticOut);drawMesh(animOut);
 if(ghost&&ghostOut.count)drawMesh(ghostOut,ghost.ok?[.35,1,.45,.42]:[1,.3,.25,.5]);
 if(INST&&treeNd+treeNc){gl.useProgram(ipr);setCommon(uI,mvp,lm);drawTrees(false)}
 if(INST&&vCount&&vGeoMesh)drawVillagers(mvp,lm);
}
function drawVillagers(mvp,lm){
 // sombras-bolha (com transparência)
 gl.useProgram(bpr);gl.uniformMatrix4fv(uB.uMVP,false,mvp);gl.enable(gl.BLEND);gl.blendFunc(gl.SRC_ALPHA,gl.ONE_MINUS_SRC_ALPHA);gl.depthMask(false);
 for(let a=1;a<7;a++)gl.disableVertexAttribArray(a);
 bindPos(blobBuf);gl.bindBuffer(gl.ARRAY_BUFFER,vInstBuf);gl.enableVertexAttribArray(3);gl.vertexAttribPointer(3,4,gl.FLOAT,false,48,0);INST.vertexAttribDivisorANGLE(3,1);
 INST.drawArraysInstancedANGLE(gl.TRIANGLES,0,6,vCount);gl.depthMask(true);gl.disable(gl.BLEND);
 gl.useProgram(vpr);setCommon(uV,mvp,lm);bindModel(vGeoMesh);gl.bindBuffer(gl.ARRAY_BUFFER,vGeoMesh.a);gl.enableVertexAttribArray(6);gl.vertexAttribPointer(6,1,gl.FLOAT,false,0,0);
 gl.bindBuffer(gl.ARRAY_BUFFER,vInstBuf);for(const [a,off] of [[3,0],[4,16],[5,32]]){gl.enableVertexAttribArray(a);gl.vertexAttribPointer(a,4,gl.FLOAT,false,48,off);INST.vertexAttribDivisorANGLE(a,1)}
 INST.drawArraysInstancedANGLE(gl.TRIANGLES,0,vGeoMesh.count,vCount);
 for(const a of [3,4,5]){INST.vertexAttribDivisorANGLE(a,0);gl.disableVertexAttribArray(a)}gl.disableVertexAttribArray(6)}
// mundo → tela (para rótulos e barras de progresso)
function toScreen(x,y,z){const m=lastM;if(!m)return null;const cx=m[0]*x+m[4]*y+m[8]*z+m[12],cy=m[1]*x+m[5]*y+m[9]*z+m[13],cw=m[3]*x+m[7]*y+m[11]*z+m[15];if(cw<=.1)return null;return {x:(cx/cw*.5+.5)*AW,y:(.5-cy/cw*.5)*AH}}

/* ---------- Laço principal ---------- */
let lastKey='',lastT=performance.now(),econT=0,saveT=0,assignT=0,uiT=0,farDraw=0;
function simStep(dt){econT+=dt;if(econT>.5){econT=0;computeEcon();checkGoals()}
 simEcon(dt);simBuild(dt);for(const v of vill)stepVillager(v,dt);
 assignT+=dt;if(assignT>1.5){assignT=0;syncVillagers();assignRoles()}
 saveT+=dt;if(saveT>8){saveT=0;save()}}
function frame(now){resize();let dt=Math.min(.5,(now-lastT)/1000);lastT=now;gameTime+=dt;
 if(fly){fly.k=Math.min(1,fly.k+dt/fly.d);const e=fly.k<.5?2*fly.k*fly.k:1-Math.pow(-2*fly.k+2,2)/2;target[0]=fly.a.t[0]+(fly.b.t[0]-fly.a.t[0])*e;target[2]=fly.a.t[2]+(fly.b.t[2]-fly.a.t[2])*e;dist=fly.a.d+(fly.b.d-fly.a.d)*e;pitch=fly.a.p+(fly.b.p-fly.a.p)*e;yaw=fly.a.y+(fly.b.y-fly.a.y)*e;if(fly.k>=1)fly=null}
 const ty=Math.max(meshH(target[0],target[2]),0);if(Math.abs(ty-target[1])>.05)target[1]+=(ty-target[1])*.3;else target[1]=ty;
 cam();
 // simulação em passos de no máximo 0,1 s (mesmo com quadros lentos)
 let rem=dt;while(rem>1e-4){const s=Math.min(.1,rem);simStep(s);rem-=s}
 if(staticDirty)rebuildStatic();if(terrDirty){terrDirty=false;updateTerrUniform()}
 updateTrees();updateShadow();
 const close=dist<900;
 if(close){rebuildAnim(gameTime,dt);uploadVillagers()}else{sparks.length=0;confs.length=0}
 const key=[yaw,pitch,dist,target[0],target[1],target[2],vw,vh,meshVer,treeVer,shadowKey,ghost&&ghost.k,selected].join('|');
 farDraw+=dt;if(close||key!==lastKey||farDraw>.5){lastKey=key;farDraw=0;draw()}
 uiT+=dt;if(uiT>.25){uiT=0;updateHUD()}updateOverlays(dt);
 requestAnimationFrame(frame)}
function flyTo(x,z,d,p,y){fly={k:0,d:1.6,a:{t:target.slice(),d:dist,p:pitch,y:yaw},b:{t:[x,0,z],d,p:p??pitch,y:y??yaw}}}
function rayDir(x,y){cam();const nx=x/AW*2-1,ny=1-y/AH*2,tan=Math.tan(Math.PI/6),aspect=AW/AH;return norm(forward.map((v,i)=>v+right[i]*nx*aspect*tan+up[i]*ny*tan))}
function pickPlane(x,y,py){const d=rayDir(x,y);if(d[1]>-.0005)return null;const t=(py-eye[1])/d[1];return t>0?{x:eye[0]+d[0]*t,z:eye[2]+d[2]*t}:null}
function pickGround(x,y){const d=rayDir(x,y);if(d[1]>-.0005)return null;let t=(target[1]-eye[1])/d[1],px=eye[0]+d[0]*t,pz=eye[2]+d[2]*t;
 for(let j=0;j<8;j++){const h=Math.max(meshH(px,pz),0);t=(h-eye[1])/d[1];px=eye[0]+d[0]*t;pz=eye[2]+d[2]*t}return {x:px,z:pz,t}}
function pickBuilding(x,y){const d=rayDir(x,y),o=eye;let best=null,bt=1e9;
 for(const b of S.b){const h=TYPES[b.type].size*TILE/2,H=HEIGHT[b.type]||6;const mn=[b.x-h,b.minH-1,b.z-h],mx=[b.x+h,b.y+H,b.z+h];let t0=0,t1=1e9,ok=true;
  for(let k=0;k<3;k++){if(Math.abs(d[k])<1e-6){if(o[k]<mn[k]||o[k]>mx[k]){ok=false;break}continue}let a=(mn[k]-o[k])/d[k],c=(mx[k]-o[k])/d[k];if(a>c)[a,c]=[c,a];t0=Math.max(t0,a);t1=Math.min(t1,c);if(t0>t1){ok=false;break}}
  if(ok&&t0<bt){bt=t0;best=b}}
 const g=pickGround(x,y);if(best&&g&&g.t<bt-1){const id=occ.get(tkey(Math.floor(g.x/TILE),Math.floor(g.z/TILE)));return id?byId.get(id):null}return best}

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
 $('tip').textContent=m==='demolish'?'🗑 Toque numa construção para demolir (devolve 50%)':m==='build'?'🏗 Escolha um local dentro das fronteiras douradas':'☝ Toque numa construção para ver detalhes e melhorar'}
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
  if(b.type==='castle'){rows.push(`Impostos: <b>+${(.4+.25*(L-1)+.025*S.pop).toFixed(1)} 🪙/s</b>`,`Moradia: <b>6</b> • Território: <b>${55+12*(L-1)} m</b>`,`Construtores: <b>${econ.builders}</b>`);
   const nx=BUILD_ORDER.filter(t=>DEF[t].unlock===L+1).map(t=>TYPES[t].icon+' '+TYPES[t].name);if(nx.length)rows.push(`<span class="small">Próximo nível libera: ${nx.join(', ')}</span>`)}
  if(b.type==='house'){const n=vill.filter(v=>v.home===b.id).length;rows.push(`Moradores: <b>${n}/${4+2*(L-1)}</b>`)}
  if(d.job&&d.job!=='happy')rows.push(`Produção: <b>+${((b.rate||0)*(b.workers||0)).toFixed(2)} ${RICON[d.job]}/s</b>`,`Trabalhadores: <b>${b.workers||0}/${slotsOf(b)}</b> • Rendimento do terreno: <b>${Math.round(b.e*100)}%</b>`);
  if(b.type==='tavern')rows.push(`Felicidade: <b>+${8+5*L}%</b> • Atendentes: ${b.workers||0}/${slotsOf(b)}`);
  if(b.type==='well')rows.push(`Felicidade: <b>+${3+2*L}%</b>`);
  if(b.type==='market')rows.push(`Felicidade: <b>+${2*L}%</b>`);
  if(b.type==='warehouse')rows.push(`Capacidade extra: <b>+${500*L}</b>`);
  if(b.type==='tower')rows.push(`Território: <b>${34+6*(L-1)} m</b>`);
  if(b.upg)rows.push(`<div class="prog"><i style="width:${b.prog*100}%"></i></div><div class="small">Melhorando para o nível ${L+1}… ${Math.round(b.prog*100)}%</div>`)}
 const canUp=b.state==='done'&&!b.upg&&L<T.max,c=canUp?costOf(b.type,b.type==='castle'?L:L+1):null;
 const sig=[b.id,b.state,L,b.upg,Math.round(b.prog*100),b.workers,Math.round((b.rate||0)*100),canUp&&canPay(c),S.pop].join('|');if(soft&&sig===panelSig)return;panelSig=sig;
 $('infoTitle').innerHTML=`${T.icon} ${T.name} <span class="stars">${stars(L,T.max)}</span>`;
 $('infoBody').innerHTML=`<p class="desc">${d.desc}</p>`+rows.map(r=>`<div class="row">${r}</div>`).join('');
 const up=$('btnUp');up.style.display=canUp?'':'none';if(canUp){up.innerHTML=`⬆ Melhorar <small>${costHTML(c)}</small>`;up.classList.toggle('poor',!canPay(c))}
 $('btnDemo').style.display=b.type==='castle'?'none':''}
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
 closeInfo();
 const g=pickGround(x,y);if(g&&dist>600&&!S.castle){}}
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
$('btnBuild').onclick=()=>{if(!S.castle){startPlacing('castle');return}openMenu(!menuOpen)};
$('btnDemolish').onclick=()=>{setMode('demolish');openMenu(false)};
$('btnUp').onclick=()=>{const b=byId.get(selected);if(b)upgradeBuilding(b)};
$('btnDemo').onclick=()=>{const b=byId.get(selected);if(!b)return;const btn=$('btnDemo');if(btn.dataset.sure!=='1'){btn.dataset.sure='1';btn.textContent='Confirmar?';setTimeout(()=>{btn.dataset.sure='';btn.textContent='🗑 Demolir'},2500);return}btn.dataset.sure='';btn.textContent='🗑 Demolir';demolish(b)};
$('btnClose').onclick=closeInfo;
$('cOk').onclick=confirmPlace;$('cRot').onclick=rotateGhost;$('cNo').onclick=()=>{setMode('select')};
$('plus').onclick=()=>{fly=null;dist=clamp(dist*.7,DMIN,DMAX)};$('minus').onclick=()=>{fly=null;dist=clamp(dist*1.43,DMIN,DMAX)};
$('reset').onclick=()=>{const c=castleB();if(c)flyTo(c.x,c.z,140,.95,0);else flyTo(0,0,HOME.dist,HOME.pitch,0)};
$('orient').onclick=()=>{setLandscape(!wantLand);toast(wantLand?'Modo horizontal ativado':'Modo vertical ativado')};
$('goal').onclick=()=>$('goal').classList.toggle('mini');
$('introGo').onclick=()=>{$('intro').classList.remove('show');startPlacing('castle');toast('Escolha uma planície com floresta e montanhas por perto 🏰')};
$('backOk').onclick=()=>$('back').classList.remove('show');
$('btnReset').onclick=()=>{if(confirm('Apagar o reino e começar de novo?')){try{localStorage.removeItem(SAVE_KEY)}catch(e){}location.reload()}};

/* ---------- Salvar / carregar (com ganhos enquanto você estava fora) ---------- */
function save(){if(!S.castle)return;S.saved=Date.now();const data={res:S.res,pop:S.pop,goal:S.goal,castle:S.castle,nextId:S.nextId,saved:S.saved,growT:S.growT,
 b:S.b.map(b=>({id:b.id,type:b.type,x:b.x,z:b.z,rot:b.rot,level:b.level,state:b.state,prog:b.prog,upg:b.upg,work:b.work})),cam:[target[0],target[2],dist,yaw,pitch]};
 try{localStorage.setItem(SAVE_KEY,JSON.stringify(data))}catch(e){}}
function load(){let d=null;try{d=JSON.parse(localStorage.getItem(SAVE_KEY)||'null')}catch(e){}if(!d||!d.b||!d.b.length)return false;
 S.res=Object.assign({gold:0,wood:0,stone:0,food:0},d.res);S.pop=d.pop|0;S.goal=d.goal|0;S.nextId=d.nextId||1;S.growT=d.growT||0;
 for(const o of d.b){const b=addBuilding({id:o.id,type:o.type,x:o.x,z:o.z,rot:o.rot||0,level:o.level||1,state:o.state,prog:o.prog||0,upg:!!o.upg,work:o.work||workTime(o.type,o.level||1)})}
 S.castle=d.castle;computeEcon();computeEcon();
 const away=clamp((Date.now()-(d.saved||Date.now()))/1000,0,4*3600);
 if(away>60){const gain={};for(const k of RES){const r=econ.rate[k];gain[k]=r>0?r*away*.5:0;S.res[k]=clamp(S.res[k]+gain[k],0,econ.cap)}
  for(const b of S.b)if(b.state==='site'||b.upg){b.prog=Math.min(1,b.prog+away/b.work*.5);if(b.prog>=1){b.state='done';if(b.upg){b.level++;b.upg=false}b.prog=0}}
  const h=Math.floor(away/3600),m=Math.floor(away%3600/60);$('backTxt').innerHTML=`Você ficou fora por <b>${h?h+'h ':''}${m} min</b>.<br>Seu povo continuou trabalhando:`+
   `<div class="gains">${RES.map(k=>gain[k]>=1?`<span>${RICON[k]} +${fmt(gain[k])}</span>`:'').join('')}</div>`;$('back').classList.add('show')}
 if(d.cam){target=[d.cam[0],0,d.cam[1]];dist=d.cam[2];yaw=d.cam[3];pitch=d.cam[4]}
 staticDirty=true;terrDirty=true;computeEcon();syncVillagers();assignRoles();
 // espalha os aldeões pela vila ao carregar
 const done=S.b.filter(b=>b.state==='done');for(const v of vill){const b=pick(done);if(b){const dd=doorOf(b);v.x=dd[0]+(Math.random()-.5)*4;v.z=dd[1]+(Math.random()-.5)*4}}
 return true}
addEventListener('visibilitychange',()=>{if(document.hidden)save()});addEventListener('pagehide',save);

/* ---------- Inicialização ---------- */
const setLoad=t=>$('loadTxt').textContent=t,tick=()=>new Promise(r=>setTimeout(r,16));
(async()=>{try{const t0=performance.now();
 const [alb,hm]=await Promise.all([loadImg(ALBEDO_SRC),loadImg(HMAP_SRC)]);
 setLoad('Lendo o relevo…');await tick();readHeightmap(hm);buildNodeHeights();
 setLoad('Preparando o terreno…');await tick();uploadAlbedo(alb);bakeNormals();bakeDetail();buildChunks();
 setLoad('Erguendo as construções…');await tick();buildTreeModels();buildVillagerMesh();for(const t of Object.keys(TYPES))getModel(t,1);
 const had=load();if(!had){$('intro').classList.add('show')}
 window.__loadMs=Math.round(performance.now()-t0);window.__dbg=()=>({drawnChunks,trees:treeNd+treeNc,dist,vill:vill.length,vCount,static:staticOut.count,anim:animOut.count});
 window.__game={S,econ,vill,check,efficiency,fracAround,classAt,computeEcon,syncVillagers,assignRoles,placeBuilding,flyTo,TYPES,byId,setView:(x,z,d,p,y)=>{target=[x,0,z];dist=d;if(p!=null)pitch=p;if(y!=null)yaw=y;fly=null},warp:(sec)=>{for(let t=0;t<sec;t+=.1)simStep(.1)},finishAll:()=>{for(const b of S.b)if(b.state==='site'||b.upg){b.prog=1;finishBuild(b)}}};
 const ld=$('loading');ld.style.opacity='0';setTimeout(()=>ld.remove(),450);
 renderMenu(true);updateHUD();requestAnimationFrame(t=>{lastT=t;frame(t)});
}catch(e){console.error(e);setLoad('Erro de inicialização: '+e.message)}})();
