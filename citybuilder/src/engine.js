'use strict';
/* =====================================================================
   REINOS 3D — CITY BUILDER
   Motor gráfico (adaptado do mapa "Reinos 3D — O Continente").
   WebGL 1 puro: terreno em blocos, água, sombras PCF, árvores instanciadas,
   construções low-poly e aldeões animados por instância.
   ===================================================================== */
const canvas=document.querySelector('#scene');
const MOBILE=matchMedia('(pointer:coarse)').matches||/Android|iPhone|iPad|Mobile/i.test(navigator.userAgent);

/* ---------- Modo horizontal no celular ---------- */
const app=document.getElementById('app');let ROT=false,AW=innerWidth,AH=innerHeight;
let wantLand=MOBILE;try{const sv=localStorage.getItem('reinos_land');if(sv!==null)wantLand=sv==='1'}catch(e){}
if(MOBILE)document.body.classList.add('mobile');
function applyOrientation(){const W=innerWidth,H=innerHeight;ROT=wantLand&&H>W;document.body.classList.toggle('rot',ROT);AW=ROT?H:W;AH=ROT?W:H;app.style.width=AW+'px';app.style.height=AH+'px';document.body.classList.toggle('compact',AH<520)}
addEventListener('resize',applyOrientation);addEventListener('orientationchange',()=>setTimeout(applyOrientation,200));applyOrientation();
const toApp=e=>ROT?{x:e.clientY,y:innerWidth-e.clientX}:{x:e.clientX,y:e.clientY};
let triedLock=false;
function tryLandscapeLock(){if(triedLock||!wantLand||!MOBILE)return;triedLock=true;const el=document.documentElement,rf=el.requestFullscreen||el.webkitRequestFullscreen;if(!rf)return;try{Promise.resolve(rf.call(el)).then(()=>screen.orientation&&screen.orientation.lock?screen.orientation.lock('landscape'):0).catch(()=>{})}catch(e){}}
function setLandscape(on){wantLand=on;try{localStorage.setItem('reinos_land',on?'1':'0')}catch(e){}if(!on){try{screen.orientation&&screen.orientation.unlock&&screen.orientation.unlock()}catch(e){}}else{triedLock=false;tryLandscapeLock()}applyOrientation()}

const gl=canvas.getContext('webgl',{antialias:true,alpha:false,powerPreference:'high-performance'});
if(!gl){document.getElementById('loadTxt').textContent='Este navegador não oferece WebGL.';throw Error('sem WebGL')}
const INST=gl.getExtension('ANGLE_instanced_arrays');

/* =====================================================================
   1. UTILITÁRIOS
   ===================================================================== */
let seed=1;function rnd(){seed=(seed*1664525+1013904223)>>>0;return seed/4294967296}function range(a,b){return a+(b-a)*rnd()}
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
function hash2(x,z){let n=Math.sin(x*127.1+z*311.7)*43758.5453;return n-Math.floor(n)}
function smoothstep(a,b,t){let q=clamp((t-a)/(b-a),0,1);return q*q*(3-2*q)}
function mixC(a,b,t){t=clamp(t,0,1);return [a[0]+(b[0]-a[0])*t,a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t]}
const _hexCache=new Map();
function hex(s){let c=_hexCache.get(s);if(!c){c=[parseInt(s.slice(1,3),16)/255,parseInt(s.slice(3,5),16)/255,parseInt(s.slice(5,7),16)/255];_hexCache.set(s,c)}return c}
function loadImg(src){return new Promise((ok,err)=>{const i=new Image();i.onload=()=>ok(i);i.onerror=()=>err(Error('falha ao ler imagem do mapa'));i.src=src})}

/* =====================================================================
   2. O CONTINENTE — relevo e biomas
   ===================================================================== */
const WX=3072,WZ=2048,HX=WX/2,HZ=WZ/2;
const CLASS_NAMES=['Mar / lago','Rio','Planície','Floresta','Deserto / estepe','Montanha','Neve'];
let HMW=0,HMH=0,HM=null,CL=null;
function readHeightmap(img){
 const c=document.createElement('canvas');c.width=img.width;c.height=img.height;const x=c.getContext('2d');x.drawImage(img,0,0);
 const d=x.getImageData(0,0,c.width,c.height).data;HMW=c.width;HMH=c.height;HM=new Float32Array(HMW*HMH);CL=new Uint8Array(HMW*HMH);
 for(let k=0,o=0;k<HM.length;k++,o+=4){HM[k]=(d[o]*256+d[o+1])/65535*200-40;CL[k]=d[o+2]}}
function htF(x,z){const fx=clamp((x+HX)/WX*(HMW-1),0,HMW-1.001),fz=clamp((z+HZ)/WZ*(HMH-1),0,HMH-1.001),i=fx|0,j=fz|0,u=fx-i,v=fz-j,k=j*HMW+i;
 return (HM[k]*(1-u)+HM[k+1]*u)*(1-v)+(HM[k+HMW]*(1-u)+HM[k+HMW+1]*u)*v}
function classAt(x,z){const i=Math.round(clamp((x+HX)/WX*(HMW-1),0,HMW-1)),j=Math.round(clamp((z+HZ)/WZ*(HMH-1),0,HMH-1));return CL[j*HMW+i]}
const NX=512,NZ=320,CS=64,CX=WX/NX,CZ=WZ/NZ;let NH=null;
function buildNodeHeights(){NH=new Float32Array((NX+1)*(NZ+1));for(let j=0;j<=NZ;j++)for(let i=0;i<=NX;i++)NH[j*(NX+1)+i]=htF(-HX+i*CX,-HZ+j*CZ)}
function meshH(x,z){const fx=clamp((x+HX)/CX,0,NX-.001),fz=clamp((z+HZ)/CZ,0,NZ-.001),i=fx|0,j=fz|0,u=fx-i,v=fz-j,W=NX+1,k=j*W+i;
 return u+v<1?NH[k]+(NH[k+1]-NH[k])*u+(NH[k+W]-NH[k])*v:NH[k+W+1]+(NH[k+W]-NH[k+W+1])*(1-u)+(NH[k+1]-NH[k+W+1])*(1-v)}
function ground(x,z){return Math.max(meshH(x,z),0)+.12}
function isWater(x,z){const c=classAt(x,z);return c<=1||meshH(x,z)<.3}

/* =====================================================================
   3. SHADERS
   ===================================================================== */
const Lf=(()=>{let v=[-0.52,0.64,0.56],d=Math.hypot(...v);return v.map(x=>x/d)})();
const HP=`#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
`;
const TAPS=[[-0.94,-0.40],[0.95,-0.77],[-0.09,-0.93],[-0.92,0.46],[0.97,0.76],[-0.24,0.97],[0.34,0.29],[0.44,-0.27],[0.44,0.93],[-0.38,-0.12],[-0.82,-0.92],[0,0]].slice(0,MOBILE?6:12);
const tapCode=TAPS.map(([a,b])=>`s+=tapS(c+vec2(${a.toFixed(2)},${b.toFixed(2)})*r,z);`).join('')+`s/=${TAPS.length}.0;`;
const LIGHT=`uniform sampler2D uShadow;uniform vec3 uEye;uniform vec3 uL;uniform float uTexel;uniform float uUseSh;uniform vec3 uFog;varying vec3 vPos;varying vec4 vSh;
float gBias;
float unpackD(vec4 c){return dot(c,vec4(1.0/16777216.0,1.0/65536.0,1.0/256.0,1.0));}
float tapS(vec2 uv,float z){return z-gBias>unpackD(texture2D(uShadow,uv))?0.0:1.0;}
float shadowAt(){if(uUseSh<0.5)return 1.0;vec3 p=vSh.xyz/vSh.w*0.5+0.5;if(p.x<=0.0||p.x>=1.0||p.y<=0.0||p.y>=1.0||p.z>=1.0)return 1.0;
 float r=uTexel*1.7,s=0.0,z=p.z;vec2 c=p.xy;${tapCode}
 vec2 e=abs(c-0.5)*2.0;return mix(s,1.0,smoothstep(0.84,1.0,max(e.x,e.y)));}
vec3 light(vec3 base,vec3 n,float ao,out float sh){
 float ndl=max(dot(n,uL),0.0);gBias=0.0005+0.0026*(1.0-ndl);sh=ndl>0.0?shadowAt():0.0;
 vec3 amb=mix(vec3(.34,.31,.24),vec3(.60,.70,.80),n.y*.5+.5)*.74*ao;vec3 sun=vec3(1.0,.91,.76)*.76*ndl*sh*mix(1.0,ao,.5);
 vec3 V=normalize(uEye-vPos);float rim=pow(1.0-max(dot(n,V),0.0),3.0)*.05;return base*(amb+sun)+vec3(.8,.9,1.0)*rim;}
vec3 fogged(vec3 col){float f=clamp((distance(vPos,uEye)-uFog.x)/uFog.y,0.0,uFog.z);return mix(col,vec3(.55,.66,.70),f);}`;
// Construções: cor por vértice + tinta (prévia verde/vermelha, destaque)
const vsO=`attribute vec3 aPos;attribute vec3 aCol;attribute vec3 aNorm;uniform mat4 uMVP;uniform mat4 uLight;uniform vec3 uL;uniform float uOff;varying vec3 vCol;varying vec3 vNorm;varying vec3 vPos;varying vec4 vSh;
void main(){gl_Position=uMVP*vec4(aPos,1.0);vec3 n=normalize(aNorm);n*=dot(n,uL)<0.0?-1.0:1.0;vSh=uLight*vec4(aPos+n*uOff,1.0);vCol=aCol;vNorm=aNorm;vPos=aPos;}`;
const fsO=HP+LIGHT+`uniform vec4 uTint;varying vec3 vCol;varying vec3 vNorm;void main(){vec3 n=normalize(vNorm);if(dot(n,uEye-vPos)<0.0)n=-n;float sh;vec3 c=light(vCol,n,1.0,sh);
 // estilo "idle": cores um pouco mais saturadas e luminosas
 float l=dot(c,vec3(.3,.59,.11));c=mix(vec3(l),c,1.18)*1.04;
 c=mix(c,uTint.rgb,uTint.a);gl_FragColor=vec4(fogged(c),1.0);}`;
const vsI=`attribute vec3 aPos;attribute vec3 aCol;attribute vec3 aNorm;attribute vec4 aInst;attribute vec2 aInst2;uniform mat4 uMVP;uniform mat4 uLight;uniform vec3 uL;uniform float uOff;varying vec3 vCol;varying vec3 vNorm;varying vec3 vPos;varying vec4 vSh;
void main(){float c=cos(aInst2.x),s=sin(aInst2.x);vec3 p=vec3(aPos.x*c-aPos.z*s,aPos.y,aPos.x*s+aPos.z*c)*aInst.w+aInst.xyz;vec3 n=vec3(aNorm.x*c-aNorm.z*s,aNorm.y,aNorm.x*s+aNorm.z*c);
gl_Position=uMVP*vec4(p,1.0);vec3 no=n*(dot(n,uL)<0.0?-1.0:1.0);vSh=uLight*vec4(p+no*uOff,1.0);vCol=aCol*aInst2.y;vNorm=n;vPos=p;}`;
const fsTree=HP+LIGHT+`uniform vec4 uTint;varying vec3 vCol;varying vec3 vNorm;void main(){vec3 n=normalize(vNorm);if(dot(n,uEye-vPos)<0.0)n=-n;float sh;gl_FragColor=vec4(fogged(light(vCol,n,1.0,sh)),1.0);}`;
// Terreno + território do reino + grade de construção + destaque da seleção
const vsT=`attribute vec3 aPos;attribute vec3 aNorm;uniform mat4 uMVP;uniform mat4 uLight;uniform float uOff;uniform vec2 uHalf;varying vec3 vPos;varying vec4 vSh;varying vec2 vUv;
void main(){gl_Position=uMVP*vec4(aPos,1.0);vSh=uLight*vec4(aPos+normalize(aNorm)*uOff,1.0);vPos=aPos;vUv=(aPos.xz+uHalf)/(2.0*uHalf);}`;
const MAXTERR=24;
const fsT=HP+LIGHT+`uniform sampler2D uCol;uniform sampler2D uNrm;uniform sampler2D uDet;uniform float uDetFar;varying vec2 vUv;
uniform vec4 uTerr[${MAXTERR}];uniform float uNT;uniform vec4 uGrid;uniform vec4 uSel;uniform float uTime;
void main(){vec4 nm=texture2D(uNrm,vUv);vec3 n=vec3(nm.r*2.0-1.0,0.0,nm.g*2.0-1.0);n.y=sqrt(max(1.0-n.x*n.x-n.z*n.z,0.05));
 vec3 base=texture2D(uCol,vUv).rgb;float d=distance(vPos,uEye),df=1.0-smoothstep(60.0,uDetFar,d);
 float det=texture2D(uDet,vPos.xz*0.13).r*0.6+texture2D(uDet,vPos.xz*0.031+vec2(0.37,0.11)).r*0.4;
 base=mix(base,vec3(.47,.44,.38)*(.75+det*.5),smoothstep(.80,.58,n.y)*.75);
 base*=mix(1.0,0.80+det*0.40,0.2+0.8*df);
 float lum=dot(base,vec3(.3,.59,.11)),fm=smoothstep(.25,.17,lum)*step(base.r,base.g);
 float cn=texture2D(uDet,vPos.xz*0.07).r*.65+texture2D(uDet,vPos.xz*0.19+vec2(.2,.6)).r*.35;
 base*=mix(1.0,.58+cn*.8,fm*clamp(d/260.0,0.25,1.0));
 // Território: distância com sinal até a união dos círculos
 float sd=1e5;for(int i=0;i<${MAXTERR};i++){if(float(i)>=uNT)break;vec4 t=uTerr[i];sd=min(sd,distance(vPos.xz,t.xy)-t.z);}
 float px=max(d*0.0025,0.35);
 float edge=1.0-smoothstep(px*1.2,px*3.2,abs(sd));
 float dash=step(0.35,fract((vPos.x+vPos.z)*0.09));
 base=mix(base,vec3(1.0,.86,.36),edge*(0.55+0.3*dash)*step(0.5,uNT));
 base=mix(base,base*vec3(1.08,1.04,.9),step(sd,0.0)*uGrid.w*0.6);
 base=mix(base,base*vec3(.75,.75,.8),step(0.0,sd)*uGrid.w*0.35);
 // Grade de construção em volta do cursor
 if(uGrid.z>0.0){vec2 g=fract(vPos.xz/4.0);vec2 gl2=min(g,1.0-g);float ln=1.0-smoothstep(0.0,0.06,min(gl2.x,gl2.y));
  float fade=1.0-smoothstep(uGrid.z*0.6,uGrid.z,distance(vPos.xz,uGrid.xy));base=mix(base,vec3(1.0,.97,.85),ln*fade*0.35);}
 // Destaque da seleção (quadrado pulsante)
 if(uSel.z>0.0){vec2 q=abs(vPos.xz-uSel.xy);float m=max(q.x,q.y);float r=1.0-smoothstep(0.0,0.5,abs(m-uSel.z));base=mix(base,vec3(1.0,.95,.5),r*(0.6+0.3*sin(uTime*5.0)));}
 float sh;gl_FragColor=vec4(fogged(light(base,n,nm.b*1.1,sh)),1.0);}`;
const vsW=`attribute vec3 aPos;uniform mat4 uMVP;uniform mat4 uLight;uniform float uOff;varying vec3 vPos;varying vec4 vSh;void main(){gl_Position=uMVP*vec4(aPos,1.0);vSh=uLight*vec4(aPos+vec3(0.0,uOff,0.0),1.0);vPos=aPos;}`;
const fsW=HP+LIGHT+`uniform sampler2D uNrm;uniform sampler2D uDet;uniform vec2 uHalf;uniform float uTime;
void main(){vec2 uv=(vPos.xz+uHalf)/(2.0*uHalf);float h=-40.0;if(uv.x>0.0&&uv.x<1.0&&uv.y>0.0&&uv.y<1.0)h=texture2D(uNrm,uv).a*50.0-40.0;
 float d=clamp(-h/24.0,0.0,1.0);vec3 col=mix(vec3(.17,.52,.56),vec3(.035,.19,.33),pow(d,.55));
 vec2 w=vec2(uTime*0.9,uTime*0.6);
 vec3 n=normalize(vec3((texture2D(uDet,vPos.xz*0.045+w*0.004).r-.5)*.22,1.0,(texture2D(uDet,vPos.xz*0.045+vec2(.5,.27)-w*0.003).r-.5)*.22));
 float sh;col=light(col,n,1.0,sh);vec3 V=normalize(uEye-vPos);
 float fr=pow(1.0-max(dot(n,V),0.0),4.0)*.35;col=mix(col,vec3(.62,.74,.82),fr);
 col+=vec3(1.0,.95,.85)*pow(max(dot(reflect(-uL,n),V),0.0),90.0)*.55*sh;
 col=mix(col,vec3(.86,.92,.88),smoothstep(-1.3,-0.1,h)*(.38+.12*sin(uTime*1.7+vPos.x*.05)));
 gl_FragColor=vec4(fogged(col),1.0);}`;
// Aldeões: um modelo articulado instanciado. Cada vértice sabe a que peça pertence (aPart)
// e o shader anima pernas, braços, ferramentas e o fardo carregado.
const vsV=`attribute vec3 aPos;attribute vec3 aCol;attribute vec3 aNorm;attribute vec4 aI1;attribute vec4 aI2;attribute vec4 aI3;attribute float aPart;
uniform mat4 uMVP;uniform mat4 uLight;uniform vec3 uL;uniform float uOff;varying vec3 vCol;varying vec3 vNorm;varying vec3 vPos;varying vec4 vSh;
vec3 rotX(vec3 p,vec3 piv,float a){p-=piv;float c=cos(a),s=sin(a);return vec3(p.x,p.y*c-p.z*s,p.y*s+p.z*c)+piv;}
void main(){
 float part=mod(aPart,10.0),acc=floor(aPart/10.0+0.01);float ph=aI2.x,mode=aI2.y,role=aI2.z,carry=aI2.w;
 vec3 p=aPos,n=aNorm,col=aCol;
 // cor da roupa (vértices marcados com r<0 recebem a cor da instância)
 if(col.r<-1.5)col=mix(vec3(.30,.18,.10),mix(vec3(.85,.62,.28),vec3(.12,.08,.06),step(.5,aI3.w)),fract(aI3.w*2.0))*col.g;else if(col.r<0.0)col=aI3.rgb*col.g;
 float vis=1.0;
 if(acc>0.5&&acc<4.5)vis=(abs(acc-role)<0.5&&carry<0.5)?1.0:0.0;
 if(acc>5.5&&acc<6.5)vis=abs(role-3.0)<0.5?1.0:0.0;           // chapéu de palha do fazendeiro
 if(acc>4.5&&acc<5.5){vis=carry>0.5?1.0:0.0;                  // fardo carregado
  col=carry<1.5?vec3(.55,.36,.2):carry<2.5?vec3(.62,.62,.6):carry<3.5?vec3(.9,.8,.5):vec3(1.0,.82,.25);}
 float walk=mode>0.5&&mode<1.5?1.0:0.0,work=mode>1.5?1.0:0.0;
 float sw=sin(ph)*0.75*walk;
 float bob=abs(sin(ph))*0.09*walk+sin(ph*0.5)*0.025*(1.0-walk)*(1.0-work);
 if(part>0.5&&part<1.5)p=rotX(p,vec3(0.0,.62,0.0),sw);
 if(part>1.5&&part<2.5)p=rotX(p,vec3(0.0,.62,0.0),-sw);
 float hold=carry>0.5?-1.25:0.0;
 float chop=work*(-1.6+1.3*smoothstep(-0.2,1.0,sin(ph*2.0)));
 if(part>2.5&&part<3.5)p=rotX(p,vec3(0.0,1.18,0.0),(carry>0.5?hold:-sw*0.8)+work*0.2);
 if(part>3.5&&part<4.5)p=rotX(p,vec3(0.0,1.18,0.0),carry>0.5?hold:(work>0.5?chop:sw*0.8));
 if(part<0.5&&work>0.5&&aPos.y>1.0)p=rotX(p,vec3(0.0,.7,0.0),0.12+0.12*sin(ph*2.0));
 p*=vis;p.y+=bob*vis;
 float c=cos(aI1.w),s=sin(aI1.w);
 vec3 wp=vec3(p.x*c+p.z*s,p.y,-p.x*s+p.z*c)*1.0+aI1.xyz;
 vec3 wn=vec3(n.x*c+n.z*s,n.y,-n.x*s+n.z*c);
 gl_Position=uMVP*vec4(wp,1.0);vec3 no=wn*(dot(wn,uL)<0.0?-1.0:1.0);vSh=uLight*vec4(wp+no*uOff,1.0);vCol=col;vNorm=wn;vPos=wp;}`;
const fsV=HP+LIGHT+`varying vec3 vCol;varying vec3 vNorm;void main(){vec3 n=normalize(vNorm);if(dot(n,uEye-vPos)<0.0)n=-n;float sh;vec3 c=light(vCol,n,1.0,sh)*1.06;
 float l=dot(c,vec3(.3,.59,.11));c=mix(vec3(l),c,1.2);gl_FragColor=vec4(fogged(c),1.0);}`;
// Sombra suave (bolha) sob cada aldeão
const vsB=`attribute vec3 aPos;attribute vec4 aI1;uniform mat4 uMVP;varying vec2 vQ;void main(){vQ=aPos.xz;gl_Position=uMVP*vec4(aI1.xyz+vec3(aPos.x*.55,.06,aPos.z*.55),1.0);}`;
const fsB=HP+`varying vec2 vQ;void main(){float r=dot(vQ,vQ);if(r>1.0)discard;gl_FragColor=vec4(0.05,0.07,0.04,(1.0-r)*0.38);}`;
const dvs=`attribute vec3 aPos;uniform mat4 uLight;void main(){gl_Position=uLight*vec4(aPos,1.0);}`;
const dvsI=`attribute vec3 aPos;attribute vec4 aInst;attribute vec2 aInst2;uniform mat4 uLight;void main(){float c=cos(aInst2.x),s=sin(aInst2.x);vec3 p=vec3(aPos.x*c-aPos.z*s,aPos.y,aPos.x*s+aPos.z*c)*aInst.w+aInst.xyz;gl_Position=uLight*vec4(p,1.0);}`;
const dfs=HP+`void main(){vec4 r=fract(gl_FragCoord.z*vec4(16777216.0,65536.0,256.0,1.0));r-=r.xxyz*vec4(0.0,1.0/256.0,1.0/256.0,1.0/256.0);gl_FragColor=r;}`;
function shader(t,src){let s=gl.createShader(t);gl.shaderSource(s,src);gl.compileShader(s);if(!gl.getShaderParameter(s,gl.COMPILE_STATUS))throw Error(gl.getShaderInfoLog(s));return s}
const ATTRS=['aPos','aCol','aNorm','aInst','aInst2'];
function program(v,f,names=ATTRS){let p=gl.createProgram();gl.attachShader(p,shader(gl.VERTEX_SHADER,v));gl.attachShader(p,shader(gl.FRAGMENT_SHADER,f));
 names.forEach((n,i)=>gl.bindAttribLocation(p,i,n));gl.linkProgram(p);if(!gl.getProgramParameter(p,gl.LINK_STATUS))throw Error(gl.getProgramInfoLog(p));return p}
function locs(p,names){const o={};for(const n of names)o[n]=gl.getUniformLocation(p,n);return o}
const COMMON=['uMVP','uEye','uLight','uL','uOff','uTexel','uUseSh','uShadow','uFog'];
const VATTR=['aPos','aCol','aNorm','aI1','aI2','aI3','aPart'];
const opr=program(vsO,fsO),ipr=program(vsI,fsTree),tpr=program(vsT,fsT),wpr=program(vsW,fsW),dpr_=program(dvs,dfs),dipr=program(dvsI,dfs);
const vpr=INST?program(vsV,fsV,VATTR):null,bpr=INST?program(vsB,fsB,['aPos','xA','xB','aI1']):null;
const uO=locs(opr,COMMON.concat(['uTint'])),uI=locs(ipr,COMMON),uT=locs(tpr,COMMON.concat(['uCol','uNrm','uDet','uHalf','uDetFar','uTerr','uNT','uGrid','uSel','uTime'])),uW=locs(wpr,COMMON.concat(['uNrm','uDet','uHalf','uTime'])),uD=locs(dpr_,['uLight']),uDI=locs(dipr,['uLight']);
const uV=vpr?locs(vpr,COMMON):null,uB=bpr?locs(bpr,['uMVP']):null;
for(const [p,u] of [[opr,uO],[ipr,uI]].concat(vpr?[[vpr,uV]]:[])){gl.useProgram(p);gl.uniform1i(u.uShadow,0)}
gl.useProgram(tpr);gl.uniform1i(uT.uShadow,0);gl.uniform1i(uT.uCol,1);gl.uniform1i(uT.uNrm,2);gl.uniform1i(uT.uDet,3);gl.uniform2f(uT.uHalf,HX,HZ);
gl.useProgram(wpr);gl.uniform1i(uW.uShadow,0);gl.uniform1i(uW.uNrm,2);gl.uniform1i(uW.uDet,3);gl.uniform2f(uW.uHalf,HX,HZ);

/* ---------- Mapa de sombras ---------- */
gl.activeTexture(gl.TEXTURE0);
const SHS=Math.min(2048,gl.getParameter(gl.MAX_TEXTURE_SIZE),gl.getParameter(gl.MAX_RENDERBUFFER_SIZE));
const shTex=gl.createTexture();gl.bindTexture(gl.TEXTURE_2D,shTex);gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,SHS,SHS,0,gl.RGBA,gl.UNSIGNED_BYTE,null);
for(let [k,val] of [[gl.TEXTURE_MIN_FILTER,gl.NEAREST],[gl.TEXTURE_MAG_FILTER,gl.NEAREST],[gl.TEXTURE_WRAP_S,gl.CLAMP_TO_EDGE],[gl.TEXTURE_WRAP_T,gl.CLAMP_TO_EDGE]])gl.texParameteri(gl.TEXTURE_2D,k,val);
const shFB=gl.createFramebuffer(),shRB=gl.createRenderbuffer();gl.bindRenderbuffer(gl.RENDERBUFFER,shRB);gl.renderbufferStorage(gl.RENDERBUFFER,gl.DEPTH_COMPONENT16,SHS,SHS);
gl.bindFramebuffer(gl.FRAMEBUFFER,shFB);gl.framebufferTexture2D(gl.FRAMEBUFFER,gl.COLOR_ATTACHMENT0,gl.TEXTURE_2D,shTex,0);gl.framebufferRenderbuffer(gl.FRAMEBUFFER,gl.DEPTH_ATTACHMENT,gl.RENDERBUFFER,shRB);
const shadowsOK=gl.checkFramebufferStatus(gl.FRAMEBUFFER)===gl.FRAMEBUFFER_COMPLETE;gl.bindFramebuffer(gl.FRAMEBUFFER,null);gl.bindTexture(gl.TEXTURE_2D,null);

/* =====================================================================
   4. TEXTURAS
   ===================================================================== */
const aniso=gl.getExtension('EXT_texture_filter_anisotropic')||gl.getExtension('WEBKIT_EXT_texture_filter_anisotropic');
function setupTex(unit){const t=gl.createTexture();gl.activeTexture(gl.TEXTURE0+unit);gl.bindTexture(gl.TEXTURE_2D,t);gl.pixelStorei(gl.UNPACK_ALIGNMENT,1);return t}
function finishTex(wrap){gl.generateMipmap(gl.TEXTURE_2D);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MIN_FILTER,gl.LINEAR_MIPMAP_LINEAR);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MAG_FILTER,gl.LINEAR);
 gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_S,wrap);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_T,wrap);
 if(aniso)gl.texParameterf(gl.TEXTURE_2D,aniso.TEXTURE_MAX_ANISOTROPY_EXT,Math.min(MOBILE?2:4,gl.getParameter(aniso.MAX_TEXTURE_MAX_ANISOTROPY_EXT)));gl.activeTexture(gl.TEXTURE0)}
function uploadAlbedo(img){setupTex(1);gl.texImage2D(gl.TEXTURE_2D,0,gl.RGB,gl.RGB,gl.UNSIGNED_BYTE,img);finishTex(gl.CLAMP_TO_EDGE)}
function bakeNormals(){const W=1024,H=512,d=new Uint8Array(W*H*4),e=3,DIR=[[1,0],[-1,0],[0,1],[0,-1],[.7,.7],[-.7,.7],[.7,-.7],[-.7,-.7]];
 for(let j=0;j<H;j++){const z=-HZ+(j+.5)/H*WZ;for(let i=0;i<W;i++){const x=-HX+(i+.5)/W*WX,h=htF(x,z);
  const dx=(htF(x+e,z)-htF(x-e,z))/(2*e),dz=(htF(x,z+e)-htF(x,z-e))/(2*e),il=1/Math.sqrt(1+dx*dx+dz*dz);
  let a1=0,a2=0;for(const [p,q] of DIR){a1+=htF(x+p*9,z+q*9);a2+=htF(x+p*30,z+q*30)}a1/=8;a2/=8;
  const ao=clamp(1+(h-a1)*.06+(h-a2)*.02,.62,1.08),o=(j*W+i)*4;
  d[o]=(-dx*il*.5+.5)*255;d[o+1]=(-dz*il*.5+.5)*255;d[o+2]=ao/1.1*255;d[o+3]=clamp((h+40)/50,0,1)*255}}
 setupTex(2);gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,W,H,0,gl.RGBA,gl.UNSIGNED_BYTE,d);finishTex(gl.CLAMP_TO_EDGE)}
function bakeDetail(){const N=256,d=new Uint8Array(N*N);const ph=(i,j,p)=>hash2(((i%p)+p)%p+.13*p,((j%p)+p)%p-.71*p);
 const pn=(x,y,p)=>{let i=Math.floor(x),j=Math.floor(y),u=x-i,v=y-j;u=u*u*(3-2*u);v=v*v*(3-2*v);return (ph(i,j,p)*(1-u)+ph(i+1,j,p)*u)*(1-v)+(ph(i,j+1,p)*(1-u)+ph(i+1,j+1,p)*u)*v};
 const OCT=[[4,.3],[8,.25],[16,.2],[32,.15],[64,.1]];
 for(let y=0;y<N;y++)for(let x=0;x<N;x++){let s=0;for(const [p,w] of OCT)s+=w*pn(x*p/N,y*p/N,p);s+=.1*hash2(x*.91,y*1.13);d[y*N+x]=clamp((s-.5)*1.7+.5,0,1)*255}
 setupTex(3);gl.texImage2D(gl.TEXTURE_2D,0,gl.LUMINANCE,N,N,0,gl.LUMINANCE,gl.UNSIGNED_BYTE,d);finishTex(gl.REPEAT)}

/* =====================================================================
   5. TERRENO EM BLOCOS + ÁGUA
   ===================================================================== */
const chunks=[];let chunkIdx=null,chunkIdxCount=0;
function buildChunks(){
 const V=CS+1,idx=new Uint16Array(CS*CS*6);let q=0;for(let j=0;j<CS;j++)for(let i=0;i<CS;i++){const a=j*V+i,b=a+1,c=a+V,d=c+1;idx[q++]=a;idx[q++]=c;idx[q++]=d;idx[q++]=a;idx[q++]=d;idx[q++]=b}
 chunkIdx=gl.createBuffer();gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER,chunkIdx);gl.bufferData(gl.ELEMENT_ARRAY_BUFFER,idx,gl.STATIC_DRAW);chunkIdxCount=idx.length;
 for(let cj=0;cj<NZ/CS;cj++)for(let ci=0;ci<NX/CS;ci++){
  const pos=new Float32Array(V*V*3),nor=new Float32Array(V*V*3);let mn=1e9,mx=-1e9;
  for(let j=0;j<V;j++)for(let i=0;i<V;i++){const gi=ci*CS+i,gj=cj*CS+j,x=-HX+gi*CX,z=-HZ+gj*CZ,W=NX+1,h=NH[gj*W+gi],o=(j*V+i)*3;
   const hl=NH[gj*W+Math.max(gi-1,0)],hr=NH[gj*W+Math.min(gi+1,NX)],hd=NH[Math.max(gj-1,0)*W+gi],hu=NH[Math.min(gj+1,NZ)*W+gi];
   const dx=(hr-hl)/(2*CX),dz=(hu-hd)/(2*CZ),il=1/Math.sqrt(1+dx*dx+dz*dz);
   pos[o]=x;pos[o+1]=h;pos[o+2]=z;nor[o]=-dx*il;nor[o+1]=il;nor[o+2]=-dz*il;mn=Math.min(mn,h);mx=Math.max(mx,h)}
  const p=gl.createBuffer(),n=gl.createBuffer();gl.bindBuffer(gl.ARRAY_BUFFER,p);gl.bufferData(gl.ARRAY_BUFFER,pos,gl.STATIC_DRAW);gl.bindBuffer(gl.ARRAY_BUFFER,n);gl.bufferData(gl.ARRAY_BUFFER,nor,gl.STATIC_DRAW);
  chunks.push({p,n,box:[-HX+ci*CS*CX,mn,-HZ+cj*CS*CZ,-HX+(ci+1)*CS*CX,mx,-HZ+(cj+1)*CS*CZ],under:mx<-.5})}}
const waterBuf=gl.createBuffer();
(function(){const R=14000;gl.bindBuffer(gl.ARRAY_BUFFER,waterBuf);gl.bufferData(gl.ARRAY_BUFFER,new Float32Array([-R,0,-R,R,0,-R,R,0,R,-R,0,-R,R,0,R,-R,0,R]),gl.STATIC_DRAW)})();
function boxVisible(m,b){const out=[0,0,0,0,0,0];for(let k=0;k<8;k++){const x=k&1?b[3]:b[0],y=k&2?b[4]:b[1],z=k&4?b[5]:b[2];
 const cx=m[0]*x+m[4]*y+m[8]*z+m[12],cy=m[1]*x+m[5]*y+m[9]*z+m[13],cz=m[2]*x+m[6]*y+m[10]*z+m[14],cw=m[3]*x+m[7]*y+m[11]*z+m[15];
 if(cx<-cw)out[0]++;if(cx>cw)out[1]++;if(cy<-cw)out[2]++;if(cy>cw)out[3]++;if(cz<-cw)out[4]++;if(cz>cw)out[5]++}
 return out.every(c=>c<8)}
