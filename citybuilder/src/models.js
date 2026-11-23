/* =====================================================================
   6. MODELOS 3D EM ESTILO "IDLE" (low-poly, cores vivas, formas robustas)
   Cada modelo é montado uma vez em coordenadas locais (base em y=0, centro
   na origem) e depois "carimbado" no mundo com giro, escala e posição.
   ===================================================================== */
class Geo{constructor(){this.p=[];this.c=[];this.n=[];this.a=[]}get count(){return this.p.length/3}}
let G=new Geo(),PART=0;
function v(p,c,n){G.p.push(p[0],p[1],p[2]);G.c.push(c[0],c[1],c[2]);G.n.push(n[0],n[1],n[2]);G.a.push(PART)}
function tri(a,b,c,col){let ab=[b[0]-a[0],b[1]-a[1],b[2]-a[2]],ac=[c[0]-a[0],c[1]-a[1],c[2]-a[2]];let n=[ab[1]*ac[2]-ab[2]*ac[1],ab[2]*ac[0]-ab[0]*ac[2],ab[0]*ac[1]-ab[1]*ac[0]],len=Math.hypot(n[0],n[1],n[2])||1;n=[n[0]/len,n[1]/len,n[2]/len];v(a,col,n);v(b,col,n);v(c,col,n)}
function quad(a,b,c,d,col){tri(a,b,c,col);tri(a,c,d,col)}
function C(c){return typeof c==='string'?hex(c):c}
// Caixa com base em y. top: cor opcional da face de cima.
function box(x,y,z,w,h,d,col,top){col=C(col);const tc=top?C(top):col;let a=[x-w/2,y,z-d/2],b=[x+w/2,y,z-d/2],c=[x+w/2,y,z+d/2],e=[x-w/2,y,z+d/2],A=[a[0],y+h,a[2]],B=[b[0],y+h,b[2]],Cc=[c[0],y+h,c[2]],E=[e[0],y+h,e[2]];
 quad(a,b,B,A,col);quad(b,c,Cc,B,col);quad(c,e,E,Cc,col);quad(e,a,A,E,col);quad(A,B,Cc,E,tc);quad(a,e,c,b,col)}
// Caixa chanfrada (cantos superiores biselados) — dá o aspecto "de brinquedo"
function bbox(x,y,z,w,h,d,col,bev=.12,top){col=C(col);const tc=top?C(top):mixC(col,[1,1,1],.08);const b=Math.min(bev,w/3,d/3,h/3);
 box(x,y,z,w,h-b,d,col);const y1=y+h-b,y2=y+h;const P=(px,py,pz)=>[x+px,py,z+pz],W=w/2,D=d/2;
 quad(P(-W+b,y2,-D+b),P(-W+b,y2,D-b),P(W-b,y2,D-b),P(W-b,y2,-D+b),tc);
 quad(P(-W,y1,-D),P(-W+b,y2,-D+b),P(W-b,y2,-D+b),P(W,y1,-D),col);quad(P(W,y1,D),P(W-b,y2,D-b),P(-W+b,y2,D-b),P(-W,y1,D),col);
 quad(P(-W,y1,D),P(-W+b,y2,D-b),P(-W+b,y2,-D+b),P(-W,y1,-D),col);quad(P(W,y1,-D),P(W-b,y2,-D+b),P(W-b,y2,D-b),P(W,y1,D),col)}
function cone(x,y,z,r,h,col,sides=8){col=C(col);let apex=[x,y+h,z];for(let j=0;j<sides;j++){let a=j*Math.PI*2/sides,b=(j+1)*Math.PI*2/sides;tri([x+r*Math.cos(a),y,z+r*Math.sin(a)],[x+r*Math.cos(b),y,z+r*Math.sin(b)],apex,col)}}
function cyl(x,y,z,r,h,col,sides=10,top){col=C(col);const tc=top?C(top):col;for(let j=0;j<sides;j++){let a=j*Math.PI*2/sides,b=(j+1)*Math.PI*2/sides;const p0=[x+r*Math.cos(a),y,z+r*Math.sin(a)],p1=[x+r*Math.cos(b),y,z+r*Math.sin(b)];
 quad(p0,[p0[0],y+h,p0[2]],[p1[0],y+h,p1[2]],p1,col);tri([x,y+h,z],[p1[0],y+h,p1[2]],[p0[0],y+h,p0[2]],tc)}}
// Cilindro deitado no eixo X ou Z (toras)
function log(x,y,z,r,len,axis,col,sides=7){col=C(col);const end=mixC(col,hex('#e8c27a'),.55);for(let j=0;j<sides;j++){let a=j*Math.PI*2/sides,b=(j+1)*Math.PI*2/sides;
 const P=(t,ang)=>axis==='x'?[x+t,y+r*Math.sin(ang),z+r*Math.cos(ang)]:[x+r*Math.cos(ang),y+r*Math.sin(ang),z+t];
 quad(P(-len/2,a),P(-len/2,b),P(len/2,b),P(len/2,a),col);tri(P(len/2,a),P(len/2,b),axis==='x'?[x+len/2,y,z]:[x,y,z+len/2],end);tri(P(-len/2,b),P(-len/2,a),axis==='x'?[x-len/2,y,z]:[x,y,z-len/2],end)}}
function roof(x,y,z,w,d,h,col,gable){col=C(col);const gc=gable?C(gable):mixC(col,[0,0,0],.15);let a=[x-w/2,y,z-d/2],b=[x+w/2,y,z-d/2],c=[x+w/2,y,z+d/2],e=[x-w/2,y,z+d/2],r=[x,y+h,z-d/2],s=[x,y+h,z+d/2];quad(a,e,s,r,col);quad(b,r,s,c,col);tri(a,r,b,gc);tri(e,c,s,gc)}
// Placa com espessura a partir de 4 cantos do topo
function slab(a,b,c,d,t,col,side){const dn=p=>[p[0],p[1]-t,p[2]];quad(a,b,c,d,col);quad(dn(a),dn(d),dn(c),dn(b),side);quad(a,dn(a),dn(b),b,side);quad(b,dn(b),dn(c),c,side);quad(c,dn(c),dn(d),d,side);quad(d,dn(d),dn(a),a,side)}
// Telhado de duas águas com beiral grosso (estilo idle)
function thickRoof(x,y,z,w,d,h,col,wall,ov=.35,t=.28){col=C(col);const side=mixC(col,[0,0,0],.28);const W=w/2+ov,D=d/2+ov,k=h/(w/2),ye=y-ov*k+t;
 roof(x,y,z,w,d,h,wall||mixC(col,[1,1,1],.5));
 slab([x-W,ye,z-D],[x-W,ye,z+D],[x,y+h+t,z+D],[x,y+h+t,z-D],t,col,side);
 slab([x,y+h+t,z-D],[x,y+h+t,z+D],[x+W,ye,z+D],[x+W,ye,z-D],t,col,side);
 box(x,y+h+t*.6,z,.3,.3,2*D+.1,mixC(col,[0,0,0],.12))}
function pyramid(x,y,z,w,d,h,col){col=C(col);const a=[x-w/2,y,z-d/2],b=[x+w/2,y,z-d/2],c=[x+w/2,y,z+d/2],e=[x-w/2,y,z+d/2],t=[x,y+h,z];tri(a,t,b,col);tri(b,t,c,col);tri(c,t,e,col);tri(e,t,a,col)}
function ball(x,y,z,r,col,sy=1,rings=4,sides=8,shade=true){col=C(col);for(let j=0;j<rings;j++){let a0=-Math.PI/2+j*Math.PI/rings,a1=-Math.PI/2+(j+1)*Math.PI/rings;
 for(let i=0;i<sides;i++){let t0=i*2*Math.PI/sides,t1=(i+1)*2*Math.PI/sides;const Pt=(a,t)=>[x+r*Math.cos(a)*Math.cos(t),y+r*sy*Math.sin(a),z+r*Math.cos(a)*Math.sin(t)];
  const occ=shade?.82+.22*j/(rings-1):1;quad(Pt(a0,t0),Pt(a1,t0),Pt(a1,t1),Pt(a0,t1),col.map(q=>q*occ))}}}
function bush(x,y,z,r,col='#4f9a3c'){ball(x,y+r*.6,z,r,col,.8,3,7);ball(x+r*.5,y+r*.45,z+r*.3,r*.6,mixC(C(col),hex('#a6d16a'),.25),.8,3,6)}
function flowers(x,y,z,w,d){box(x,y,z,w,.35,d,'#7a5232');const cs=['#ff5d73','#ffd23f','#ffffff','#b56cff'];for(let i=0;i<Math.max(2,Math.round(w/.35));i++){const xx=x-w/2+.2+i*(w-.4)/Math.max(1,Math.round(w/.35)-1);ball(xx,y+.42,z,.13,cs[i%4],1,2,5,false)}}
function fence(x,z,w,d,y=0,gapFront=0){const post='#9b6b3f',rail='#c08a55';const posts=(x0,z0,x1,z1)=>{const L=Math.hypot(x1-x0,z1-z0),n=Math.max(1,Math.round(L/1.3));for(let i=0;i<=n;i++){const t=i/n;box(x0+(x1-x0)*t,y,z0+(z1-z0)*t,.18,.75,.18,post)}
 const cx=(x0+x1)/2,cz=(z0+z1)/2;if(Math.abs(x1-x0)>Math.abs(z1-z0)){box(cx,y+.45,cz,L,.1,.08,rail);box(cx,y+.2,cz,L,.1,.08,rail)}else{box(cx,y+.45,cz,.08,.1,L,rail);box(cx,y+.2,cz,.08,.1,L,rail)}};
 const W=w/2,D=d/2;posts(-W+x,-D+z,W+x,-D+z);posts(-W+x,-D+z,-W+x,D+z);posts(W+x,-D+z,W+x,D+z);
 if(gapFront>0){posts(-W+x,D+z,x-gapFront/2,D+z);posts(x+gapFront/2,D+z,W+x,D+z)}else posts(-W+x,D+z,W+x,D+z)}
function barrel(x,y,z,r=.32,h=.75){cyl(x,y,z,r,h,'#a5693a',8,'#c48a52');cyl(x,y+.12,z,r+.02,.08,'#5b5b62',8);cyl(x,y+h-.2,z,r+.02,.08,'#5b5b62',8)}
function crate(x,y,z,s=.6,col='#c28a4d'){box(x,y,z,s,s,s,col);box(x,y+s*.45,z,s+.02,s*.1,s+.02,mixC(C(col),[0,0,0],.25))}
function sack(x,y,z,col='#e3cf9d'){ball(x,y+.28,z,.3,col,1.1,3,6);box(x,y+.55,z,.18,.12,.18,mixC(C(col),[0,0,0],.2))}
function windowF(x,y,z,face,w=.6,h=.7){// janela com moldura branca e vidro azul-escuro; face: 'z+','z-','x+','x-'
 const fr='#f6efe0',gl_='#36506b',t=.08;if(face[0]==='z'){const s=face[1]==='+'?1:-1;box(x,y,z+s*.02,w+.16,h+.16,t,fr);box(x,y+.08,z+s*.07,w,h,t,gl_);box(x,y+.08+h/2-.04,z+s*.1,w,.07,t,fr);box(x,y-.06,z+s*.12,w+.3,.12,.22,fr)}
 else{const s=face[1]==='+'?1:-1;box(x+s*.02,y,z,t,h+.16,w+.16,fr);box(x+s*.07,y+.08,z,t,h,w,gl_);box(x+s*.1,y+.08+h/2-.04,z,t,.07,w,fr);box(x+s*.12,y-.06,z,.22,.12,w+.3,fr)}}
function door(x,y,z,w=.9,h=1.5,col='#7b4a2a'){box(x,y,z,w+.2,h+.12,.12,'#5a3a22');box(x,y,z+.05,w,h,.12,col);box(x+w*.3,y+h*.45,z+.13,.1,.1,.06,'#e2b64b')}
function flagpole(x,y,z,h){cyl(x,y,z,.07,h,'#6b5137',5);ball(x,y+h+.05,z,.12,'#ffd34d',1,2,6,false)}

/* ---------- Construções ---------- */
const PAL={wall:'#f3e3c3',wall2:'#e9d2a8',timber:'#8a5a36',roofR:'#d9553f',roofO:'#e98a3a',roofB:'#4a78c4',roofG:'#4f9a55',roofP:'#8a5bc2',stone:'#b9b6ad',stone2:'#9c9a93',stoneD:'#7d7c78',wood:'#b07a48',woodD:'#7a5232',gold:'#f3c43c',grass:'#7cc35a',path:'#d8c39a',dirt:'#a07a4f'};

function mHouse(L){
 const sz=L>=3?4.6:4.0,wh=L>=3?2.2:2.5;
 if(L>=5){bbox(0,0,0,sz+.3,1.1,3.7,PAL.stone,.1);}
 bbox(0,L>=5?1.0:0,-.2,sz,wh,3.4,PAL.wall,.08);
 // enxaimel
 for(const s of [-1,1])box(s*(sz/2-.05),0,1.5,.22,wh,.16,PAL.timber);box(0,wh-.18,1.52,sz,.2,.16,PAL.timber);
 door(-.6,L>=5?1.0:0,1.45);windowF(.9,(L>=5?1.0:0)+.9,1.47,'z+');windowF(sz/2,(L>=5?1:0)+.9,-.2,'x+',.55,.6);windowF(-sz/2,(L>=5?1:0)+.9,-.2,'x-',.55,.6);
 let top=(L>=5?1.0:0)+wh;
 if(L>=3){// segundo andar em balanço
  bbox(0,top,-.2,sz+.35,1.9,3.7,PAL.wall2,.06);for(const s of [-1,0,1])box(s*(sz/2),top,1.66,.2,1.9,.14,PAL.timber);
  windowF(-.9,top+.6,1.7,'z+',.55,.6);windowF(.9,top+.6,1.7,'z+',.55,.6);top+=1.9}
 thickRoof(0,top,-.2,sz+.2,3.6,L>=3?2.3:2.0,L>=4?PAL.roofB:PAL.roofR,PAL.wall2);
 if(L>=2){box(1.1,top+.4,-1.0,.6,1.9,.6,PAL.stone2);box(1.1,top+2.2,-1.0,.75,.18,.75,PAL.stoneD);flowers(.9,(L>=5?1:0)+.35,1.85,1.1,.3)}
 if(L>=2){fence(0,.2,7.4,7.2,0,1.6)}
 if(L>=4){bbox(-3.0,0,-1.6,1.6,1.7,1.8,PAL.wall,.06);thickRoof(-3.0,1.7,-1.6,1.6,1.8,.9,PAL.roofB,PAL.wall2,.2,.18);bush(2.8,0,2.6,.6)}
 if(L>=5){flagpole(2.9,0,-2.9,3.6)}
 bush(-2.6,0,2.7,.5);
}
function mFarm(L){
 // campo de trigo em fileiras
 const rows=L>=3?7:5,fw=L>=3?13:9;
 for(let r=0;r<rows;r++){const z=-6+r*1.25;box(-1.5+(L>=3?1.5:0)-2,0,z,fw,.18,.9,'#8d6239');
  for(let k=0;k<Math.round(fw/.9);k++){const x=-1.5+(L>=3?1.5:0)-2-fw/2+.45+k*.9;const ht=.55+hash2(r*7+k,L)*.25;box(x,.18,z,.5,ht,.5,(r+k)%3?'#e8c351':'#d9b23d','#f4d56b')}}
 // celeiro vermelho
 const bx=L>=3?4.6:4.2,bz=L>=3?4.4:2.2;
 bbox(bx,0,bz,3.6,2.4,3.4,'#c8443a',.1);for(const s of [-1,1])box(bx+s*1.0,.0,bz+1.71,.14,2.4,.1,'#f6efe0');box(bx,2.3,bz+1.72,3.6,.14,.1,'#f6efe0');
 box(bx,0,bz+1.72,1.4,1.7,.1,'#8f2e27');box(bx,.0,bz+1.78,1.4,.12,.1,'#f6efe0');for(const s of [-1,1])box(bx,0,bz+1.8,.1,1.7,.08,'#f6efe0');
 thickRoof(bx,2.4,bz,3.6,3.4,1.6,'#6b4a3a','#c8443a',.25,.2);
 if(L>=2){// moinho (pás animadas à parte)
  const mx=-5.6,mz=4.6;cyl(mx,0,mz,1.25,.4,PAL.stone2,10);cone(mx,.4,mz,1.2,0.01,PAL.stone2,10);cyl(mx,.4,mz,1.05,3.8,'#f1e6cf',10);cone(mx,4.2,mz,1.35,1.6,PAL.roofR,10);door(mx,.4,mz+1.0,.6,1.0)}
 if(L>=3){for(const [x,z] of [[6.4,-1.2],[5.2,-2.6]]){cyl(x,0,z,.6,.8,'#e8c351',8,'#f4d56b')}}
 if(L>=4){cyl(-1.8,0,5.6,1,3.4,'#d9d4c9',10);cone(-1.8,3.4,5.6,1.15,1,'#4a78c4',10)}
 if(L>=5){box(-6.5,0,-6.6,.12,1.8,.12,PAL.woodD);box(-6.5,1.2,-6.6,1.1,.12,.12,PAL.woodD);ball(-6.5,1.95,-6.6,.28,'#e3cf9d');cone(-6.5,2.1,-6.6,.45,.4,'#d9b23d')}
 fence(0,0,15.4,15.4,0,2.5);
}
function mLumber(L){
 // cabana de toras
 const cx=-1.2,cz=-1.4;for(let i=0;i<5;i++){log(cx,.25+i*.45,cz-1.5,.24,4.4,'x',i%2?'#9a643a':'#a8703f');log(cx,.25+i*.45,cz+1.5,.24,4.4,'x',i%2?'#9a643a':'#a8703f');log(cx-2.0,.25+i*.45,cz,.24,3.4,'z','#93603a');log(cx+2.0,.25+i*.45,cz,.24,3.4,'z','#93603a')}
 box(cx,0,cz,3.8,2.2,2.8,'#7b5233');door(cx,0,cz+1.55,.8,1.4,'#5a3a22');windowF(cx+1.2,1.0,cz+1.62,'z+',.5,.5);
 thickRoof(cx,2.3,cz,4.5,3.4,1.6,PAL.roofG,'#93603a',.3,.25);
 box(cx+1.3,2.6,cz-.6,.5,1.4,.5,PAL.stone2);
 // pilha de toras
 const n=L>=2?3:2;for(let r=0;r<n;r++)for(let k=0;k<n+1-r;k++)log(3.0,.28+r*.48,-2.6+k*.52+r*.26,.25,2.6,'x','#a8703f');
 // cepo com machado
 cyl(2.6,0,2.4,.45,.6,'#8b5a33',8,'#e0b071');box(2.75,.6,2.35,.08,.8,.08,'#6b4a2e');box(2.75,1.2,2.5,.07,.3,.35,'#c9ccd1');
 if(L>=3){for(const s of [-1,1])box(-3.6,0,2.4+s*.5,.15,.8,.15,PAL.woodD);log(-3.6,.85,2.4,.22,1.8,'z','#a8703f');box(-3.6,.85,1.8,.02,.9,.3,'#c9ccd1')}
 if(L>=4){// carroça
  box(1.0,.5,4.0,2.0,.5,1.2,PAL.wood);for(const s of [-1,1])log(1.0+s*.8,.4,4.0,.4,.12,'z','#6b4a2e',8);box(-.4,.7,4.0,1.2,.08,.08,PAL.woodD);for(let i=0;i<3;i++)log(1.0,1.15,3.7+i*.32,.15,1.8,'x','#c08a55')}
 if(L>=5){for(let i=0;i<4;i++)box(4.6,i*.3,1.2,1.8,.25,1.2,i%2?'#d9a066':'#c98f56')}
 bush(-4.6,0,-4.4,.7,'#3f8a3a');bush(4.6,0,-4.6,.55,'#3f8a3a');
}
function mQuarry(L){
 // rochas e blocos de pedra
 ball(-2.8,0,-3.0,2.0,PAL.stone2,.75,3,7);ball(-1.0,0,-3.8,1.4,PAL.stone,.8,3,6);ball(-4.2,0,-1.6,1.1,PAL.stoneD,.8,3,6);
 bbox(2.4,0,-2.6,2.8,1.9,2.4,'#d8cdb4',.08);door(2.4,0,-1.35,.8,1.3,'#5a3a22');thickRoof(2.4,1.9,-2.6,2.8,2.4,1.1,PAL.roofB,'#d8cdb4',.25,.2);
 const piles=L>=3?3:2;for(let p=0;p<piles;p++){const px=-2.4+p*2.6,pz=2.6;for(let r=0;r<2;r++)for(let k=0;k<2-r;k++)bbox(px+k*.75-.37+r*.37,r*.6,pz,.7,.6,.7,p%2?PAL.stone:'#cfccc4',.08)}
 if(L>=2){// guindaste de madeira (braço animado à parte)
  box(3.8,0,2.2,.3,4.2,.3,PAL.woodD);box(3.8,0,2.2,1.4,.3,1.4,PAL.wood)}
 if(L>=4){box(0,0,4.6,5,.12,.6,'#8b7a66');for(let i=0;i<5;i++)box(-2+i,.12,4.6,.15,.08,.8,PAL.woodD)}
 if(L>=5){bbox(-4.4,0,2.6,1.4,2.2,1.4,PAL.stone,.1);ball(-4.4,2.4,2.6,.4,PAL.gold,1,3,6)}
}
function mMine(L){
 // monte rochoso com entrada escorada
 ball(0,0,-1.6,4.2,'#8f877a',.7,4,9);ball(-2.8,0,-2.6,2.4,'#a39a8a',.8,3,7);ball(2.9,0,-2.2,2.6,'#7d766b',.75,3,7);
 box(0,0,1.2,2.2,2.3,1.0,'#1d1a18');for(const s of [-1,1])box(s*1.15,0,1.75,.3,2.4,.3,PAL.woodD);box(0,2.3,1.75,2.7,.35,.36,PAL.woodD);
 // trilhos e vagonete com ouro
 for(let i=0;i<5;i++)box(0,.05,2.4+i*.8,1.4,.1,.22,PAL.woodD);for(const s of [-1,1])box(s*.5,.15,4.0,.08,.08,4.4,'#8c8f96');
 box(0,.35,3.6,1.3,.8,1.6,'#5b5f66');box(0,1.0,3.6,1.36,.1,1.66,'#3e4147');for(let k=0;k<5;k++)ball(-.35+k*.18,1.1,3.3+(k%3)*.3,.22,PAL.gold,1,2,6,false);
 for(const s of [-1,1])for(const t of [-1,1])cyl(s*.62,.18,3.6+t*.5,.2,.1,'#2e3036',6);
 if(L>=2){box(1.6,0,2.2,.12,1.8,.12,PAL.woodD);box(1.6,1.6,2.35,.35,.4,.35,'#ffcf5a')}
 if(L>=3){box(-3.2,0,3.0,1.0,.8,1.0,'#5b5f66');for(let k=0;k<3;k++)ball(-3.4+k*.2,.85,3.0,.2,PAL.gold,1,2,6,false)}
 if(L>=4){bbox(3.4,0,3.2,2,1.6,1.8,'#d8cdb4',.06);thickRoof(3.4,1.6,3.2,2,1.8,.9,PAL.roofO,'#d8cdb4',.2,.18)}
 if(L>=5){flagpole(-1.8,2.6,-.4,2.4)}
}
function awning(x,y,z,w,d,c1,c2){const n=6;for(let i=0;i<n;i++){const xx=x-w/2+(i+.5)*w/n;const a=[xx-w/n/2,y+.5,z-d/2],b=[xx+w/n/2,y+.5,z-d/2],c=[xx+w/n/2,y,z+d/2],e=[xx-w/n/2,y,z+d/2];quad(a,e,c,b,i%2?c1:c2);box(xx,y-.28,z+d/2,w/n,.3,.05,i%2?c1:c2)}}
function stall(x,z,c1,goods){for(const s of [-1,1])for(const t of [-1,1])box(x+s*1.1,0,z+t*.7,.14,1.9,.14,PAL.woodD);box(x,.75,z+.3,2.3,.18,.9,PAL.wood);box(x,0,z+.3,2.2,.75,.85,'#9a643a');
 awning(x,1.9,z,2.6,1.9,C(c1),hex('#f6efe0'));for(let k=0;k<4;k++)ball(x-.75+k*.5,1.05,z+.4,.18,goods[k%goods.length],1,2,6,false)}
function mMarket(L){
 box(0,0,0,11.4,.12,11.4,'#d9c7a0');// praça de pedra
 for(let i=0;i<4;i++)for(let j=0;j<4;j++)if((i+j)%2)box(-4.3+i*2.86,.12,-4.3+j*2.86,2.7,.04,2.7,'#cbb98f');
 stall(-2.8,-2.6,'#d9553f',['#ff5d4f','#ffd23f','#7cc35a']);stall(2.8,-2.6,'#4a78c4',['#e98a3a','#b56cff','#ffffff']);
 if(L>=2)stall(-2.8,2.4,'#4f9a55',['#d9b23d','#a07a4f','#ff5d4f']);if(L>=3)stall(2.8,2.4,'#8a5bc2',['#f3c43c','#7cc35a','#e98a3a']);
 // fonte central
 cyl(0,.12,0,1.1,.5,PAL.stone,10,'#5fb0d6');cyl(0,.5,0,.22,1.0,PAL.stone,8);cyl(0,1.4,0,.5,.18,PAL.stone,8,'#5fb0d6');
 for(let k=0;k<(L>=4?6:3);k++)crate(-5+k*.8,.12,5,.55,k%2?'#c28a4d':'#a5733f');
 if(L>=5){flagpole(-5,.12,-5,4);flagpole(5,.12,-5,4)}
 if(L>=2)sack(4.8,.12,4.8);
}
function mTavern(L){
 bbox(0,0,-.8,6.2,2.4,5,PAL.stone,.08);door(0,0,1.72,1.1,1.7,'#7b4a2a');windowF(-1.9,.9,1.75,'z+',.7,.7);windowF(1.9,.9,1.75,'z+',.7,.7);
 bbox(0,2.4,-.8,6.6,2.0,5.4,PAL.wall,.06);for(const s of [-1,-.33,.33,1])box(s*3.2,2.4,1.92,.2,2.0,.14,PAL.timber);box(0,2.4,1.94,6.6,.18,.14,PAL.timber);
 windowF(-1.6,2.9,1.98,'z+',.6,.6);windowF(1.6,2.9,1.98,'z+',.6,.6);
 thickRoof(0,4.4,-.8,6.8,5.6,2.4,PAL.roofO,PAL.wall2,.35,.28);box(-2,5.3,-2,.7,2.2,.7,PAL.stone2);
 // placa pendurada
 box(1.2,2.6,2.6,.1,.1,1.4,PAL.woodD);box(1.2,1.7,3.2,.08,.8,.9,'#e3cf9d');ball(1.2,2.1,3.26,.18,'#c8443a',1,2,5,false);
 barrel(-3.6,0,2.4);barrel(-3.2,0,3.2);if(L>=2){barrel(-3.6,.75,2.8)}
 if(L>=3){box(2.6,0,4.2,1.8,.85,.9,PAL.wood);for(const s of [-1,1])box(2.6,0,4.2+s*.9,1.8,.45,.3,PAL.woodD)}
 if(L>=4){bbox(4.2,0,-1.8,2,2,2.4,PAL.wall,.06);thickRoof(4.2,2,-1.8,2,2.4,1,PAL.roofO,PAL.wall2,.2,.18)}
 if(L>=5){flagpole(-4.4,0,-3.6,4.4)}
}
function mWarehouse(L){
 const w=L>=3?8:7,d=L>=3?6.2:5.4;
 bbox(0,0,-.8,w,3.2,d,'#a8703f',.1);for(let i=0;i<=4;i++)box(-w/2+i*w/4,0,-.8+d/2+.02,.2,3.2,.1,'#7a5232');box(0,1.6,-.8+d/2+.03,w,.16,.1,'#7a5232');
 box(0,0,-.8+d/2+.06,2.2,2.4,.1,'#6b4228');box(0,1.2,-.8+d/2+.12,2.2,.12,.06,'#3a2a1c');
 thickRoof(0,3.2,-.8,w,d,2.2,'#7a5f8a','#a8703f',.35,.28);
 for(let k=0;k<3+L;k++)crate(-3.4+(k%5)*.75,(k>4?.6:0),3.4+(k%2)*.1,.6,k%2?'#c28a4d':'#d8a868');
 for(let k=0;k<Math.min(L,4);k++)sack(2.4+k*.65,0,3.6,'#e3cf9d');
 if(L>=4){barrel(4.6,0,1.8);barrel(4.6,0,2.6)}
}
function mTower(L){
 const h=6.5+L*.9;bbox(0,0,0,4.2,1.0,4.2,PAL.stoneD,.12);cyl(0,.9,0,1.8,h,PAL.stone,10);
 for(let i=0;i<10;i++){const a=i/10*Math.PI*2;box(Math.cos(a)*1.9,h+.9,Math.sin(a)*1.9,.55,.6,.55,PAL.stone2)}
 cyl(0,h+.9,0,2.05,.35,PAL.stone2,10);cone(0,h+1.3,0,2.15,2.8,L>=4?'#d9a32a':PAL.roofB,10);
 door(0,.9,1.75,.8,1.3);windowF(0,h*.6,1.82,'z+',.4,.7);windowF(1.82,h*.4,0,'x+',.4,.7);
}
function mWell(L){
 cyl(0,0,0,1.0,.9,PAL.stone,10,'#3c6f8f');cyl(0,.9,0,1.05,.15,PAL.stone2,10);for(const s of [-1,1])box(s*.85,.9,0,.16,1.6,.16,PAL.woodD);
 box(0,2.35,0,2.0,.12,.12,PAL.woodD);roof(0,2.4,0,2.3,1.5,.8,PAL.roofR);box(0,1.6,0,.3,.35,.3,'#8b5a33');flowers(0,0,1.55,1.4,.3);
}
function mCastle(L){
 const R=9.5,wallH=4.2+L*.25,tH=6.5+L*.5;
 bbox(0,0,0,23.4,.6,23.4,PAL.stoneD,.2);
 // muralhas
 for(const s of [-1,1]){bbox(0,.6,s*R,2*R,wallH,1.6,PAL.stone,.08);bbox(s*R,.6,0,1.6,wallH,2*R,PAL.stone,.08)}
 for(let i=-4;i<=4;i++){for(const s of [-1,1]){box(i*2.1,.6+wallH,s*R,.9,.75,1.7,PAL.stone2);box(s*R,.6+wallH,i*2.1,1.7,.75,.9,PAL.stone2)}}
 // torres de canto
 for(const a of [-1,1])for(const b of [-1,1]){cyl(a*R,.6,b*R,2.0,tH,PAL.stone,10);for(let i=0;i<8;i++){const q=i/8*Math.PI*2;box(a*R+Math.cos(q)*2.1,.6+tH,b*R+Math.sin(q)*2.1,.6,.6,.6,PAL.stone2)}
  cone(a*R,.6+tH+.3,b*R,2.4,3.4,L>=5?'#d9a32a':PAL.roofB,10);windowF(a*R+(a>0?0:0),.6+tH*.6,b*R+2.02,'z+',.35,.6)}
 // portão
 bbox(0,.6,R+.6,5.2,wallH+1.2,2.4,PAL.stone2,.1);box(0,.6,R+1.85,2.4,3.0,.2,'#3a2a1c');for(let i=0;i<4;i++)box(-.9+i*.6,.6,R+1.95,.1,3.0,.08,'#2a2a2e');
 for(const s of [-1,1]){cyl(s*2.6,.6,R+.6,1.1,wallH+2.4,PAL.stone,8);cone(s*2.6,.6+wallH+2.4,R+.6,1.4,2,PAL.roofR,8)}
 // torre de menagem
 const kH=7.5+L*1.1;bbox(0,.6,-1.2,8,kH,7,'#d9d3c4',.15);
 for(let i=-3;i<=3;i++){box(i*1.1,.6+kH,2.3,.7,.7,.7,PAL.stone2);box(i*1.1,.6+kH,-4.7,.7,.7,.7,PAL.stone2)}for(let i=-2;i<=2;i++){box(4,.6+kH,-1.2+i*1.1,.7,.7,.7,PAL.stone2);box(-4,.6+kH,-1.2+i*1.1,.7,.7,.7,PAL.stone2)}
 thickRoof(0,.6+kH+.7,-1.2,6.8,5.8,3.2,L>=5?'#d9a32a':PAL.roofR,'#d9d3c4',.3,.3);
 door(0,.6,2.32,1.6,2.4,'#7b4a2a');for(const s of [-1,1]){windowF(s*2.4,.6+kH*.55,2.32,'z+',.6,1.0);windowF(s*2.4,.6+kH*.25,2.32,'z+',.6,1.0)}
 // estandartes nas paredes da menagem
 for(const s of [-1,1]){box(s*1.3,.6+kH*.45,2.34,.9,2.2,.08,'#2f5fb8');pyramid(s*1.3,.6+kH*.45-.01,2.34,.9,.09,-.5,'#2f5fb8');box(s*1.3,.6+kH*.45+1.4,2.36,.4,.4,.06,'#ffd34d')}
 if(L>=2){cyl(3.4,.6+kH,-3.8,1.0,3.2,PAL.stone,8);cone(3.4,.6+kH+3.2,-3.8,1.3,2.2,PAL.roofB,8)}
 if(L>=3){bush(-6,.6,5,.9);bush(6,.6,5.2,.8);bush(-6,.6,-6,.8)}
 if(L>=4){bbox(-5.4,.6,-5.6,4,2.4,3.2,PAL.wall,.06);thickRoof(-5.4,3,-5.6,4,3.2,1.4,PAL.roofR,PAL.wall2,.25,.2)}
}
function mSite(S){// canteiro: terreno marcado e estacas
 const s=S/2-.4;for(const a of [-1,1])for(const b of [-1,1]){box(a*s,0,b*s,.22,1.0,.22,'#c08a55');box(a*s,.9,b*s,.3,.14,.3,'#ff8a3d')}
}
function mScaffold(S,h){const s=S/2-.1,post='#c9925a',plank='#a8743f';for(const a of [-1,0,1])for(const b of [-1,1]){box(a*s,0,b*s,.16,h,.16,post);box(b*s,0,a*s,.16,h,.16,post)}
 for(let y=1.4;y<h;y+=1.6){for(const b of [-1,1]){box(0,y,b*s,2*s,.12,.5,plank);box(b*s,y,0,.5,.12,2*s,plank)}}}
function mPlot(S,col){bbox(0,-.05,0,S-.2,.25,S-.2,col||'#89c464',.12,col||'#8fd16a')}

const TYPES={
 castle:{name:'Castelo',icon:'🏰',size:6,model:mCastle,max:5,time:5,plot:'#b8c08a'},
 house:{name:'Casa',icon:'🏠',size:2,model:mHouse,max:5,time:6,plot:'#8fcf68'},
 farm:{name:'Fazenda',icon:'🌾',size:4,model:mFarm,max:5,time:8,plot:'#b99a63'},
 lumber:{name:'Lenhador',icon:'🪓',size:3,model:mLumber,max:5,time:7,plot:'#86bd5e'},
 quarry:{name:'Pedreira',icon:'⛏️',size:3,model:mQuarry,max:5,time:10,plot:'#bdb59f'},
 mine:{name:'Mina de Ouro',icon:'💰',size:3,model:mMine,max:5,time:14,plot:'#a99d86'},
 market:{name:'Mercado',icon:'🏪',size:3,model:mMarket,max:5,time:14,plot:'#c9b78e'},
 tavern:{name:'Taverna',icon:'🍺',size:3,model:mTavern,max:5,time:16,plot:'#8fcf68'},
 warehouse:{name:'Armazém',icon:'📦',size:3,model:mWarehouse,max:5,time:10,plot:'#a9c27a'},
 tower:{name:'Torre',icon:'🗼',size:2,model:mTower,max:5,time:14,plot:'#a9b08e'},
 well:{name:'Poço',icon:'⛲',size:1,model:mWell,max:3,time:4,plot:'#8fcf68'},
};
const TILE=4;
const modelCache=new Map();
function getModel(type,level){const k=type+level;let m=modelCache.get(k);if(m)return m;const T=TYPES[type];G=new Geo();PART=0;seed=777;mPlot(T.size*TILE,T.plot);T.model(level);m=G;modelCache.set(k,m);G=new Geo();return m}
function makeGeo(fn){G=new Geo();PART=0;fn();const m=G;G=new Geo();return m}

/* ---------- Saída de malha: carimba modelos locais no mundo ---------- */
class Out{constructor(n=4096){this.p=new Float32Array(n*3);this.c=new Float32Array(n*3);this.n=new Float32Array(n*3);this.k=0;this.buf=null}
 reset(){this.k=0}
 grow(add){const need=(this.k+add)*3;if(need<=this.p.length)return;let L=this.p.length;while(L<need)L*=2;for(const f of ['p','c','n']){const a=new Float32Array(L);a.set(this[f]);this[f]=a}}
 // m: Geo; rot: ângulo (rad) em torno de Y; sx/sy/sz: escala; tint: multiplicador de cor
 stamp(m,x,y,z,rot=0,sx=1,sy=1,sz=1,tint=1){const N=m.count;this.grow(N);const c=Math.cos(rot),s=Math.sin(rot),P=m.p,Cc=m.c,Nn=m.n;let o=this.k*3;
  for(let i=0;i<N*3;i+=3,o+=3){const lx=P[i]*sx,ly=P[i+1]*sy,lz=P[i+2]*sz;this.p[o]=x+lx*c+lz*s;this.p[o+1]=y+ly;this.p[o+2]=z-lx*s+lz*c;
   this.c[o]=Cc[i]*tint;this.c[o+1]=Cc[i+1]*tint;this.c[o+2]=Cc[i+2]*tint;
   let nx=Nn[i]/sx,ny=Nn[i+1]/sy,nz=Nn[i+2]/sz;const l=Math.hypot(nx,ny,nz)||1;nx/=l;ny/=l;nz/=l;this.n[o]=nx*c+nz*s;this.n[o+1]=ny;this.n[o+2]=-nx*s+nz*c}
  this.k+=N}
 upload(){if(!this.buf)this.buf={p:gl.createBuffer(),c:gl.createBuffer(),n:gl.createBuffer()};const B=this.buf;
  for(const [b,a] of [[B.p,this.p],[B.c,this.c],[B.n,this.n]]){gl.bindBuffer(gl.ARRAY_BUFFER,b);gl.bufferData(gl.ARRAY_BUFFER,a.subarray(0,this.k*3),gl.DYNAMIC_DRAW)}this.count=this.k}}

/* ---------- Árvores (instanciadas) ---------- */
let treeDec=null,treeCon=null;
function geoToMesh(m){const r={p:gl.createBuffer(),c:gl.createBuffer(),n:gl.createBuffer(),count:m.count};for(let [buf,arr] of [[r.p,m.p],[r.c,m.c],[r.n,m.n]]){gl.bindBuffer(gl.ARRAY_BUFFER,buf);gl.bufferData(gl.ARRAY_BUFFER,new Float32Array(arr),gl.STATIC_DRAW)}return r}
function buildTreeModels(){
 treeDec=geoToMesh(makeGeo(()=>{box(0,-.3,0,.42,3.3,.42,'#7a5a3a');ball(0,4.0,0,2.05,'#4f9a42',.82,3,6);ball(.9,3.3,.4,1.25,'#5aa548',.85,3,6);ball(-.7,3.6,-.5,1.1,'#438a3a',.85,3,6)}));
 treeCon=geoToMesh(makeGeo(()=>{box(0,-.3,0,.36,2.9,.36,'#6f5236');for(let j=0;j<3;j++)cone(0,(1.3+j*1.15),0,(1.95-j*.42),(3.2-j*.3),mixC(hex('#2f6b40'),hex('#64a05a'),j*.15).map(q=>q*(.85+j*.1)),7)}))}

/* ---------- Aldeão articulado ----------
   aPart = peça + 10*acessório. Peças: 0 corpo, 1/2 pernas, 3/4 braços.
   Acessórios: 1 machado, 2 picareta, 3 enxada, 4 martelo, 5 fardo, 6 chapéu de palha.
   Cor com r=-1 → roupa da instância (g = sombra); r=-2 → cabelo. */
function villagerGeo(){G=new Geo();
 const SKIN='#f2c29b',PANTS='#5a4636',SHOE='#3b2a20',SH=g=>[-1,g,0],HAIR=g=>[-2,g,0];
 PART=1;box(-.14,0,0,.24,.62,.26,PANTS);box(-.14,0,.05,.26,.14,.36,SHOE);
 PART=2;box(.14,0,0,.24,.62,.26,PANTS);box(.14,0,.05,.26,.14,.36,SHOE);
 PART=0;bbox(0,.56,0,.66,.66,.42,SH(1),.08);box(0,.62,0,.68,.12,.44,'#6b4a2e');box(0,.66,.225,.14,.1,.02,'#e2b64b');
 bbox(0,1.18,0,.24,.1,.24,SKIN,.03);
 ball(0,1.56,0,.36,SKIN,1,4,8);ball(0,1.66,-.03,.38,HAIR(1),.72,3,8,false);box(0,1.4,-.2,.5,.3,.2,HAIR(.9));
 box(-.12,1.56,.33,.07,.1,.04,'#2a1d17');box(.12,1.56,.33,.07,.1,.04,'#2a1d17');box(0,1.46,.35,.06,.06,.04,'#e3a07f');
 box(-.2,1.45,.31,.08,.05,.02,'#f29a9a');box(.2,1.45,.31,.08,.05,.02,'#f29a9a');
 PART=3;box(-.42,.7,0,.17,.5,.2,SH(.92));box(-.42,.6,0,.16,.14,.16,SKIN);
 PART=4;box(.42,.7,0,.17,.5,.2,SH(.92));box(.42,.6,0,.16,.14,.16,SKIN);
 // ferramentas na mão direita (cabo para a frente)
 PART=14;box(.42,.6,.35,.07,.07,.75,'#7a5232');box(.42,.62,.7,.07,.32,.2,'#c9ccd1');
 PART=24;box(.42,.6,.35,.07,.07,.75,'#7a5232');box(.42,.62,.72,.06,.08,.55,'#9aa0a8');box(.42,.62,.72,.5,.08,.08,'#9aa0a8');
 PART=34;box(.42,.6,.4,.06,.06,.95,'#9b6b3f');box(.42,.5,.86,.3,.18,.05,'#9aa0a8');
 PART=44;box(.42,.6,.3,.07,.07,.55,'#7a5232');box(.42,.6,.6,.18,.18,.28,'#6c7078');
 // fardo carregado (cor definida no shader)
 PART=50;bbox(0,.95,.42,.62,.42,.42,'#ffffff',.08);
 // chapéu de palha
 PART=60;cyl(0,1.86,0,.62,.06,'#e8cf7a',10);cone(0,1.9,0,.36,.32,'#e2c464',10);
 const m=G;G=new Geo();return m}
