/* =====================================================================
   CITY BUILDER — shaders extras (aldeões animados e sombra-bolha).
   O motor do mapa (terreno, água, rios, províncias, sombras) vem do
   arquivo "Reinos 3D — Reinos Independentes" e é mantido como está.
   ===================================================================== */
function programN(v,f,names){let p=gl.createProgram();gl.attachShader(p,shader(gl.VERTEX_SHADER,v));gl.attachShader(p,shader(gl.FRAGMENT_SHADER,f));
 names.forEach((n,i)=>gl.bindAttribLocation(p,i,n));gl.linkProgram(p);if(!gl.getProgramParameter(p,gl.LINK_STATUS))throw Error(gl.getProgramInfoLog(p));return p}
// Aldeões: um modelo articulado instanciado. Cada vértice sabe a que peça pertence (aPart)
// e o shader anima pernas, braços, ferramentas e o fardo carregado.
const vsV=`attribute vec3 aPos;attribute vec3 aCol;attribute vec3 aNorm;attribute vec4 aI1;attribute vec4 aI2;attribute vec4 aI3;attribute float aPart;
uniform mat4 uMVP;uniform mat4 uLight;uniform vec3 uL;uniform float uOff;varying vec3 vCol;varying vec3 vNorm;varying vec3 vPos;varying vec4 vSh;
vec3 rotX(vec3 p,vec3 piv,float a){p-=piv;float c=cos(a),s=sin(a);return vec3(p.x,p.y*c-p.z*s,p.y*s+p.z*c)+piv;}
void main(){
 float part=mod(aPart,10.0),acc=floor(aPart/10.0+0.01);float ph=aI2.x,mode=aI2.y,role=aI2.z,carry=aI2.w;
 vec3 p=aPos,n=aNorm,col=aCol;
 if(col.r<-1.5)col=mix(vec3(.30,.18,.10),mix(vec3(.85,.62,.28),vec3(.12,.08,.06),step(.5,aI3.w)),fract(aI3.w*2.0))*col.g;else if(col.r<0.0)col=aI3.rgb*col.g;
 float vis=1.0;
 if(acc>0.5&&acc<4.5)vis=(abs(acc-role)<0.5&&carry<0.5)?1.0:0.0;
 if(acc>5.5&&acc<6.5)vis=abs(role-3.0)<0.5?1.0:0.0;
 if(acc>4.5&&acc<5.5){vis=carry>0.5?1.0:0.0;
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
 vec3 wp=vec3(p.x*c+p.z*s,p.y,-p.x*s+p.z*c)+aI1.xyz;
 vec3 wn=vec3(n.x*c+n.z*s,n.y,-n.x*s+n.z*c);
 gl_Position=uMVP*vec4(wp,1.0);vec3 no=wn*(dot(wn,uL)<0.0?-1.0:1.0);vSh=uLight*vec4(wp+no*uOff,1.0);vCol=col;vNorm=wn;vPos=wp;}`;
const fsV=HP+LIGHT+`varying vec3 vCol;varying vec3 vNorm;void main(){vec3 n=normalize(vNorm);if(dot(n,uEye-vPos)<0.0)n=-n;float sh;vec3 c=light(vCol,n,1.0,sh)*1.06;
 float l=dot(c,vec3(.3,.59,.11));c=mix(vec3(l),c,1.2);gl_FragColor=vec4(fogged(c),1.0);}`;
const vsB=`attribute vec3 aPos;attribute vec4 aI1;uniform mat4 uMVP;varying vec2 vQ;void main(){vQ=aPos.xz;gl_Position=uMVP*vec4(aI1.xyz+vec3(aPos.x*.55,.06,aPos.z*.55),1.0);}`;
const fsB=HP+`varying vec2 vQ;void main(){float r=dot(vQ,vQ);if(r>1.0)discard;gl_FragColor=vec4(0.05,0.07,0.04,(1.0-r)*0.38);}`;
const vpr=INST?programN(vsV,fsV,['aPos','aCol','aNorm','aI1','aI2','aI3','aPart']):null,bpr=INST?programN(vsB,fsB,['aPos','xA','xB','aI1']):null;
const uV=vpr?locs(vpr,COMMON):null,uB=bpr?locs(bpr,['uMVP']):null;
if(vpr){gl.useProgram(vpr);gl.uniform1i(uV.uShadow,0)}
