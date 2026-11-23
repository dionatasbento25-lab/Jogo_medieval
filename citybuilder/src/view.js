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
  const latN=(z+HZ)/WZ,coldN=smoothstep(.40,.06,latN);coni=.5+.47*coldN;
  if(cl===3)p=.82;else if(cl===2)p=.03+.03*coldN;else if(cl===5){p=htF(x,z)<48?.13:0;coni=.95}else if(cl===4)p=.004;
  if(r()>p)continue;const y=meshH(x,z);if(y<.4)continue;if(RIV){const ri=Math.floor((x+HX)/WX*PW),rj=Math.floor((z+HZ)/WZ*PH);if(RIV[rj*PW+ri]>50){r();r();r();r();continue}}const sc=.75+r()*.6,rot=r()*6.283,tn=.82+r()*.32,isC=r()<coni;if(occNear(x,z))continue;(isC?c:d).push(x,y-.2,z,sc,rot,tn)}
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
 lightMat=mul(orthoM(E,D-R,D+R),lookAtM(le,ctr,[0,1,0]));shOff=(2*E/SHS)*4.0;if(!shadowsOK)return;
 gl.activeTexture(gl.TEXTURE0);gl.bindTexture(gl.TEXTURE_2D,null);
 gl.bindFramebuffer(gl.FRAMEBUFFER,shFB);gl.viewport(0,0,SHS,SHS);gl.clearColor(1,1,1,1);gl.clear(gl.COLOR_BUFFER_BIT|gl.DEPTH_BUFFER_BIT);gl.enable(gl.DEPTH_TEST);
 const lm=new Float32Array(lightMat);gl.useProgram(dpr_);gl.uniformMatrix4fv(uD.uLight,false,lm);gl.disableVertexAttribArray(1);gl.disableVertexAttribArray(2);
 gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER,chunkIdx);for(const c of chunks){if(c.under||!boxVisible(lightMat,c.box))continue;bindPos(c.p);gl.drawElements(gl.TRIANGLES,chunkIdxCount,gl.UNSIGNED_SHORT,0)}
 for(const o of [staticOut,worldOut])if(o.count){bindPos(o.buf.p);gl.drawArrays(gl.TRIANGLES,0,o.count)}
 if(INST&&treeNd+treeNc){gl.useProgram(dipr);gl.uniformMatrix4fv(uDI.uLight,false,lm);drawTrees(true)}
 gl.bindFramebuffer(gl.FRAMEBUFFER,null)}
function fogVals(){return [dist*2.2+250,dist*3+900,dist>900?0:.24]}
function setCommon(u,mvp,lm){gl.uniformMatrix4fv(u.uMVP,false,mvp);gl.uniform3fv(u.uEye,eye);gl.uniformMatrix4fv(u.uLight,false,lm);gl.uniform3fv(u.uL,Lf);gl.uniform1f(u.uOff,shOff);gl.uniform1f(u.uTexel,1/SHS);gl.uniform1f(u.uUseSh,shadowsOK?1:0);gl.uniform3fv(u.uFog,fogVals())}
let drawnChunks=0,lastM=null,gameTime=0;

function drawMesh(o,tint){if(!o.count)return;gl.uniform4fv(uO.uTint,tint||[0,0,0,0]);bindModel(o.buf);gl.drawArrays(gl.TRIANGLES,0,o.count)}
function draw(){
 gl.viewport(0,0,vw,vh);gl.clearColor(.55,.66,.70,1);gl.clear(gl.COLOR_BUFFER_BIT|gl.DEPTH_BUFFER_BIT);gl.enable(gl.DEPTH_TEST);gl.disable(gl.CULL_FACE);
 const M=mul(projection(),view()),mvp=new Float32Array(M),lm=new Float32Array(lightMat);lastM=M;placeLabels(M);
 gl.activeTexture(gl.TEXTURE0);gl.bindTexture(gl.TEXTURE_2D,shTex);
 gl.useProgram(tpr);setCommon(uT,mvp,lm);gl.uniform1f(uT.uDetFar,Math.max(240,dist*1.5));
 gl.uniform1f(uT.uTime,animT);{const M_=MODES[mapMode];gl.uniform1f(uT.uFill,M_.fill*(.25+.53*smoothstep(150,1300,dist)));gl.uniform1f(uT.uPix,2*Math.tan(Math.PI/6)/vh);gl.uniform3fv(uT.uLines,M_.lines)}
 gl.uniform4f(uT.uGrid,ghost?ghost.x:0,ghost?ghost.z:0,placing&&ghost?42:0,placing?1:0);
 const sb=selected&&byId.get(selected);gl.uniform4f(uT.uSel,sb?sb.x:0,sb?sb.z:0,sb?TYPES[sb.type].size*TILE/2+.6:0,0);
 gl.disableVertexAttribArray(1);gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER,chunkIdx);drawnChunks=0;
 for(const c of chunks){if(!boxVisible(M,c.box))continue;drawnChunks++;bindPos(c.p);gl.bindBuffer(gl.ARRAY_BUFFER,c.n);gl.enableVertexAttribArray(2);gl.vertexAttribPointer(2,3,gl.FLOAT,false,0,0);gl.drawElements(gl.TRIANGLES,chunkIdxCount,gl.UNSIGNED_SHORT,0)}
 gl.useProgram(wpr);setCommon(uW,mvp,lm);gl.disableVertexAttribArray(2);bindPos(waterBuf);gl.drawArrays(gl.TRIANGLES,0,6);
 gl.useProgram(opr);setCommon(uO,mvp,lm);drawMesh(worldOut);drawMesh(strOut);drawMesh(staticOut);drawMesh(animOut);
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
const SPEED_MUL=[0,1,1.5,2,3,4];
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
 let rem=GameTime.pausado?0:dt*SPEED_MUL[GameTime.velocidade];while(rem>1e-4){const s=Math.min(.1,rem);simStep(s);rem-=s}
 if(staticDirty)rebuildStatic();
 updateTrees();updateShadow();
 const close=dist<900;if(close||(dist<420&&riverNear())){animT=gameTime%1000}
 if(close){rebuildAnim(gameTime,dt);uploadVillagers()}else{sparks.length=0;confs.length=0}
 const key=[yaw,pitch,dist,target[0],target[1],target[2],vw,vh,meshVer,treeVer,shadowKey,ghost&&ghost.k,selected,polVer,mapMode,animT].join('|');
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

